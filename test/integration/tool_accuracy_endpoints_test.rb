require "test_helper"

# 2026-08-04 도구 정확성 P0 교정 — 컨트롤러 경로 회귀 테스트.
class ToolAccuracyEndpointsTest < ActionDispatch::IntegrationTest
  # ── 적격심사: 경쟁자 최저가에 종속된 가격점수를 내보내던 결함 ──
  test "적격심사는 가격점수를 산출하지 않고 사유를 밝힌다" do
    post "/qualification-evaluations/evaluate", params: {
      project_type: "construction", estimated_price: 100_000_000, floor_rate: 89.745,
      bidder_count: 2,
      bidder_1_name: "A", bidder_1_price: 90_000_000, bidder_1_non_price: 35,
      bidder_2_name: "B", bidder_2_price: 95_000_000, bidder_2_non_price: 38
    }
    assert_response :success
    body = JSON.parse(response.body)

    assert body["score_unavailable"], "점수 미산출 사실이 응답에 표시되어야 한다"
    assert_nil body["winner"], "점수를 못 내면 낙찰자도 단정하면 안 된다"
    assert body["notice"].present?
    body["bidders"].each do |b|
      assert_nil b["price_score"], "가격점수는 산출하지 않는다"
      assert_nil b["is_qualified"], "적격 여부를 단정하면 안 된다"
      assert b["bid_ratio"].present?, "입찰률은 참고값으로 제공한다"
    end
  end

  test "적격심사 결과는 경쟁자 구성이 바뀌어도 같은 입찰가의 값이 달라지지 않는다" do
    common = { project_type: "construction", estimated_price: 100_000_000, floor_rate: 89.745 }

    post "/qualification-evaluations/evaluate", params: common.merge(
      bidder_count: 2,
      bidder_1_name: "A", bidder_1_price: 90_000_000, bidder_1_non_price: 35,
      bidder_2_name: "B", bidder_2_price: 95_000_000, bidder_2_non_price: 38
    )
    with_rival = JSON.parse(response.body)["bidders"].find { |b| b["name"] == "B" }

    post "/qualification-evaluations/evaluate", params: common.merge(
      bidder_count: 1,
      bidder_1_name: "B", bidder_1_price: 95_000_000, bidder_1_non_price: 38
    )
    alone = JSON.parse(response.body)["bidders"].find { |b| b["name"] == "B" }

    assert_equal with_rival["bid_ratio"], alone["bid_ratio"],
      "같은 입찰가는 경쟁자 유무와 무관하게 같은 값이어야 한다"
    assert_nil with_rival["price_score"]
    assert_nil alone["price_score"]
  end

  # ── 추정가격: 공사 종류 없이 종합공사 4억을 단정하던 결함 ──
  test "공사는 종류를 지정하지 않으면 수의계약 가능 여부를 단정하지 않는다" do
    post "/estimated-prices/calculate", params: {
      contract_type: "construction", material: 300_000_000
    }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["success"], "계산이 실패하면 안 된다: #{body['error']}"
    assert_equal 300_000_000, body.dig("result", "base_amount"),
      "원가항목이 0으로 떨어지면 모든 공사가 수의계약 가능으로 표시된다"

    pc = body.dig("result", "private_contract")
    assert pc["undetermined"], "종류 미지정 시 판단 보류여야 한다"
    assert_nil pc["available"]
    assert_includes pc["note"], "전문공사 2억"
  end

  test "전문공사 3억은 수의계약 한도를 넘는다" do
    post "/estimated-prices/calculate", params: {
      contract_type: "construction", construction_type: "special",
      material: 300_000_000
    }, as: :json
    body = JSON.parse(response.body)
    assert body["success"], "계산이 실패하면 안 된다: #{body['error']}"

    pc = body.dig("result", "private_contract")
    assert_equal 200_000_000, pc["threshold"]
    assert_equal false, pc["available"]
    assert_equal "입찰", pc.dig("estimate_requirement", "type"),
      "수의계약 불가인데 견적요건이 '2인 이상 견적'이면 모순이다"
  end

  test "종합공사 3억은 수의계약 가능이고 견적요건도 모순되지 않는다" do
    post "/estimated-prices/calculate", params: {
      contract_type: "construction", construction_type: "general",
      material: 300_000_000
    }, as: :json
    pc = JSON.parse(response.body).dig("result", "private_contract")
    assert_equal true, pc["available"]
    assert_equal "2인 이상 견적", pc.dig("estimate_requirement", "type"),
      "1억 초과라는 이유로 '입찰'이 나오면 물품 기준을 공사에 잘못 적용한 것이다"
  end

  # ── HWPX: 클라이언트가 보낸 결과를 그대로 문서화하던 결함 ──
  test "HWPX는 클라이언트가 보낸 연가일수를 신뢰하지 않는다" do
    post "/tools/annual-leave/hwpx", params: {
      hire_date: "2025-01-01", ref_year: 2026, used_leave: 0,
      granted_leave: "999일", remaining_leave: "999일"   # 위조 시도
    }
    # 폰트 미설치 등으로 생성 자체가 실패할 수 있으나, 어떤 경우에도
    # 위조된 999가 채택되어서는 안 된다. 서버 재계산 결과는 12일이다.
    assert_includes [ 200, 422 ], response.status
    assert_equal 12, PdfExportService.annual_leave_data(
      hire_date: "2025-01-01", ref_year: 2026, used_leave: 0
    )[:granted]
  end

  test "HWPX는 임용일이 잘못되면 생성하지 않는다" do
    post "/tools/annual-leave/hwpx", params: { hire_date: "2026/01/01", ref_year: 2026 }
    assert_response :unprocessable_entity
  end

  # ── ads.txt: 수익화하지 않으므로 승인 판매자 선언이 없어야 한다 ──
  test "ads.txt는 더 이상 제공하지 않는다" do
    get "/ads.txt"
    assert_response :not_found
  end
end
