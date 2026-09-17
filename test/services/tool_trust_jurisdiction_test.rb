# frozen_string_literal: true

require "test_helper"

# P0-2 (LECTURE_READINESS_AUDIT R1) — 적용기관 고지 등록부.
#
# 이 테스트가 막는 것: 학교 사용자가 지방자치단체 기준 예산 도구를 학교회계 기준으로 오해하는 것.
# 수리 전 코드에서는 Info 에 jurisdiction 이 없어 NoMethodError 로 실패한다(양성 대조 = 실패 확인 완료).
class ToolTrustJurisdictionTest < ActiveSupport::TestCase
  # 학교 문맥에서 지자체 기준으로 오해될 수 있는 도구 — 전부 고지가 있어야 한다.
  LOCAL_GOV_BUDGET_TOOLS = %w[
    budget-category-finder
    budget-execution-rate
    budget-transfer-checker
  ].freeze

  setup { ToolTrust.reset! }
  teardown { ToolTrust.reset! }

  test "지자체 기준 예산 도구 3종에 적용기관 고지가 등록돼 있다" do
    LOCAL_GOV_BUDGET_TOOLS.each do |key|
      j = ToolTrust.for(key).jurisdiction
      assert_not_nil j, "#{key}: jurisdiction 미등록 — 학교 사용자에게 기준이 안 보인다"
    end
  end

  test "고지 4필드(적용대상·적용기관·근거지침·기준연도)가 전부 채워져 있다" do
    LOCAL_GOV_BUDGET_TOOLS.each do |key|
      j = ToolTrust.for(key).jurisdiction
      assert j.applies_to.present?,     "#{key}: 적용대상 없음"
      assert j.agency.present?,         "#{key}: 적용기관 없음"
      assert j.guideline.present?,      "#{key}: 근거 지침 없음"
      assert j.standard_year.present?,  "#{key}: 기준연도 필드 자체가 없음 (모르면 UNVERIFIED 로 둔다)"
    end
  end

  test "적용기관에 지방자치단체가 명시돼 있다" do
    LOCAL_GOV_BUDGET_TOOLS.each do |key|
      assert_match(/지방자치단체/, ToolTrust.for(key).jurisdiction.agency,
                   "#{key}: 적용기관이 지방자치단체라고 말하지 않는다")
    end
  end

  test "학교회계가 다르다는 고지와 학교 경로가 함께 있다" do
    LOCAL_GOV_BUDGET_TOOLS.each do |key|
      j = ToolTrust.for(key).jurisdiction
      assert j.school_note?,                      "#{key}: 학교회계 차이 고지 없음"
      assert_match(/학교/, j.school_differs,      "#{key}: 고지 문구에 학교 언급 없음")
      assert j.school_path.present?,              "#{key}: 학교 경로 없음 — 경고만 하고 대안을 안 준다"
      assert j.school_path.start_with?("/"),      "#{key}: 학교 경로가 상대경로가 아니다"
    end
  end

  # 음성 대조 — 등록하지 않은 도구에는 고지를 만들어내지 않는다.
  test "등록되지 않은 도구는 jurisdiction 이 nil 이다" do
    assert_nil ToolTrust.for("contract-method").jurisdiction,
               "등록 안 한 도구에 고지가 생겼다 — 없는 기준을 만들고 있다"
    assert_nil ToolTrust.for("존재하지-않는-도구").jurisdiction
  end

  # 기준연도는 모르면 «검증됨» 이라고 말하지 않는다.
  test "UNVERIFIED 기준연도는 검증된 것으로 취급되지 않는다" do
    LOCAL_GOV_BUDGET_TOOLS.each do |key|
      j = ToolTrust.for(key).jurisdiction
      next if j.standard_year.to_s != "UNVERIFIED"

      assert_not j.standard_year_verified?,
                 "#{key}: UNVERIFIED 인데 검증된 기준연도로 표시된다"
    end
  end

  test "검증된 기준연도는 검증된 것으로 취급된다" do
    j = ToolTrust::Jurisdiction.new(standard_year: "2026")
    assert j.standard_year_verified?
  end
end
