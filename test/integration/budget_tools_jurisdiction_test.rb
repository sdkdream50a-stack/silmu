# frozen_string_literal: true

require "test_helper"

# P3 (2026-09-20) — 예산 도구 6종의 «적용 범위» 고지.
#
# `tools_helper` 의 `domain: "예산"` 은 6개인데 jurisdiction 이 붙은 것은 3개뿐이었다.
# 표시가 없다는 것은 «중립» 이 아니라 «지자체 기준을 학교 사용자에게 무표시로 준다» 는 뜻이다.
#
# 그중 하나는 무표시가 아니라 **거짓**이었다 — 예비비 한도 계산기의 1% 는
# 「지방재정법」 제43조제1항이고 그 주어는 **지방자치단체**다. 같은 항의 「교육비특별회계」는
# 시·도교육청 회계이지 학교회계가 아니다. 학교회계 예비비는 「초·중등교육법」 제30조의2제4항이
# 비율 없이 «적절한 금액을 계상할 수 있다» 로 정하고, 17개 시·도 교육규칙에도 비율 규정이 없다.
class BudgetToolsJurisdictionTest < ActionDispatch::IntegrationTest
  BUDGET_TOOLS = {
    "budget-estimator"           => "/tools/budget-estimator",
    "budget-execution-rate"      => "/tools/budget-execution-rate",
    "contingency-fund"           => "/tools/contingency-fund",
    "budget-category-finder"     => "/tools/budget-category-finder",
    "subsidy-settlement-checker" => "/tools/subsidy-settlement-checker",
    "budget-transfer-checker"    => "/tools/budget-transfer-checker"
  }.freeze

  test "레지스트리의 예산 도구는 정확히 이 6개다" do  # 목록이 늘면 이 검사가 먼저 깨져야 한다
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    paths = controller.view_context.tools_registry
                      .select { |t| t[:domain] == "예산" }.map { |t| t[:path] }
    assert_equal BUDGET_TOOLS.values.sort, paths.sort,
                 "예산 도구 목록이 바뀌었다 — 관할 판정을 다시 해야 한다"
  end

  test "예산 도구 6종 전부에 적용 범위가 등록돼 있다" do
    BUDGET_TOOLS.each_key do |key|
      j = ToolTrust.for(key).jurisdiction
      assert j.present?, "#{key} 에 jurisdiction 이 없다 — 지자체 기준이 무표시로 나간다"
      assert j.applies_to.present?, "#{key} 의 적용대상이 비었다"
      assert j.agency.present?, "#{key} 의 적용기관이 비었다"
      assert j.school_note?, "#{key} 에 학교 사용자 안내가 없다"
    end
  end

  test "적용 범위 블록이 각 도구 화면에 실제로 렌더된다" do
    BUDGET_TOOLS.each do |key, path|
      get path
      assert_response :success, "#{path} 가 열리지 않는다"
      assert_includes response.body, "적용 범위", "#{key} 화면에 적용 범위 블록이 없다"
      assert_includes response.body, ToolTrust.for(key).jurisdiction.school_differs,
                      "#{key} 화면에 학교 안내가 렌더되지 않았다"
    end
  end

  test "등록하지 않은 도구에는 적용 범위를 붙이지 않는다" do  # 음성 대조 — 전부 칠하면 구분이 사라진다
    assert_nil ToolTrust.for("pension-calculator").jurisdiction
    get "/tools/pension-calculator"
    assert_response :success
    assert_not_includes response.body, "적용 범위", "미등록 도구에도 적용 범위 블록이 떴다"
  end

  # ── 예비비 — 이번 P3 의 핵심 수리 ───────────────────────────────────────
  test "예비비 1% 한도가 학교회계에 적용되지 않는다고 화면에 적는다" do
    get "/tools/contingency-fund"
    body = response.body
    assert_includes body, "학교회계 예비비에는 이 1% 한도가 적용되지 않습니다"
    assert_includes body, "교육비특별회계"
    assert_includes body, "초·중등교육법", "학교회계 예비비의 근거 조문이 없다"
  end

  test "예비비 화면에서 학교 사용자를 학교회계 면으로 보낸다" do
    get "/tools/contingency-fund"
    assert_includes response.body, "/school-office/calendar"
  end

  test "지방재정법 1% 설명 자체는 그대로다" do  # 지자체 사용자 비회귀 — 고지를 붙였지 기능을 바꾸지 않았다
    get "/tools/contingency-fund"
    body = response.body
    assert_includes body, "지방재정법 제43조"
    assert_includes body, "1% 이내"
    assert_includes body, "법정 한도(상한 1%)"
  end

  test "학교회계 예비비에 우리가 임의의 비율을 만들어 붙이지 않았다" do
    # ⚠️ 「%가 안 나온다」로 재면 «1% 가 적용되지 않는다» 는 정정 문장까지 결함으로 잡는다.
    #    그래서 **문장 단위**로 본다 — 학교회계를 주어로 비율을 «부여하는» 문장이 있는가.
    detect = lambda do |text|
      text.split(/[.。]\s*/).select do |sentence|
        sentence.include?("학교회계") &&
          sentence.match?(/\d+(\.\d+)?\s*%|퍼센트|100분의/) &&
          !sentence.match?(/적용되지 않|없습니다|없고/)
      end
    end

    school_text = ToolTrust.for("contingency-fund").jurisdiction.school_differs
    assert_empty detect.call(school_text), "학교회계에 없는 비율 한도를 만들어 적었다"
    assert_includes school_text, "비율 상한이 없"

    # 양성 대조 — 같은 검사식이 날조된 문장은 잡아야 한다(안 잡으면 위 검사는 항진식이다).
    planted = "학교회계 예비비는 예산 총액의 2% 이내로 계상하여야 합니다."
    assert_not_empty detect.call(planted), "날조된 비율 문장을 검사식이 통과시킨다"
  end

  test "기존 3종의 학교 안내가 그대로다" do  # P0 비회귀
    assert_includes ToolTrust.for("budget-category-finder").jurisdiction.school_differs,
                    "학교회계 과목이 아닙니다"
    assert_includes ToolTrust.for("budget-execution-rate").jurisdiction.school_differs,
                    "3월이어야 경과 월 수가 맞습니다"
    assert_includes ToolTrust.for("budget-transfer-checker").jurisdiction.school_differs,
                    "의회 심의"
  end
end
