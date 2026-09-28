require "test_helper"

# 2026-09-12 도구 사용 계측(tool_start/tool_complete) 회귀.
# 계측 스니펫은 /tools 에서만 나가야 한다 — 다른 페이지에 새면 tool_id 가 오염된다.
#
# 2026-09-28 감사(10_ANALYTICS_COVERAGE.md) — 렌더 조건이 params[:controller] ∈
# {tools, contract_methods} 뿐이라 다른 컨트롤러 이름을 쓰는 17개 /tools/* 도구가
# «0 이용자»와 «미계측»을 구분할 수 없는 상태였다. 아래는 그 17개 전부에 대한 양성
# 회귀 + 기존 20개(대표 1건)가 안 깨졌는지의 음성 대조다.
class ToolAnalyticsTest < ActionDispatch::IntegrationTest
  test "tool pages carry the tool analytics snippet" do
    host! "silmu.kr"

    get "/tools/budget-execution-rate"

    assert_response :success
    assert_includes response.body, '"tool_start"'
    assert_includes response.body, '"tool_complete"'
  end

  # 음성 대조 — 위 양성이 통과할 때만 의미가 있다.
  test "non-tool pages do not carry it" do
    host! "silmu.kr"

    get "/guides/#{guides(:one).slug}"

    assert_response :success
    refute_includes response.body, '"tool_complete"'
  end

  # tool_complete 는 #result-area 관례에 의존한다. 그 관례가 사라지면
  # 이벤트가 조용히 0 이 되므로 앵커를 고정한다(실측: 21개 중 5개만 이 관례를 쓴다).
  test "result-area anchor still exists on an instrumented tool" do
    host! "silmu.kr"

    get "/tools/budget-execution-rate"

    assert_includes response.body, 'id="result-area"',
                    "#result-area 가 사라졌다 — tool_complete 가 영원히 0 이 된다"
  end

  # 이전에 컨트롤러 이름이 달라 계측이 빠져 있던 17개 — 이제 전부 스니펫을 받는다.
  PREVIOUSLY_UNCOVERED_TOOL_PATHS = %w[
    /tools/contract-documents
    /tools/cost-estimate
    /tools/design-change
    /tools/progress-inspection
    /tools/cost-calculation
    /tools/quote-auto
    /tools/quote-review
    /tools/project-plan
    /tools/official-document
    /tools/contract-reason
    /tools/estimated-price
    /tools/legal-period
    /tools/contract-guarantee
    /tools/qualification-evaluation
    /tools/insurance-calculator
    /tools/budget-estimator
    /tools/pdf
  ].freeze

  PREVIOUSLY_UNCOVERED_TOOL_PATHS.each do |tool_path|
    test "previously-uncovered tool #{tool_path} now carries the tool analytics snippet" do
      host! "silmu.kr"

      get tool_path

      assert_response :success
      assert_includes response.body, '"tool_start"',
                      "#{tool_path} 가 계측 파셜을 받지 못했다"
      assert_includes response.body, '"tool_complete"',
                      "#{tool_path} 가 계측 파셜을 받지 못했다"
    end
  end

  # /tools/contract-method 는 P1-2 에서 이미 고쳤다 — 회귀만 지킨다.
  test "contract-method (already-fixed controller) still carries the snippet" do
    host! "silmu.kr"

    get "/tools/contract-method"

    assert_response :success
    assert_includes response.body, '"tool_start"'
  end

  # 음성 대조 — 렌더 조건을 옛 화이트리스트({tools, contract_methods})로 되돌리면
  # 이 테스트들은 반드시 실패해야 한다(그렇지 않으면 위 양성이 우연히 통과한 것이다).
  test "negative control: the old controller-only condition would have missed these paths" do
    old_whitelist = %w[tools contract_methods]
    new_controllers_for_previously_uncovered = %w[
      contract_documents cost_estimates design_changes progress_inspections
      cost_calculations quote_documents quote_reviews project_plans
      official_documents contract_reasons estimated_prices legal_periods
      contract_guarantees qualification_evaluations insurance_calculators
      estimations pdf_tools
    ]

    new_controllers_for_previously_uncovered.each do |controller_name|
      refute_includes old_whitelist, controller_name,
                      "#{controller_name} 이 옛 화이트리스트에 이미 있었다면 이번 변경은 무의미하다"
    end
  end
end
