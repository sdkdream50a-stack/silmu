# frozen_string_literal: true

require "test_helper"

# P1.5 §44 — 변경 감지의 positive / negative / unchanged control.
#
# ⚠️ "변경 0건" 주장에는 **changed control 이 먼저 성공했다는 기록**이 있어야 한다.
#    검출기가 변화를 못 보는 것과 변화가 없는 것은 다르다.
class Authority::ChangeDetectionTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  setup { @document = create_document }

  # ── ① CHANGED POSITIVE CONTROL (먼저 성공해야 한다) ──
  test "POSITIVE — 내용이 바뀌면 변경 이벤트가 정확히 1건 생긴다" do
    detector_with(build_success_result).check(@document)  # 기준선
    assert_equal 1, @document.authority_versions.count

    changed = build_success_result(revision_number: "99999", effective_on: "20261101")
    assert_difference -> { AuthorityChangeEvent.count }, 1 do
      out = detector_with(changed).check(@document.reload)
      assert out.changed?, "변경을 감지하지 못했다"
    end
    assert_equal 2, @document.reload.authority_versions.count
  end

  # ── ② UNCHANGED CONTROL (①이 성공한 뒤에만 의미가 있다) ──
  test "UNCHANGED — 동일 snapshot 이면 새 버전도 이벤트도 만들지 않는다" do
    result = build_success_result
    detector_with(result).check(@document)
    baseline_versions = @document.reload.authority_versions.count
    baseline_events = AuthorityChangeEvent.count

    3.times { detector_with(result).check(@document.reload) }

    assert_equal baseline_versions, @document.reload.authority_versions.count,
                 "동일 내용인데 버전이 늘었다"
    assert_equal baseline_events, AuthorityChangeEvent.count,
                 "동일 내용인데 변경 이벤트가 생겼다"
  end

  test "NEGATIVE — fetch 실패는 '법령 삭제'가 아니라 실패로 기록된다" do
    failing = Authority::FetchResult.failure("SOURCE_UNAVAILABLE", "connection reset")
    out = detector_with(failing).check(@document)

    assert out.failed?
    assert_equal 0, @document.reload.authority_versions.count, "실패했는데 버전이 생성됐다"
    assert_equal 0, AuthorityChangeEvent.count
    source = @document.authority_source.reload
    assert_equal "SOURCE_UNAVAILABLE", source.last_failure_kind
    assert_equal 1, source.failure_count
    assert_equal "ACTIVE", @document.reload.status, "출처 장애로 문서가 폐지 처리되면 안 된다"
  end

  test "NEGATIVE — 파싱 실패와 네트워크 실패를 구분한다" do
    out = detector_with(Authority::FetchResult.failure("PARSE_FAILED", "검색 결과 없음")).check(@document)
    assert out.failed?
    assert_equal "PARSE_FAILED", @document.authority_source.reload.last_failure_kind
  end

  test "최초 수집은 NEW_DOCUMENT — 개정이 아니라 기준선이다" do
    out = detector_with(build_success_result).check(@document)
    assert out.changed?
    event = out.change_event
    assert_equal "NEW_DOCUMENT", event.change_type
    assert event.baseline?, "최초 수집이 개정으로 분류됐다"
    assert_nil event.old_version_id
  end

  test "시행일 변경은 별도 change_type 을 갖는다" do
    detector_with(build_success_result).check(@document)
    out = detector_with(build_success_result(effective_on: "20261201")).check(@document.reload)
    assert_equal "EFFECTIVE_DATE_CHANGED", out.change_event.change_type
    assert_equal Date.new(2026, 12, 1), out.version.effective_at
  end

  test "정규화 — 공백·줄바꿈 차이는 개정으로 오인되지 않는다" do
    base = build_success_result
    detector_with(base).check(@document)

    noisy = Authority::FetchResult.success(
      raw_content: base.raw_content.gsub("\n", "\r\n").gsub(": ", ":  ") + "   \n\n\n",
      format: :text, metadata: AuthorityTestHelper::REAL_METADATA, source_url: base.source_url
    )
    assert_no_difference -> { AuthorityChangeEvent.count } do
      assert detector_with(noisy).check(@document.reload).unchanged?
    end
  end

  test "정규화가 의미를 바꾸지 않는다 — 조문 번호·금액은 보존된다" do
    src = "제25조 (수의계약)  추정가격 2,000만원  이하\r\n\r\n\r\n다만 제30조 제1항은 제외한다"
    out = Authority::Normalizer.normalize(src)
    %w[제25조 2,000만원 제30조 제1항].each { |token| assert_includes out, token }
  end
end
