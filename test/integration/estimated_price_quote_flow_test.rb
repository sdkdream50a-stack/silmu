require "test_helper"

# 2026-11-25 추정가격 계산기 — 파일 업로드 없음 · 견적서 금액 옮겨 적기 · 결재용 산출 근거.
class EstimatedPriceQuoteFlowTest < ActionDispatch::IntegrationTest
  test "공급가액 100만·부가세 10만·합계 110만 견적이면 추정가격은 100만원이다" do
    post "/estimated-prices/calculate",
         params: { contract_type: "goods", unit_price: "1000000", quantity: "1", delivery_fee: "0", install_fee: "0" },
         as: :json
    assert_response :success
    r = response.parsed_body["result"]
    assert_equal 1_000_000, r["base_amount"]
    assert_equal 1_100_000, r["estimated_price"]
  end

  test "화면에 업로드 영역이 없고 옮겨 적기 입력과 산출 근거가 있다" do
    get "/tools/estimated-price"
    assert_response :success
    body = response.body
    assert_no_match "quote-documents/extract", body
    assert_no_match(/quMapFields_ep/, body)
    assert_includes body, "파일은 올리지 않습니다"
    %w[ep-q-supply ep-q-vat ep-q-total ep-copy-btn].each { |id| assert_includes body, %(id="#{id}"), id }
    assert_includes body, "산출 근거 (결재 첨부용)"
    assert_includes body, 'inputmode="numeric"'
  end

  test "참고 지표는 기준월을 밝히고 매월 갱신을 주장하지 않는다" do
    get "/tools/estimated-price"
    body = response.body
    assert_includes body, "#{MonthlyIndicatorService::REFERENCE_MONTH} 기준"
    assert_includes body, "자동으로 갱신되지 않습니다"
    assert_no_match(/매월 업데이트|이달의/, body)
  end

  test "없는 기능(복수 견적 비교표·엑셀 다운로드)을 내세우지 않는다" do
    get "/tools/estimated-price"
    assert_no_match(/복수 견적서 비교표 자동 생성|엑셀\/PDF 다운로드/, response.body)
  end
end
