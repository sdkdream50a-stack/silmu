# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P0 — 지방계약법 시행령 §73① «100분의 3 이상» 인데 가중 등락률이 정확히 3% 이면 Float 오차로 «조정 불가».
class PriceAdjustmentThresholdTest < ApplicationSystemTestCase
  def eligible_for(rate)
    visit "/tools/price-adjustment-calculator"
    page.evaluate_script("meetsThreshold(#{rate})")
  end

  test "가중 등락률 (2×1+3.1×10)/11 = 3% 는 조정 가능" do
    visit "/tools/price-adjustment-calculator"
    rate = page.evaluate_script("((102-100)/100*100*10000 + (103.1-100)/100*100*100000) / 110000")
    assert_operator rate, :<, 3, "재현 전제: JS 가 3 보다 작은 값을 낸다(#{rate})"
    assert page.evaluate_script("meetsThreshold(#{rate})"), "정확히 3% 인데 조정 불가로 판정"
  end

  test "음성 대조 — 2.999% 는 여전히 불가, 3.001% 는 가능, 감액 −3% 도 가능" do
    assert_not eligible_for(2.999)
    assert eligible_for(3.001)
    assert eligible_for(-3.0)
  end
end
