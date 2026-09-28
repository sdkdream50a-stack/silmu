# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P2 — 소요예산 추정기.
# 구간 경계에서 요율표를 통짜로 조회해(단일 구간 요율 × 전체 금액) 공사비가 늘었는데
# 설계비가 줄어드는 절벽이 있었다(건축 공사비 1억→6,500,000원, 1억100만→5,555,000원).
# 소득세 누진공제처럼 구간별 폭에 그 구간 요율을 곱해 누적하는 방식으로 교정한다.
class EstimateCalculatorServiceTest < ActiveSupport::TestCase
  test "공사비 구간 경계를 살짝 넘겨도 설계비가 줄지 않고 늘어난다(단조 증가)" do
    at_boundary = EstimateCalculatorService.estimate_design_fee(
      construction_cost: 100_000_000, design_type: "architecture"
    )
    just_over = EstimateCalculatorService.estimate_design_fee(
      construction_cost: 101_000_000, design_type: "architecture"
    )

    assert at_boundary[:success]
    assert just_over[:success]
    assert_operator just_over[:summary][:design_fee], :>, at_boundary[:summary][:design_fee]
  end

  test "구간 안(1억 이하)에서는 기존과 같은 6.5% 단일 요율 결과와 일치한다" do
    result = EstimateCalculatorService.estimate_design_fee(
      construction_cost: 100_000_000, design_type: "architecture"
    )
    assert_equal 6_500_000, result[:summary][:design_fee]
  end

  test "여러 구간에 걸치면 각 구간 폭만큼만 그 구간 요율이 적용된 가중평균이다" do
    # 30억(300000_0000_0000?) 대신 6억으로: 1억×6.5% + 4억×5.5% + 1억×4.8% = 6,500,000+22,000,000+4,800,000=33,300,000
    result = EstimateCalculatorService.estimate_design_fee(
      construction_cost: 600_000_000, design_type: "architecture"
    )
    assert_equal 33_300_000, result[:summary][:design_fee]
  end
end
