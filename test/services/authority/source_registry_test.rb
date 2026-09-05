# frozen_string_literal: true

require "test_helper"

# P1.5 §16·§23·§24·§25 — Source Registry · 주기 · 실패 처리
class Authority::SourceRegistryTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  test "주기는 소스마다 다르게 설정된다 (§23)" do
    daily = create_source(check_interval_hours: 24)
    weekly = create_source(check_interval_hours: 168)

    daily.update_columns(last_checked_at: 25.hours.ago)
    weekly.update_columns(last_checked_at: 25.hours.ago)

    assert daily.due?, "일간 소스가 25시간 후에도 due 가 아니다"
    refute weekly.due?, "주간 소스가 25시간 만에 due 가 됐다"
  end

  test "한 번도 검사하지 않은 소스는 즉시 due" do
    assert create_source(last_checked_at: nil).due?
  end

  test "비활성 소스는 due 가 되지 않는다" do
    refute create_source(enabled: false, last_checked_at: nil).due?
  end

  test "Tier 4 는 현행성 판정 근거로 쓸 수 없다 (§7)" do
    (1..3).each { |t| assert create_source(authority_tier: t).usable_for_currency_judgement? }
    refute create_source(authority_tier: 4).usable_for_currency_judgement?,
           "커뮤니티 자료가 현행성 근거로 허용됐다"
  end

  test "실패 종류를 구분해 기록한다 (§24)" do
    s = create_source
    s.record_failure!("SOURCE_UNAVAILABLE", "timeout")
    assert_equal 1, s.failure_count
    assert_equal "SOURCE_UNAVAILABLE", s.last_failure_kind

    s.record_failure!("PARSE_FAILED", "구조 변경")
    assert_equal 2, s.failure_count
    assert_equal "PARSE_FAILED", s.last_failure_kind
  end

  test "성공하면 실패 카운터가 초기화된다 (§25)" do
    s = create_source
    3.times { s.record_failure!("FETCH_FAILED", "err") }
    assert_equal 3, s.failure_count
    s.record_success!
    assert_equal 0, s.failure_count
    assert_nil s.last_failure_kind
  end

  test "알 수 없는 실패 종류는 거부한다" do
    assert_raises(ArgumentError) { Authority::FetchResult.failure("WHATEVER", "x") }
  end

  test "연속 실패가 상한을 넘으면 잡이 그 소스를 건너뛴다 (무한 retry 금지)" do
    source = create_source
    doc = create_document(source: source)
    source.update_columns(failure_count: AuthorityFreshnessCheckJob::MAX_CONSECUTIVE_FAILURES)

    report = AuthorityFreshnessCheckJob.new.perform(document_ids: [ doc.id ])
    assert_equal 1, report[:skipped_failing]
    assert_equal 0, report[:checked]
  end

  test "잡은 실행당 문서 수가 제한된다 (bounded)" do
    source = create_source
    3.times { create_document(source: source) }
    report = AuthorityFreshnessCheckJob.new.perform(limit: 2)
    assert_operator report[:checked], :<=, 2
  end

  test "지원하지 않는 fetch 전략은 조용히 성공하지 않는다" do
    source = create_source(fetch_strategy: "manual")
    doc = create_document(source: source)
    out = Authority::ChangeDetector.new.check(doc)
    assert out.failed?
    assert_equal "PARSE_FAILED", source.reload.last_failure_kind
  end
end
