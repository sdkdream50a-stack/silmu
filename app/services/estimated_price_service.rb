# 추정가격 계산기 서비스
# 계약유형별 원가항목을 합산하여 추정가격(VAT 제외)을 산출
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
      { id: "general_admin", name: "일반관리비", note: "직접인건비+제경비+직접경비의 5% 이내 (학술연구용역: 회계예규 §28, 시행규칙 §8 별표)" },
      { id: "profit", name: "이윤", note: "직접인건비+제경비+직접경비+일반관리비의 10% 이내 (학술연구용역)" }
    ],
    construction: [
      { id: "material", name: "재료비", note: "자재·부재료비" },
      { id: "direct_labor", name: "직접노무비", note: "직접 시공 인건비" },
      { id: "indirect_labor", name: "간접노무비", note: "직접노무비의 일정비율" },
      { id: "industrial_insurance", name: "산재보험료", note: "노무비의 일정비율" },
      { id: "expense", name: "경비", note: "기계경비·가설비·운반비 등" },
      { id: "general_admin", name: "일반관리비", note: "재료비+노무비+경비의 6% 이내 (50억 미만 6.0%/50~300억 5.5%/300억 이상 5.0%, 일반건설공사, 회계예규 §20)" },
      { id: "profit", name: "이윤", note: "노무비+경비+일반관리비의 15% 이내 (회계예규 §21, 기술료·외주가공비 제외)" }
    ]
  }.freeze

  # 요율 상한 (회계예규 「원가계산에 의한 예정가격 작성기준」 §13·§14·§20·§21·§28)
  RATE_LIMITS = {
    goods: { profit: { max: 0.25, basis: "노무비+경비+일반관리비 (기술료·외주가공비 제외)", name: "이윤" } },
    service: { profit: { max: 0.10, basis: "직접인건비+제경비+직접경비+일반관리비", name: "이윤" },
               general_admin: { max: 0.05, basis: "직접인건비+제경비+직접경비", name: "일반관리비 (학술연구용역 §28)" } },
    construction: { profit: { max: 0.15, basis: "노무비+경비+일반관리비 (기술료·외주가공비 제외)", name: "이윤" },
                    general_admin: { max: 0.06, basis: "재료비+노무비+경비 (50억 미만 일반건설공사 / 50~300억 5.5% / 300억 이상 5.0%)", name: "일반관리비" } }
  }.freeze

  # 수의계약 기준금액 (지방계약법 시행령 제25조 제1항)
  PRIVATE_CONTRACT_THRESHOLDS = {
    goods: 20_000_000,          # 2천만원 (일반)
    service: 20_000_000,        # 2천만원 (일반)
    construction: 400_000_000   # 4억원 (종합공사 기준 - 가장 일반적 발주)
  }.freeze

  # 공사 종류별 수의계약 한도 (지방계약법 시행령 제25조 제1항 제5호)
  CONSTRUCTION_THRESHOLDS = {
    general: 400_000_000,    # 종합공사 4억
    special: 200_000_000,    # 전문공사 2억
    other: 160_000_000       # 기타공사(전기·정보통신·소방시설 등) 1.6억
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

    def calculate(raw_params)
      # 컨트롤러는 심볼 키 Hash를, 뷰(JSON)·테스트·직접 호출은 문자열 키를 넘긴다.
      # 한쪽 표기만 조회하면 값이 전부 nil이 되어 추정가격이 0으로 나오고
      # 모든 공사가 "수의계약 가능"으로 표시된다. 진입부에서 한 번만 정규화한다.
      params = normalize_keys(raw_params)

      type = params[:contract_type].to_s.to_sym
      return { success: false, error: "유효하지 않은 계약유형입니다." } unless CONTRACT_TYPES.key?(type)

      items = COST_ITEMS[type]
      amounts = {}
      items.each do |item|
        amounts[item[:id].to_sym] = params[item[:id].to_sym].to_i
      end

      # 기초금액 계산 (= 추정가격, VAT 제외)
      base_amount = calculate_base_amount(type, amounts)
      vat = (base_amount * VAT_RATE).round(0)
      total_with_vat = base_amount + vat

      # 요율 검증
      warnings = check_rate_limits(type, amounts, base_amount)

      # 수의계약 가능 여부 + 견적 요건 — 추정가격(VAT 제외) 기준 비교
      # 공사는 종류(종합 4억 / 전문 2억 / 기타 1.6억)에 따라 한도가 다르다.
      # 종류를 모르면 4억을 단정하지 않고 "종류 확인 필요"로 돌려준다 —
      # 3억 공사에 대해 "수의계약 가능"과 "1억 초과라 입찰"을 동시에 답하던 결함의 원인이었다.
      construction_type = params[:construction_type].to_s.to_sym
      threshold =
        if type == :construction
          CONSTRUCTION_THRESHOLDS[construction_type]
        else
          PRIVATE_CONTRACT_THRESHOLDS[type]
        end

      estimate_requirement = determine_estimate_requirement(type, base_amount, threshold)
      private_contract =
        if threshold
          {
            available: base_amount <= threshold,
            threshold: threshold,
            type_name: CONTRACT_TYPES[type][:name],
            estimate_requirement: estimate_requirement
          }
        else
          {
            available: nil,
            threshold: nil,
            undetermined: true,
            type_name: CONTRACT_TYPES[type][:name],
            note: "공사 종류를 선택해야 수의계약 한도를 판단할 수 있습니다 " \
                  "(종합공사 4억 / 전문공사 2억 / 기타공사(전기·정보통신·소방 등) 1.6억, 지방계약법 시행령 제25조 제1항 제5호).",
            estimate_requirement: estimate_requirement
          }
        end

      # 복수예비가격 시뮬레이션 (기초금액 ±3%, 15개)
      multiple_prices = generate_multiple_prices(base_amount)

      {
        success: true,
        result: {
          type_name: CONTRACT_TYPES[type][:name],
          base_amount: base_amount,
          vat: vat,
          estimated_price: total_with_vat,
          amounts: amounts,
          warnings: warnings,
          private_contract: private_contract,
          multiple_prices: multiple_prices
        }
      }
    end

    private

    # ActionController::Parameters·문자열 키 Hash·심볼 키 Hash를 모두 심볼 키로 통일한다.
    def normalize_keys(params)
      source = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params
      source.to_h.each_with_object({}) { |(k, v), acc| acc[k.to_sym] = v }
    end

    def calculate_base_amount(type, amounts)
      case type
      when :goods
        unit_total = amounts[:unit_price] * [ amounts[:quantity], 1 ].max
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
        # 이윤 검증: (직접인건비+제경비+직접경비+일반관리비) 기준 (국가계약법 시행규칙 제7조)
        profit_basis = amounts[:direct_labor] + amounts[:overhead] + amounts[:direct_expense] + amounts[:general_admin]
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

    # price = 추정가격 (VAT 제외)
    # threshold = 해당 계약의 수의계약 한도. 공사는 종류별로 다르고(4억/2억/1.6억),
    # 종류 미지정이면 nil이 들어온다. 물품·용역 기준(2천만·1억)을 공사에 그대로 적용하면
    # "수의계약 가능(≤4억)"과 "1억 초과라 입찰"이 동시에 나오는 모순이 생긴다.
    def determine_estimate_requirement(type, price, threshold = nil)
      # 견적서 생략(시행규칙 제33조)은 200만원 미만 물품·용역만 해당 — 공사는 미열거
      if price <= 2_000_000
        if type == :construction
          return { type: "1인견적", desc: "추정가격 2백만원 이하: 1인 견적 수의계약 (공사는 견적서 생략 대상 아님)", basis: "지방계약법 시행령 제30조제1항" }
        else
          return { type: "생략가능", desc: "추정가격 200만원 미만: 견적서 생략 가능 (200만원 이하는 1인 견적)", basis: "지방계약법 시행령 제30조제1항·제4항, 시행규칙 제33조" }
        end
      end

      return { type: "1인견적", desc: "추정가격 2천만원 이하: 1인 견적 수의계약", basis: "지방계약법 시행령 제30조제1항" } if price <= 20_000_000

      if type == :construction
        return { type: "확인 필요", desc: "공사 종류(종합/전문/기타)를 선택해야 수의계약 가능 여부와 견적 요건을 판단할 수 있습니다", basis: "지방계약법 시행령 제25조제1항제5호" } if threshold.nil?

        if price <= threshold
          { type: "2인 이상 견적", desc: "2천만원 초과 ~ 수의계약 한도(#{format_amount(threshold)}) 이하: 2인 이상 견적 수의계약", basis: "지방계약법 시행령 제25조제1항제5호·제30조제1항" }
        else
          { type: "입찰", desc: "수의계약 한도(#{format_amount(threshold)}) 초과: 경쟁입찰 진행 필요", basis: "지방계약법 제9조" }
        end
      elsif price <= 100_000_000
        { type: "2인 이상 견적 또는 특례 수의", desc: "2천만원 초과: 일반 기업은 입찰, 특례기업(청년창업·소기업·소상공인·여성·장애인·사회적기업 등)은 5천만원~1억원 이하 수의계약 가능", basis: "지방계약법 시행령 제25조제1항제5호" }
      else
        { type: "입찰", desc: "1억원 초과: 경쟁입찰 진행 필요", basis: "지방계약법 제9조" }
      end
    end

    def format_amount(won)
      eok = won / 100_000_000.0
      eok == eok.to_i ? "#{eok.to_i}억원" : "#{eok.round(1)}억원"
    end

    # 복수예비가격 15개는 **서로 달라야** 한다. ±3% 범위 안의 정수가 15개 미만이면
    # 만들 수 없으므로(예: 기초금액 200원 → 194~206원, 13개) 무한 시도 대신 빈 배열을 돌려준다.
    def generate_multiple_prices(base_amount)
      return [] if base_amount <= 0

      # ±3% "안쪽"의 정수만 허용한다. floor/ceil을 바깥쪽으로 쓰면 범위를 벗어난 가격이 섞인다
      # (기초금액 201원: 올바른 범위 195~207원 13개인데, 바깥쪽 반올림이면 194~208원 15개가 되어 통과).
      min_price = (base_amount * 0.97).ceil
      max_price = (base_amount * 1.03).floor
      return [] if max_price - min_price + 1 < 15

      seen = {}
      while seen.size < 15
        price = rand(min_price..max_price)
        seen[price] ||= { price: price, rate: ((price - base_amount) * 100.0 / base_amount).round(2) }
      end
      seen.values.sort_by { |p| p[:price] }
    end
  end
end
