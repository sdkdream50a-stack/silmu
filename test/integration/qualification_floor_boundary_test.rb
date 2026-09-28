# frozen_string_literal: true

require "test_helper"

# 2026-09-28 전 도구 기능 감사 P0 — 하한가와 정확히 같은 입찰을 «낙찰하한율 미달» 로 오판(Float 오차).
# 지방계약법 시행령 §42 적격심사·종합심사 모두 «낙찰하한율 이상» 이 유효. 하한가 투찰은 가장 흔한 투찰점이다.
class QualificationFloorBoundaryTest < ActionDispatch::IntegrationTest
  CASES = [
    # [예정가격, 하한율, 정확한 하한가]
    [ 1_000_000_000, "89.745", 897_450_000 ],
    [ 500_000_000,   "87.745", 438_725_000 ],
    [ 300_000_000,   "88.745", 266_235_000 ]
  ].freeze

  def evaluate(estimated, rate, bid)
    post "/qualification-evaluations/evaluate", params: {
      project_type: "construction", estimated_price: estimated, floor_rate: rate,
      bidder_count: 1, bidder_1_name: "A", bidder_1_price: bid, bidder_1_non_price: 30
    }
    assert_response :success
    JSON.parse(response.body)["bidders"].first
  end

  test "하한가와 정확히 같은 입찰은 미달이 아니다" do
    CASES.each do |estimated, rate, floor|
      b = evaluate(estimated, rate, floor)
      assert_equal false, b["below_floor"], "#{estimated}×#{rate}% 하한가 #{floor} 입찰이 미달로 판정됐다"
      assert_equal true, b["is_valid"]
    end
  end

  test "음성 대조 — 하한가보다 1원 낮으면 미달이다" do
    CASES.each do |estimated, rate, floor|
      assert_equal true, evaluate(estimated, rate, floor - 1)["below_floor"], "#{floor - 1} 입찰이 미달로 잡히지 않았다"
    end
  end

  test "하한가가 원 단위로 떨어지지 않을 때는 올림한 금액부터 유효하다" do
    # 123,456,789 × 89.745% = 110,796,295.29… → 110,796,295 는 미달, 110,796,296 은 유효
    assert_equal true,  evaluate(123_456_789, "89.745", 110_796_295)["below_floor"]
    assert_equal false, evaluate(123_456_789, "89.745", 110_796_296)["below_floor"]
  end

  test "종합심사 경로도 같은 경계 규칙을 쓴다" do
    post "/qualification-evaluations/comprehensive", params: {
      estimated_price: 40_000_000_000, floor_rate: "89.745", bidder_count: 2,
      bidder_1_name: "AT", bidder_1_price: 35_898_000_000, bidder_1_construction: 20, bidder_1_capacity: 15, bidder_1_management: 10, bidder_1_social: 5,
      bidder_2_name: "BELOW", bidder_2_price: 35_897_999_999, bidder_2_construction: 20, bidder_2_capacity: 15, bidder_2_management: 10, bidder_2_social: 5
    }
    assert_response :success
    by = JSON.parse(response.body)["bidders"].index_by { |b| b["name"] }
    assert_equal false, by["AT"]["below_floor"], "종심 하한가 정확 투찰이 미달로 판정됐다"
    assert_equal true, by["BELOW"]["below_floor"]
  end
end
