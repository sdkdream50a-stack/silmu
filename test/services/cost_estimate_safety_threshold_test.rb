# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P1 — 물량내역서 생성 문서와 화면 미리보기의 산업안전보건관리비 판정이 달랐다.
# 고시 제3조 적용범위는 «총공사금액» 2천만원 이상 — 직접비(1,600만)만으로 비교하던 서버는 산안비를 빠뜨렸다.
class CostEstimateSafetyThresholdTest < ActiveSupport::TestCase
  def safety_for(direct)
    CostEstimateGeneratorService.send(:calculate_indirect_costs, direct)[:details].find { |d| d[:name] == "산업안전보건관리비" }
  end

  test "직접비 1,600만원 공사는 총공사금액이 2천만원을 넘어 산안비를 계상한다" do
    # 화면과 같은 산식: (16,000,000 + 일반관리비 960,000 + 이윤 1,104,000 + 보험료 857,600) × 1.1 = 20,813,760
    row = safety_for(16_000_000)
    assert row, "산안비가 빠졌다"
    assert_equal (16_000_000 * 0.0311).round, row[:amount]
  end

  test "음성 대조 — 직접비 1,000만원 공사는 총공사금액이 2천만원 미만이라 계상하지 않는다" do
    assert_nil safety_for(10_000_000)
  end
end
