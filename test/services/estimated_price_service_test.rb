# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P2 — 추정가격 계산기.
# ① 시행규칙 제33조2호 "추정가격 200만원 미만"인데 `<=`로 200만원 정각도 생략가능으로 잘못 판정.
# ② 0원·음수 입력에도 "수의계약 가능/생략가능"이 그대로 표시됐다(검증 없음).
class EstimatedPriceServiceTest < ActiveSupport::TestCase
  def goods_params(unit_price:, quantity: 1)
    { contract_type: "goods", unit_price: unit_price, quantity: quantity, delivery_fee: 0, install_fee: 0 }
  end

  test "199,999원은 200만원 미만이라 생략가능이다" do
    result = EstimatedPriceService.calculate(goods_params(unit_price: 1_999_999))
    assert result[:success]
    assert_equal "생략가능", result[:result][:private_contract][:estimate_requirement][:type]
  end

  test "정확히 200만원은 미만이 아니므로 1인견적이다(생략가능 아님)" do
    result = EstimatedPriceService.calculate(goods_params(unit_price: 2_000_000))
    assert result[:success]
    assert_equal "1인견적", result[:result][:private_contract][:estimate_requirement][:type]
  end

  test "0원 입력은 계산을 거부한다" do
    result = EstimatedPriceService.calculate(goods_params(unit_price: 0))
    assert_equal false, result[:success]
  end

  test "음수 합계(운반비 음수로 총액이 음수)는 계산을 거부한다" do
    params = goods_params(unit_price: 100).merge(delivery_fee: -1000)
    result = EstimatedPriceService.calculate(params)
    assert_equal false, result[:success]
  end
end
