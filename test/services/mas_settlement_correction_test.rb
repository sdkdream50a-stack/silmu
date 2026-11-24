require "test_helper"

MAS_SETTLEMENT_CORRECTION_LIBRARY_ONLY = true unless defined?(MAS_SETTLEMENT_CORRECTION_LIBRARY_ONLY)
load Rails.root.join("db/content_migrations/20261124090000_mas_settlement_official_corrections.rb").to_s

# 2026-11-24 MAS 2단계경쟁·결산 법령 정정 — 정정본 내용과 안전장치 회귀 테스트
class MasSettlementCorrectionTest < ActiveSupport::TestCase
  M = MasSettlementCorrection20261124

  def text_of(dir)
    M.values(dir).values.map { |v| v.is_a?(String) ? v : JSON.generate(v) }.join("\n")
  end

  test "MAS 정정본에 옛 오류 기준이 없고 현행 기준이 있다" do
    text = text_of("mas-contract")
    refute_match(/2천만원\s*초과/, text)
    refute_match(/3개\s*업체/, text)
    assert_includes text, "1회 납품요구"
    assert_includes text, "5인 이상"
    assert_includes text, "2027.1.1."
    assert_includes text, "최고 점수"
  end

  test "결산 정정본·감사사례에 8월 31일 기한이 없고 5월 31일 제출·다음 해 승인이 있다" do
    %w[budget-settlement audit-settlement-report-delayed].each do |dir|
      text = text_of(dir)
      refute_match(/8월\s*31일(?!인가요)/, text, dir) # "8월 31일인가요? 아닙니다" 반박 문항만 허용
      refute_match(/2월\s*10일\s*출납\s*폐쇄/, text, dir)
      assert_includes text, "5월 31일", dir
    end
    text = text_of("budget-settlement")
    assert_includes text, "다음 해"
    assert_includes text, "학교운영위원회"
    assert_includes text, "교육부장관"
  end

  test "데이터 파일과 가드 필드가 일치한다" do
    M::GUARDS.each { |slug, g| assert_equal g.keys.sort, M.values(slug).keys.sort, slug }
    M::AUDIT_GUARDS.each { |slug, g| assert_equal g.keys.sort, M.values("audit-#{slug}").keys.sort, slug }
  end

  test "운영값이 가드와 다르면 아무것도 쓰지 않고 실패한다" do
    setup_records { |_field, _new| "다른 사람이 고친 값" }
    before = Topic.find_by!(slug: "mas-contract").summary

    error = assert_raises(RuntimeError) { M.run!(dry_run: false) }
    assert_match "아무것도 쓰지 않음", error.message
    assert_equal before, Topic.find_by!(slug: "mas-contract").summary
  end

  test "이미 정정본이면 변경 없이 통과한다(멱등)" do
    setup_records { |_field, new_value| new_value }
    plans = M.run!(dry_run: false)
    assert plans.all? { |p| p[:changes].empty? }
  end

  private

  def setup_records
    M::GUARDS.each_key do |slug|
      topic = Topic.find_or_initialize_by(slug: slug)
      topic.name ||= slug
      M.values(slug).each { |field, v| topic[field] = yield(field, v) }
      topic.save!(validate: false)
    end
    M::AUDIT_GUARDS.each_key do |slug|
      audit = AuditCase.find_or_initialize_by(slug: slug)
      audit.title ||= slug
      M.values("audit-#{slug}").each { |field, v| audit[field] = yield(field, v) }
      audit.save!(validate: false)
    end
  end
end
