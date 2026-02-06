# 계약보증금·하자보증금·인지세 계산기 서비스
class ContractGuaranteeService
  # 계약보증금률 (지방계약법 시행령 제37조)
  CONTRACT_GUARANTEE_RATES = {
    general: { name: "일반 계약", rate: 0.10, note: "계약금액의 10% 이상" },
    construction: { name: "공사 계약", rate: 0.10, note: "계약금액의 10% 이상 (이행보증서 제출 가능)" },
    service: { name: "용역 계약", rate: 0.10, note: "계약금액의 10% 이상" },
    lease: { name: "임대차 계약", rate: 0.05, note: "계약금액의 5% 이상" },
    small_private: { name: "소액수의계약 (3천만원 이하)", rate: 0.0, note: "면제 가능 (지방계약법 시행규칙 제39조)" }
  }.freeze

  # 하자보수보증금률 (지방계약법 시행령 제78조)
  DEFECT_GUARANTEE_RATES = [
    { id: "structure", name: "구조체 공사", rate: 0.05, years: 5, note: "철근콘크리트·철골 구조" },
    { id: "roof_waterproof", name: "지붕·방수공사", rate: 0.03, years: 3, note: "지붕, 방수" },
    { id: "road", name: "도로·포장공사", rate: 0.03, years: 3, note: "아스팔트·콘크리트 포장" },
    { id: "civil", name: "토목공사", rate: 0.03, years: 3, note: "토공, 배수, 옹벽" },
    { id: "metal_window", name: "창호공사", rate: 0.02, years: 2, note: "금속·목재 창호" },
    { id: "electrical", name: "전기·설비공사", rate: 0.02, years: 2, note: "전기, 기계설비, 소방" },
    { id: "landscaping", name: "조경공사", rate: 0.02, years: 2, note: "조경식재, 시설물" },
    { id: "interior", name: "실내건축공사", rate: 0.02, years: 2, note: "바닥재, 벽체, 천장" },
    { id: "painting", name: "도장공사", rate: 0.01, years: 1, note: "내·외부 도장" },
    { id: "plaster", name: "미장·타일공사", rate: 0.01, years: 1, note: "미장, 타일, 돌붙임" }
  ].freeze

  # 인지세 기준 (인지세법 제3조, 시행령 별표)
  STAMP_TAX_TABLE = [
    { min: 0, max: 10_000_000, tax: 0, label: "1천만원 이하" },
    { min: 10_000_001, max: 30_000_000, tax: 20_000, label: "1천만원 초과 ~ 3천만원 이하" },
    { min: 30_000_001, max: 50_000_000, tax: 40_000, label: "3천만원 초과 ~ 5천만원 이하" },
    { min: 50_000_001, max: 100_000_000, tax: 70_000, label: "5천만원 초과 ~ 1억원 이하" },
    { min: 100_000_001, max: 1_000_000_000, tax: 150_000, label: "1억원 초과 ~ 10억원 이하" },
    { min: 1_000_000_001, max: Float::INFINITY, tax: 350_000, label: "10억원 초과" }
  ].freeze

  class << self
    def get_contract_guarantee_types
      CONTRACT_GUARANTEE_RATES.map { |key, val| { id: key.to_s, name: val[:name], note: val[:note] } }
    end

    def get_defect_work_types
      DEFECT_GUARANTEE_RATES.map { |item| { id: item[:id], name: item[:name], rate: (item[:rate] * 100).round(0), years: item[:years], note: item[:note] } }
    end

    def calculate(params)
      contract_amount = params[:contract_amount].to_i
      return { success: false, error: "계약금액을 입력해주세요." } if contract_amount <= 0

      results = {}

      # 1. 계약보증금 계산
      guarantee_type = params[:guarantee_type].to_s.to_sym
      guarantee_type = :general unless CONTRACT_GUARANTEE_RATES.key?(guarantee_type)
      rate_info = CONTRACT_GUARANTEE_RATES[guarantee_type]
      guarantee_amount = (contract_amount * rate_info[:rate]).round(0)

      results[:contract_guarantee] = {
        type_name: rate_info[:name],
        rate: (rate_info[:rate] * 100).round(0),
        amount: guarantee_amount,
        note: rate_info[:note],
        exempt: rate_info[:rate] == 0.0
      }

      # 2. 하자보수보증금 계산 (공사일 경우)
      selected_works = params[:defect_work_types] || []
      if selected_works.any?
        defect_results = selected_works.map do |work_id|
          item = DEFECT_GUARANTEE_RATES.find { |d| d[:id] == work_id.to_s }
          next unless item
          {
            name: item[:name],
            rate: (item[:rate] * 100).round(0),
            years: item[:years],
            amount: (contract_amount * item[:rate]).round(0),
            note: item[:note]
          }
        end.compact
        results[:defect_guarantee] = defect_results
      end

      # 3. 인지세 계산
      stamp_info = STAMP_TAX_TABLE.find { |t| contract_amount >= t[:min] && contract_amount <= t[:max] }
      stamp_tax = stamp_info ? stamp_info[:tax] : 0
      stamp_each = stamp_tax > 0 ? (stamp_tax / 2.0).ceil : 0

      results[:stamp_tax] = {
        amount: stamp_tax,
        each_party: stamp_each,
        label: stamp_info ? stamp_info[:label] : "",
        exempt: stamp_tax == 0,
        note: stamp_tax > 0 ? "발주자·계약자 각 50% 부담 (각 #{format_currency(stamp_each)}원)" : "1천만원 이하 면제"
      }

      # 4. 총 비용 요약
      total_guarantee = guarantee_amount
      total_defect = results[:defect_guarantee] ? results[:defect_guarantee].sum { |d| d[:amount] } : 0

      results[:summary] = {
        contract_amount: contract_amount,
        contract_guarantee: guarantee_amount,
        defect_guarantee_total: total_defect,
        stamp_tax: stamp_tax,
        total_cost: guarantee_amount + stamp_each
      }

      { success: true, result: results }
    end

    private

    def format_currency(amount)
      amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
