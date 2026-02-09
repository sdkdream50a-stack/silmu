# 예정가격 계산기 서비스
# 계약유형별 원가항목을 합산하여 예정가격을 산출
class EstimatedPriceService
  # 계약 유형
  CONTRACT_TYPES = {
    goods: {
      name: "물품구매",
      icon: "inventory_2",
      desc: "물품·비품 구매 계약"
    },
    service: {
      name: "용역",
      icon: "engineering",
      desc: "일반·학술·SW 용역"
    },
    construction: {
      name: "공사",
      icon: "construction",
      desc: "시설공사·유지보수공사"
    }
  }.freeze

  # 유형별 원가항목
  COST_ITEMS = {
    goods: [
      { id: "unit_price", name: "단가", note: "물품 1개당 가격" },
      { id: "quantity", name: "수량", note: "구매 수량", is_quantity: true },
      { id: "delivery_fee", name: "운반비", note: "운송·하역 비용 (해당시)" },
      { id: "install_fee", name: "설치비", note: "설치·시운전 비용 (해당시)" }
    ],
    service: [
      { id: "direct_labor", name: "직접인건비", note: "노임단가 × 투입 M/M" },
      { id: "overhead", name: "제경비", note: "직접인건비의 110~120%" },
      { id: "direct_expense", name: "직접경비", note: "여비·인쇄비 등 실비" },
      { id: "general_admin", name: "일반관리비", note: "노무비+경비의 5~8%" },
      { id: "profit", name: "이윤", note: "노무비+경비+일반관리비의 10% 이내" }
    ],
    construction: [
      { id: "material", name: "재료비", note: "자재·부재료비" },
      { id: "direct_labor", name: "직접노무비", note: "직접 시공 인건비" },
      { id: "indirect_labor", name: "간접노무비", note: "직접노무비의 일정비율" },
      { id: "industrial_insurance", name: "산재보험료", note: "노무비의 일정비율" },
      { id: "expense", name: "경비", note: "기계경비·가설비·운반비 등" },
      { id: "general_admin", name: "일반관리비", note: "재+노+경의 8% 이내" },
      { id: "profit", name: "이윤", note: "노+경+관의 15% 이내" }
    ]
  }.freeze

  # 요율 상한
  RATE_LIMITS = {
    goods: { profit: { max: 0.25, basis: "원가", name: "이윤" } },
    service: { profit: { max: 0.10, basis: "노무비+경비+일반관리비", name: "이윤" },
               general_admin: { max: 0.08, basis: "노무비+경비", name: "일반관리비" } },
    construction: { profit: { max: 0.15, basis: "노무비+경비+일반관리비", name: "이윤" },
                    general_admin: { max: 0.08, basis: "재료비+노무비+경비", name: "일반관리비" } }
  }.freeze

  # 수의계약 기준금액
  PRIVATE_CONTRACT_THRESHOLDS = {
    goods: 50_000_000,
    service: 50_000_000,
    construction: 160_000_000
  }.freeze

  VAT_RATE = 0.10

  class << self
    def get_contract_types
      CONTRACT_TYPES.map { |key, val| { id: key.to_s, name: val[:name], icon: val[:icon], desc: val[:desc] } }
    end

    def get_cost_items(type)
      type_sym = type.to_s.to_sym
      return [] unless COST_ITEMS.key?(type_sym)
      COST_ITEMS[type_sym]
    end

    def calculate(params)
      type = params[:contract_type].to_s.to_sym
      return { success: false, error: "유효하지 않은 계약유형입니다." } unless CONTRACT_TYPES.key?(type)

      items = COST_ITEMS[type]
      amounts = {}
      items.each do |item|
        amounts[item[:id].to_sym] = params[item[:id]].to_i
      end

      # 기초금액 계산
      base_amount = calculate_base_amount(type, amounts)
      vat = (base_amount * VAT_RATE).round(0)
      estimated_price = base_amount + vat

      # 요율 검증
      warnings = check_rate_limits(type, amounts, base_amount)

      # 수의계약 가능 여부 + 견적 요건
      threshold = PRIVATE_CONTRACT_THRESHOLDS[type]
      estimate_requirement = determine_estimate_requirement(estimated_price)
      private_contract = {
        available: estimated_price <= threshold,
        threshold: threshold,
        type_name: CONTRACT_TYPES[type][:name],
        estimate_requirement: estimate_requirement
      }

      # 복수예비가격 시뮬레이션 (기초금액 ±3%, 15개)
      multiple_prices = generate_multiple_prices(base_amount)

      {
        success: true,
        result: {
          type_name: CONTRACT_TYPES[type][:name],
          base_amount: base_amount,
          vat: vat,
          estimated_price: estimated_price,
          amounts: amounts,
          warnings: warnings,
          private_contract: private_contract,
          multiple_prices: multiple_prices
        }
      }
    end

    private

    def calculate_base_amount(type, amounts)
      case type
      when :goods
        unit_total = amounts[:unit_price] * [amounts[:quantity], 1].max
        unit_total + amounts.fetch(:delivery_fee, 0) + amounts.fetch(:install_fee, 0)
      when :service
        amounts[:direct_labor] + amounts[:overhead] + amounts[:direct_expense] +
          amounts[:general_admin] + amounts[:profit]
      when :construction
        amounts[:material] + amounts[:direct_labor] + amounts[:indirect_labor] +
          amounts[:industrial_insurance] + amounts[:expense] +
          amounts[:general_admin] + amounts[:profit]
      end
    end

    def check_rate_limits(type, amounts, base_amount)
      warnings = []
      limits = RATE_LIMITS[type]
      return warnings unless limits

      case type
      when :service
        # 일반관리비 검증: (노무비+경비) 기준
        labor_expense = amounts[:direct_labor] + amounts[:overhead] + amounts[:direct_expense]
        if labor_expense > 0 && amounts[:general_admin] > 0
          rate = amounts[:general_admin].to_f / labor_expense
          if rate > limits[:general_admin][:max]
            warnings << { item: "일반관리비", rate: (rate * 100).round(1), max: (limits[:general_admin][:max] * 100).round(0), message: "일반관리비율 #{(rate * 100).round(1)}%가 상한 #{(limits[:general_admin][:max] * 100).round(0)}%를 초과합니다." }
          end
        end
        # 이윤 검증
        profit_basis = amounts[:direct_labor] + amounts[:overhead] + amounts[:general_admin]
        if profit_basis > 0 && amounts[:profit] > 0
          rate = amounts[:profit].to_f / profit_basis
          if rate > limits[:profit][:max]
            warnings << { item: "이윤", rate: (rate * 100).round(1), max: (limits[:profit][:max] * 100).round(0), message: "이윤율 #{(rate * 100).round(1)}%가 상한 #{(limits[:profit][:max] * 100).round(0)}%를 초과합니다." }
          end
        end
      when :construction
        # 일반관리비 검증: (재+노+경) 기준
        total_cost = amounts[:material] + amounts[:direct_labor] + amounts[:indirect_labor] +
                     amounts[:industrial_insurance] + amounts[:expense]
        if total_cost > 0 && amounts[:general_admin] > 0
          rate = amounts[:general_admin].to_f / total_cost
          if rate > limits[:general_admin][:max]
            warnings << { item: "일반관리비", rate: (rate * 100).round(1), max: (limits[:general_admin][:max] * 100).round(0), message: "일반관리비율 #{(rate * 100).round(1)}%가 상한 #{(limits[:general_admin][:max] * 100).round(0)}%를 초과합니다." }
          end
        end
        # 이윤 검증: (노무비+경비+일반관리비) 기준
        profit_basis = amounts[:direct_labor] + amounts[:indirect_labor] +
                       amounts[:industrial_insurance] + amounts[:expense] + amounts[:general_admin]
        if profit_basis > 0 && amounts[:profit] > 0
          rate = amounts[:profit].to_f / profit_basis
          if rate > limits[:profit][:max]
            warnings << { item: "이윤", rate: (rate * 100).round(1), max: (limits[:profit][:max] * 100).round(0), message: "이윤율 #{(rate * 100).round(1)}%가 상한 #{(limits[:profit][:max] * 100).round(0)}%를 초과합니다." }
          end
        end
      end

      warnings
    end

    def determine_estimate_requirement(price)
      if price <= 2_000_000
        { type: "생략가능", desc: "200만원 이하: 견적서 생략 또는 1인 견적", basis: "지방계약법 시행령 제30조제2항" }
      elsif price <= 22_000_000
        { type: "1인견적", desc: "2천만원 이하(부가세 포함 2,200만원): 1인 견적 수의계약", basis: "지방계약법 시행령 제25조제1항제5호" }
      elsif price <= 50_000_000
        { type: "2인 이상 견적", desc: "5천만원 이하: 2인 이상 견적 비교 (특례기업은 1인 가능)", basis: "지방계약법 시행령 제25조제1항제5호, 제30조제1항" }
      elsif price <= 110_000_000
        { type: "특례기업 수의계약", desc: "1억원 이하: 소기업·여성·장애인·사회적기업 등은 2인 이상 견적 수의계약 가능", basis: "지방계약법 시행령 제25조제1항제5호 다목~마목" }
      else
        { type: "입찰", desc: "수의계약 기준 초과: 경쟁입찰 진행 필요", basis: "지방계약법 제9조" }
      end
    end

    def generate_multiple_prices(base_amount)
      prices = []
      15.times do
        variation = (rand * 6 - 3) / 100.0  # -3% ~ +3%
        price = (base_amount * (1 + variation)).round(0)
        prices << { price: price, rate: (variation * 100).round(2) }
      end
      prices.sort_by { |p| p[:price] }
    end
  end
end
