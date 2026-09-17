require "test_helper"

# 계약 화면 소형 사실 회귀 (2026-09-17 전수감사 G-11·G-14).
class ContractSmallFactsTest < ActionDispatch::IntegrationTest
  test "legality checklist asks for 2+ quotes above 20M won, not below" do
    get "/tools/contract-legality-check"
    assert_response :success
    assert_includes response.body, "추정가격 2,000만원 초과 수의계약 시"
    assert_not_includes response.body, "2인 이상 견적 징구 (2,000만원 이하 수의계약 시)"
  end

  test "period-extension flowchart uses the construction delay rate 0.5/1000" do
    html = ApplicationController.render(partial: "topics/flowcharts/contract_period_extension")
    assert_includes html, "0.5/1,000"
    assert_not_includes html, "× 1/1,000"
  end
end
