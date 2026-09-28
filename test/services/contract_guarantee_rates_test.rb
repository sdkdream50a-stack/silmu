# frozen_string_literal: true

require "test_helper"

# 지방계약법 시행령 §51①1호·⑤ — 계약보증금은 공사·물품·용역 등 모두 계약금액의 10% 이상.
# 5% 는 행정안전부가 기간을 정해 고시한 경우(단서)뿐이다. 2026-09-28 감사 전에는 임대차를 5% 로 계산했다.
class ContractGuaranteeRatesTest < ActiveSupport::TestCase
  test "임대차를 포함한 모든 일반 유형의 계약보증금률은 10% 다" do
    %i[general construction service lease].each do |type|
      assert_equal 0.10, ContractGuaranteeService::CONTRACT_GUARANTEE_RATES[type][:rate], "#{type} 보증금률"
    end
  end

  test "임대차 1억 계약의 계약보증금은 1천만원이다" do
    result = ContractGuaranteeService.calculate(contract_amount: "100000000", guarantee_type: "lease", defect_work_types: [])
    amount = result.dig(:result, :contract_guarantee, :amount)
    assert_equal 10_000_000, amount.to_i
  end

  test "음성 대조 — 소액 면제 유형은 여전히 0 이다" do
    assert_equal 0.0, ContractGuaranteeService::CONTRACT_GUARANTEE_RATES[:small_private][:rate]
  end
end
