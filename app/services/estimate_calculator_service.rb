# 소요예산 추정 서비스
# 소규모 공사/용역 시행 전 대략적인 소요예산을 추정하기 위한 서비스
# 주의: 본 서비스의 추정 결과는 참고용이며 실제 금액과 차이가 있을 수 있습니다.

class EstimateCalculatorService
  # 공사 종류별 기준 단가 (원/m² 또는 원/단위)
  CONSTRUCTION_BASE_PRICES = {
    # 인테리어/마감 공사
    "wallpaper" => { name: "도배", unit: "m²", base_price: 15_000, description: "벽지 도배" },
    "flooring" => { name: "장판/바닥재", unit: "m²", base_price: 35_000, description: "장판, 마루, 데코타일 등" },
    "tile" => { name: "타일", unit: "m²", base_price: 80_000, description: "바닥/벽 타일 시공" },
    "painting" => { name: "페인트", unit: "m²", base_price: 12_000, description: "내부 도장 공사" },
    "ceiling" => { name: "천장", unit: "m²", base_price: 45_000, description: "천장 마감, 텍스 등" },

    # 설비 공사
    "electric" => { name: "전기", unit: "개소", base_price: 150_000, description: "콘센트, 조명 등" },
    "plumbing" => { name: "배관", unit: "개소", base_price: 200_000, description: "상하수도 배관" },
    "aircon" => { name: "에어컨 설치", unit: "대", base_price: 350_000, description: "벽걸이/스탠드 에어컨" },
    "boiler" => { name: "보일러", unit: "대", base_price: 800_000, description: "보일러 교체" },

    # 기타 공사
    "window" => { name: "창호", unit: "m²", base_price: 250_000, description: "창문, 문 교체" },
    "demolition" => { name: "철거", unit: "m²", base_price: 25_000, description: "기존 시설 철거" },
    "waterproof" => { name: "방수", unit: "m²", base_price: 60_000, description: "옥상, 화장실 방수" },
    "partition" => { name: "칸막이", unit: "m²", base_price: 120_000, description: "사무실 파티션" }
  }.freeze

  # 용역 종류별 기준 단가 (원/인월 또는 원/시간)
  SERVICE_BASE_PRICES = {
    "maintenance" => { name: "유지보수", unit: "월", base_price: 3_000_000, description: "시스템/시설물 유지보수" },
    "cleaning" => { name: "청소용역", unit: "월", base_price: 2_500_000, description: "사무실/건물 청소" },
    "security" => { name: "경비용역", unit: "월", base_price: 3_500_000, description: "시설 경비" },
    "consulting" => { name: "컨설팅", unit: "일", base_price: 800_000, description: "전문 컨설팅" },
    "design" => { name: "디자인", unit: "건", base_price: 2_000_000, description: "그래픽/웹 디자인" },
    "research" => { name: "연구용역", unit: "건", base_price: 20_000_000, description: "정책연구, 조사분석" },
    "education" => { name: "교육훈련", unit: "시간", base_price: 150_000, description: "직원 교육" }
  }.freeze

  # 물품 카테고리별 기준 단가
  GOODS_BASE_PRICES = {
    "desk" => { name: "책상", unit: "개", base_price: 300_000, description: "사무용 책상" },
    "chair" => { name: "의자", unit: "개", base_price: 150_000, description: "사무용 의자" },
    "cabinet" => { name: "캐비닛", unit: "개", base_price: 200_000, description: "수납장, 서류함" },
    "computer" => { name: "컴퓨터", unit: "대", base_price: 1_200_000, description: "데스크탑 PC" },
    "laptop" => { name: "노트북", unit: "대", base_price: 1_500_000, description: "노트북 PC" },
    "monitor" => { name: "모니터", unit: "대", base_price: 350_000, description: "24인치 기준" },
    "printer" => { name: "프린터", unit: "대", base_price: 500_000, description: "레이저 프린터" },
    "projector" => { name: "프로젝터", unit: "대", base_price: 800_000, description: "빔프로젝터" },
    "aircon_unit" => { name: "에어컨", unit: "대", base_price: 1_500_000, description: "냉난방기" },
    "refrigerator" => { name: "냉장고", unit: "대", base_price: 600_000, description: "업소용 냉장고" }
  }.freeze

  # 자재 등급별 계수
  GRADE_MULTIPLIERS = {
    "basic" => { name: "기본형", multiplier: 1.0, description: "표준 사양" },
    "standard" => { name: "보통", multiplier: 1.3, description: "중급 사양" },
    "premium" => { name: "고급", multiplier: 1.7, description: "고급 사양" },
    "luxury" => { name: "프리미엄", multiplier: 2.2, description: "최고급 사양" }
  }.freeze

  # 간접비 비율 (공사/용역 특성에 따라 적용)
  INDIRECT_COST_RATES = {
    construction: {
      overhead: 0.06,        # 일반관리비 6%
      profit: 0.05,          # 이윤 5%
      safety: 0.025,         # 안전관리비 2.5%
      insurance: 0.035,      # 산재보험료 3.5%
      vat: 0.10              # 부가세 10%
    },
    service: {
      overhead: 0.05,        # 일반관리비 5%
      profit: 0.04,          # 이윤 4%
      vat: 0.10              # 부가세 10%
    },
    goods: {
      vat: 0.10              # 부가세 10%
    }
  }.freeze

  class << self
    # 공사 예산 추정
    def estimate_construction(items:, grade: "standard")
      return invalid_result("공사 항목을 선택해주세요.") if items.blank?

      grade_info = GRADE_MULTIPLIERS[grade] || GRADE_MULTIPLIERS["standard"]
      details = []
      direct_cost = 0

      items.each do |item|
        work_type = item[:type]
        quantity = item[:quantity].to_f

        next unless CONSTRUCTION_BASE_PRICES[work_type] && quantity > 0

        price_info = CONSTRUCTION_BASE_PRICES[work_type]
        unit_price = (price_info[:base_price] * grade_info[:multiplier]).round(-3)
        subtotal = (unit_price * quantity).round(-3)

        details << {
          name: price_info[:name],
          quantity: quantity,
          unit: price_info[:unit],
          unit_price: unit_price,
          subtotal: subtotal
        }

        direct_cost += subtotal
      end

      return invalid_result("유효한 공사 항목이 없습니다.") if details.empty?

      # 간접비 계산
      rates = INDIRECT_COST_RATES[:construction]
      overhead = (direct_cost * rates[:overhead]).round(-3)
      profit = (direct_cost * rates[:profit]).round(-3)
      safety = (direct_cost * rates[:safety]).round(-3)
      insurance = (direct_cost * rates[:insurance]).round(-3)

      subtotal = direct_cost + overhead + profit + safety + insurance
      vat = (subtotal * rates[:vat]).round(-3)
      total = subtotal + vat

      {
        success: true,
        type: :construction,
        grade: grade_info,
        details: details,
        summary: {
          direct_cost: direct_cost,
          overhead: overhead,
          profit: profit,
          safety: safety,
          insurance: insurance,
          subtotal: subtotal,
          vat: vat,
          total: total
        },
        range: calculate_range(total),
        disclaimer: construction_disclaimer
      }
    end

    # 용역 예산 추정
    def estimate_service(service_type:, duration:, personnel_count: 1, grade: "standard")
      return invalid_result("용역 종류를 선택해주세요.") unless SERVICE_BASE_PRICES[service_type]
      return invalid_result("기간을 입력해주세요.") if duration.to_f <= 0

      price_info = SERVICE_BASE_PRICES[service_type]
      grade_info = GRADE_MULTIPLIERS[grade] || GRADE_MULTIPLIERS["standard"]

      base_price = (price_info[:base_price] * grade_info[:multiplier]).round(-3)
      personnel = [ personnel_count.to_i, 1 ].max
      direct_cost = (base_price * duration.to_f * personnel).round(-3)

      # 간접비 계산
      rates = INDIRECT_COST_RATES[:service]
      overhead = (direct_cost * rates[:overhead]).round(-3)
      profit = (direct_cost * rates[:profit]).round(-3)

      subtotal = direct_cost + overhead + profit
      vat = (subtotal * rates[:vat]).round(-3)
      total = subtotal + vat

      {
        success: true,
        type: :service,
        grade: grade_info,
        details: [ {
          name: price_info[:name],
          duration: duration,
          unit: price_info[:unit],
          personnel: personnel,
          unit_price: base_price,
          subtotal: direct_cost
        } ],
        summary: {
          direct_cost: direct_cost,
          overhead: overhead,
          profit: profit,
          subtotal: subtotal,
          vat: vat,
          total: total
        },
        range: calculate_range(total),
        disclaimer: service_disclaimer
      }
    end

    # 물품 예산 추정
    def estimate_goods(items:, grade: "standard")
      return invalid_result("물품을 선택해주세요.") if items.blank?

      grade_info = GRADE_MULTIPLIERS[grade] || GRADE_MULTIPLIERS["standard"]
      details = []
      subtotal = 0

      items.each do |item|
        goods_type = item[:type]
        quantity = item[:quantity].to_i

        next unless GOODS_BASE_PRICES[goods_type] && quantity > 0

        price_info = GOODS_BASE_PRICES[goods_type]
        unit_price = (price_info[:base_price] * grade_info[:multiplier]).round(-3)
        item_total = unit_price * quantity

        details << {
          name: price_info[:name],
          quantity: quantity,
          unit: price_info[:unit],
          unit_price: unit_price,
          subtotal: item_total
        }

        subtotal += item_total
      end

      return invalid_result("유효한 물품 항목이 없습니다.") if details.empty?

      vat = (subtotal * INDIRECT_COST_RATES[:goods][:vat]).round(-3)
      total = subtotal + vat

      {
        success: true,
        type: :goods,
        grade: grade_info,
        details: details,
        summary: {
          subtotal: subtotal,
          vat: vat,
          total: total
        },
        range: calculate_range(total),
        disclaimer: goods_disclaimer
      }
    end

    # 가격 정보 조회 (프론트엔드용)
    def price_catalog
      {
        construction: CONSTRUCTION_BASE_PRICES.transform_values { |v| v.except(:base_price) },
        service: SERVICE_BASE_PRICES.transform_values { |v| v.except(:base_price) },
        goods: GOODS_BASE_PRICES.transform_values { |v| v.except(:base_price) },
        grades: GRADE_MULTIPLIERS
      }
    end

    private

    def calculate_range(total)
      # 추정 범위: -15% ~ +20%
      {
        min: (total * 0.85).round(-4),
        max: (total * 1.20).round(-4)
      }
    end

    def invalid_result(message)
      {
        success: false,
        error: message
      }
    end

    def construction_disclaimer
      <<~DISCLAIMER
        ※ 본 추정 금액은 일반적인 시장 단가를 기준으로 산출된 참고 자료입니다.
        ※ 실제 계약 금액은 현장 조건, 시공 난이도, 자재 품질, 업체 견적 등에 따라 달라질 수 있습니다.
        ※ 정확한 예산 산정을 위해서는 반드시 전문 업체의 현장 실사 및 정밀 견적을 받으시기 바랍니다.
        ※ 간접비(일반관리비, 이윤, 안전관리비, 산재보험료)는 「예정가격작성기준」에 따른 표준 요율을 적용하였습니다.
      DISCLAIMER
    end

    def service_disclaimer
      <<~DISCLAIMER
        ※ 본 추정 금액은 일반적인 용역 단가를 기준으로 산출된 참고 자료입니다.
        ※ 실제 계약 금액은 용역 범위, 수행 조건, 투입 인력 수준 등에 따라 달라질 수 있습니다.
        ※ 인건비 기준은 한국소프트웨어산업협회/엔지니어링협회 노임단가 등을 참고할 수 있습니다.
        ※ 정확한 예산 산정을 위해서는 원가계산서 작성 및 전문가 검토가 필요합니다.
      DISCLAIMER
    end

    def goods_disclaimer
      <<~DISCLAIMER
        ※ 본 추정 금액은 일반적인 시장 가격을 기준으로 산출된 참고 자료입니다.
        ※ 실제 구매 금액은 제조사, 모델, 구매 수량, 계약 조건 등에 따라 달라질 수 있습니다.
        ※ 조달청 나라장터(www.g2b.go.kr) 또는 디지털서비스몰 가격을 확인하시면 더 정확한 예산을 산정할 수 있습니다.
        ※ 대량 구매 시 할인이 적용될 수 있으며, 배송비가 별도로 발생할 수 있습니다.
      DISCLAIMER
    end
  end
end
