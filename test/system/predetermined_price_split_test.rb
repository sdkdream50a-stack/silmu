# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P2 — 지방 복수예비가격: 기초금액 ±3% 안에서 이상 7개·미만 8개
# («지방자치단체 입찰 및 계약 집행기준» 행정안전부예규 제372호). 종전 기본 ±2%·무작위 분포.
class PredeterminedPriceSplitTest < ApplicationSystemTestCase
  test "기본값은 ±3% 이고 기초금액 이상 7개·미만 8개를 만든다" do
    visit "/tools/predetermined-price"
    assert_equal "3", find("#range-rate", visible: :all).value
    5.times do
      prices = page.evaluate_script("generateMultiplePrices(100000000, 3)")
      assert_equal 15, prices.uniq.size
      assert_equal 7, prices.count { |p| p >= 100_000_000 }
      assert_equal 8, prices.count { |p| p < 100_000_000 }
      assert prices.all? { |p| p.between?(97_000_000, 103_000_000) }
    end
  end

  test "한쪽에 정수가 모자라는 작은 기초금액은 최소 금액을 안내한다" do
    visit "/tools/predetermined-price"
    min = page.evaluate_script("minimumBaseAmount(3)")
    sides = page.evaluate_script("sideCounts(#{min}, 0.03)")
    assert_operator sides["up"], :>=, 7
    assert_operator sides["down"], :>=, 8
  end
end
