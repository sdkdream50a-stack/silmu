# frozen_string_literal: true

require "test_helper"

# P1.5 §9 — "개정되었는가"와 "지금 시행 중인가"는 다른 질문이다.
class AuthorityEffectiveDateTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  setup { @document = create_document }

  test "미래 시행 버전은 아직 현행이 아니다" do
    detector_with(build_success_result(effective_on: (Date.current + 30).strftime("%Y%m%d"))).check(@document)
    v = @document.reload.authority_versions.last

    assert v.future_effective?
    refute v.in_effect?, "시행 전인데 현행으로 판정됐다"
    assert_includes v.effective_label, "시행 예정"
  end

  test "과거 시행 버전은 현행이다" do
    detector_with(build_success_result(effective_on: (Date.current - 30).strftime("%Y%m%d"))).check(@document)
    v = @document.reload.authority_versions.last
    assert v.in_effect?
    refute v.future_effective?
  end

  test "시행일 미상이면 현행으로 단정하지 않는다" do
    detector_with(build_success_result(effective_on: nil)).check(@document)
    v = @document.reload.authority_versions.last
    assert_nil v.effective_at
    refute v.in_effect?, "시행일을 모르는데 현행으로 판정됐다"
    assert_equal "시행일 미상", v.effective_label
  end

  test "문서는 '오늘 기준 시행 중인 버전'을 고를 수 있다" do
    detector_with(build_success_result(effective_on: (Date.current - 60).strftime("%Y%m%d"))).check(@document)
    detector_with(build_success_result(revision_number: "99999",
                                       effective_on: (Date.current + 60).strftime("%Y%m%d"))).check(@document.reload)

    doc = @document.reload
    assert_equal 2, doc.authority_versions.count
    assert_equal "36338", doc.effective_version.revision_number, "미래 시행 버전을 현행으로 골랐다"
    assert doc.pending_change?, "시행 예정 버전을 감지하지 못했다"
    assert_equal 1, doc.pending_versions.count
  end

  test "변경 이벤트는 이미 시행됐는지 구분한다" do
    detector_with(build_success_result).check(@document)
    out = detector_with(build_success_result(effective_on: (Date.current + 10).strftime("%Y%m%d"),
                                             revision_number: "99999")).check(@document.reload)
    refute out.change_event.already_in_effect?, "시행 전 개정이 이미 시행으로 판정됐다"
  end

  test "잘못된 날짜 형식은 nil 로 처리하고 예외를 던지지 않는다" do
    detector_with(build_success_result(effective_on: "not-a-date")).check(@document)
    assert_nil @document.reload.authority_versions.last.effective_at
  end
end
