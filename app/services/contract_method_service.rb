# 계약방식 결정 서비스
# 추정가격과 계약유형에 따라 적정 계약방식을 판단하고 관련 정보를 제공

class ContractMethodService
  # 계약방식 기준 (지방계약법 시행령 기준)
  CONTRACT_THRESHOLDS = {
    goods: {
      name: "물품",
      icon: "inventory_2",
      thresholds: [
        {
          max: 2_000_000,
          method: "소액수의계약",
          method_detail: "견적서 생략 또는 1인 견적",
          basis: "지방계약법 시행령 제25조제1항제5호 나목, 제30조제2항",
          note: "추정가격 200만원 이하 (200만원 미만은 견적서 생략 가능)",
          documents: %w[체결제한확인서 견적서 물품규격서 사업자등록증사본]
        },
        {
          max: 20_000_000,
          method: "수의계약",
          method_detail: "1인 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 나목",
          note: "추정가격 2천만원 이하 (예정가격 작성 생략 가능 — 시행령 제9조)",
          documents: %w[체결제한확인서 견적서 물품규격서 사업자등록증사본 청렴서약서]
        },
        {
          max: 50_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 라목·마목",
          note: "추정가격 5천만원 이하 (학술연구 등 특수분야 또는 여성·장애인·사회적기업 등 해당 시). G2B 전자견적 필수",
          special_condition: "일반 업체와의 계약은 2천만원 초과 시 경쟁입찰 대상. 특례기업은 5천만원까지 1인 견적 가능",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 물품규격서 예정가격조서 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: 100_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약 (특례기업)",
          basis: "지방계약법 시행령 제25조제1항제5호 다목~마목",
          note: "추정가격 1억원 이하 (소기업·소상공인·여성·장애인·사회적기업 등과의 계약에 한정). G2B 전자견적 필수",
          special_condition: "해당 기업 확인서 필수 (중소기업확인서·여성기업확인서 등). 중소기업자간 경쟁제품 해당 여부 확인 필요",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 물품규격서 예정가격조서 사업자등록증사본 청렴서약서 수의계약사유서 중소기업확인서]
        },
        {
          max: Float::INFINITY,
          method: "입찰",
          method_detail: "일반/제한경쟁입찰",
          basis: "지방계약법 제9조, 시행령 제13조",
          note: "추정가격 1억원 초과 (특례기업 외 일반 업체는 2천만원 초과 시 입찰)",
          special_condition: "나라장터(G2B) 또는 학교장터(S2B) 전자입찰 필수",
          documents: %w[입찰공고문 설계서 예정가격조서 입찰참가자격요건 계약서 계약보증금]
        }
      ]
    },
    service: {
      name: "용역",
      icon: "support_agent",
      thresholds: [
        {
          max: 2_000_000,
          method: "소액수의계약",
          method_detail: "견적서 생략 또는 1인 견적",
          basis: "지방계약법 시행령 제25조제1항제5호 나목, 제30조제2항",
          note: "추정가격 200만원 이하 (200만원 미만은 견적서 생략 가능)",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 20_000_000,
          method: "수의계약",
          method_detail: "1인 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 나목",
          note: "추정가격 2천만원 이하 (예정가격 작성 생략 가능 — 시행령 제9조)",
          documents: %w[체결제한확인서 견적서 사업자등록증사본 청렴서약서 과업내용서]
        },
        {
          max: 50_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 라목·마목",
          note: "추정가격 5천만원 이하 (학술연구 등 특수분야 또는 여성·장애인·사회적기업 등 해당 시). G2B 전자견적 필수",
          special_condition: "일반 업체와의 계약은 2천만원 초과 시 경쟁입찰 대상. 특례기업은 5천만원까지 1인 견적 가능",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 과업내용서 예정가격조서 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: 100_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약 (특례기업)",
          basis: "지방계약법 시행령 제25조제1항제5호 다목~마목",
          note: "추정가격 1억원 이하 (소기업·소상공인·여성·장애인·사회적기업 등과의 계약에 한정). G2B 전자견적 필수",
          special_condition: "해당 기업 확인서 필수 (중소기업확인서·여성기업확인서 등). 용역의 특성상 특정인 수의계약 가능 여부 검토 (제25조제1항제4호)",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 과업내용서 예정가격조서 사업자등록증사본 청렴서약서 수의계약사유서 중소기업확인서]
        },
        {
          max: Float::INFINITY,
          method: "입찰",
          method_detail: "일반/제한경쟁입찰 또는 협상에의한계약",
          basis: "지방계약법 제9조, 시행령 제13조, 제43조",
          note: "추정가격 1억원 초과 (특례기업 외 일반 업체는 2천만원 초과 시 입찰)",
          special_condition: "기술제안서 평가 등 협상에의한계약 적용 가능",
          documents: %w[입찰공고문 과업내용서 예정가격조서 평가기준 계약서 계약이행보증서]
        }
      ]
    },
    construction_general: {
      name: "종합공사",
      icon: "domain",
      thresholds: [
        {
          max: 2_000_000,
          method: "소액수의계약",
          method_detail: "견적서 생략 또는 1인 견적",
          basis: "지방계약법 시행령 제25조제1항제5호 가목, 제30조제2항",
          note: "추정가격 200만원 이하 (200만원 미만은 견적서 생략 가능)",
          type_display_name: "경미한 건설공사",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 20_000_000,
          method: "수의계약",
          method_detail: "1인 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목",
          note: "추정가격 2천만원 이하 (경미한 건설공사, 건설업 등록 불필요). 예정가격 작성 생략 가능 (시행령 제9조)",
          type_display_name: "경미한 건설공사",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 50_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목, 건설산업기본법 시행령 제8조",
          note: "추정가격 5천만원 이하 (경미한 건설공사). G2B 전자견적 필수",
          type_display_name: "경미한 건설공사",
          special_condition: "공사예정금액 5천만원 미만 시 건설업 등록 없이 시공 가능 (건설산업기본법 시행령 제8조)",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 설계서 예정가격조서 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: 400_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목",
          note: "추정가격 4억원 이하 (2022.9 개정 반영). G2B 전자견적 필수",
          special_condition: "건설업 등록업체만 참여 가능",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 설계서 예정가격조서 건설업등록증 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: Float::INFINITY,
          method: "입찰",
          method_detail: "일반/제한경쟁입찰",
          basis: "지방계약법 제9조, 건설산업기본법",
          note: "추정가격 4억원 초과",
          special_condition: "전자입찰 필수, PQ(사전심사) 또는 적격심사",
          documents: %w[입찰공고문 설계서 예정가격조서 입찰참가자격요건 계약서 계약보증금 이행보증서 하자보증서 산업재해보험가입증명]
        }
      ]
    },
    construction_special: {
      name: "전문공사",
      icon: "engineering",
      thresholds: [
        {
          max: 2_000_000,
          method: "소액수의계약",
          method_detail: "견적서 생략 또는 1인 견적",
          basis: "지방계약법 시행령 제25조제1항제5호 가목, 제30조제2항",
          note: "추정가격 200만원 이하 (200만원 미만은 견적서 생략 가능)",
          type_display_name: "경미한 건설공사",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 20_000_000,
          method: "수의계약",
          method_detail: "1인 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목",
          note: "추정가격 2천만원 이하 (경미한 건설공사). 예정가격 작성 생략 가능 (시행령 제9조)",
          type_display_name: "경미한 건설공사",
          special_condition: "공사예정금액 1,500만원 미만은 경미한 건설공사로 전문공사업 등록 불필요 (건설산업기본법 시행령 제8조)",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 200_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목",
          note: "추정가격 2억원 이하 (2022.9 개정 반영). G2B 전자견적 필수",
          special_condition: "해당 전문공사업 등록업체만 참여",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 설계서 예정가격조서 건설업등록증 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: Float::INFINITY,
          method: "입찰",
          method_detail: "일반/제한경쟁입찰",
          basis: "지방계약법 제9조, 건설산업기본법",
          note: "추정가격 2억원 초과",
          special_condition: "전자입찰 필수",
          documents: %w[입찰공고문 설계서 예정가격조서 입찰참가자격요건 계약서 계약보증금 이행보증서 하자보증서]
        }
      ]
    },
    construction_etc: {
      name: "전기/소방/정보통신공사",
      icon: "electrical_services",
      thresholds: [
        {
          max: 2_000_000,
          method: "소액수의계약",
          method_detail: "견적서 생략 또는 1인 견적",
          basis: "지방계약법 시행령 제25조제1항제5호 가목, 제30조제2항",
          note: "추정가격 200만원 이하 (200만원 미만은 견적서 생략 가능)",
          type_display_name: "경미한 건설공사",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 20_000_000,
          method: "수의계약",
          method_detail: "1인 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목",
          note: "추정가격 2천만원 이하 (경미한 건설공사). 예정가격 작성 생략 가능 (시행령 제9조)",
          type_display_name: "경미한 건설공사",
          documents: %w[체결제한확인서 견적서 사업자등록증사본]
        },
        {
          max: 50_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목, 각 개별법령(전기공사업법 등)",
          note: "추정가격 5천만원 이하. G2B 전자견적 필수",
          type_display_name: "경미한 건설공사",
          special_condition: "각 개별법령에서 정한 경미한 공사 범위 내 시 해당 공사업 등록 없이 가능",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 설계서 예정가격조서 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: 160_000_000,
          method: "수의계약",
          method_detail: "2인 이상 견적 수의계약",
          basis: "지방계약법 시행령 제25조제1항제5호 가목",
          note: "추정가격 1억6천만원 이하 (2022.9 개정 반영). G2B 전자견적 필수",
          special_condition: "해당 공사업 등록업체만 참여 (전기공사업, 소방시설업, 정보통신공사업)",
          documents: %w[체결제한확인서 견적서(2인이상) 견적비교표 설계서 예정가격조서 공사업등록증 사업자등록증사본 청렴서약서 수의계약사유서]
        },
        {
          max: Float::INFINITY,
          method: "입찰",
          method_detail: "일반/제한경쟁입찰",
          basis: "지방계약법 제9조, 각 개별법령",
          note: "추정가격 1억6천만원 초과",
          special_condition: "전자입찰 필수",
          documents: %w[입찰공고문 설계서 예정가격조서 입찰참가자격요건 계약서 계약보증금 이행보증서 하자보증서]
        }
      ]
    }
  }.freeze

  # 특례 조건 (여성기업, 장애인기업, 사회적기업 등)
  SPECIAL_ENTERPRISES = {
    women: { name: "여성기업", threshold: 50_000_000, basis: "여성기업지원에 관한 법률" },
    disabled: { name: "장애인기업", threshold: 50_000_000, basis: "장애인기업활동 촉진법" },
    social: { name: "사회적기업", threshold: 50_000_000, basis: "사회적기업 육성법" },
    cooperative: { name: "협동조합", threshold: 50_000_000, basis: "협동조합 기본법" },
    village: { name: "마을기업", threshold: 50_000_000, basis: "도시재생법" },
    self_support: { name: "자활기업", threshold: 50_000_000, basis: "국민기초생활보장법" },
    social_cooperative: { name: "사회적협동조합", threshold: 50_000_000, basis: "협동조합 기본법" }
  }.freeze

  # 낙찰하한율 기준 (지방계약법 시행령 제42조, 지방계약법 시행규칙 별표2)
  LOWEST_BID_RATES = {
    construction: {
      name: "공사",
      rates: [
        { min: 100_000_000_000, max: Float::INFINITY, rate: "87.745% ~ 89.745%", detail: "1,000억원 이상" },
        { min: 30_000_000_000, max: 100_000_000_000, rate: "87.495% ~ 89.495%", detail: "300억원 이상 ~ 1,000억원 미만" },
        { min: 0, max: 30_000_000_000, rate: "87.745% ~ 89.745%", detail: "300억원 미만" }
      ]
    },
    goods_service: {
      name: "물품·용역",
      rates: [
        { min: 20_000_001, max: Float::INFINITY, rate: "88.0%", detail: "2천만원 초과" },
        { min: 0, max: 20_000_000, rate: "90.0%", detail: "2천만원 이하" }
      ]
    }
  }.freeze

  # 관련 법령 정보
  RELATED_LAWS = {
    "지방계약법" => "https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률",
    "지방계약법 시행령" => "https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률시행령",
    "건설산업기본법" => "https://www.law.go.kr/법령/건설산업기본법",
    "중소기업제품 구매촉진법" => "https://www.law.go.kr/법령/중소기업제품구매촉진및판로지원에관한법률"
  }.freeze

  class << self
    # 계약방식 결정
    def determine(contract_type:, estimated_price:, special_enterprise: nil)
      return invalid_result("계약 유형을 선택해주세요.") if contract_type.blank?
      type_sym = contract_type.to_sym
      return invalid_result("유효하지 않은 계약 유형입니다.") unless CONTRACT_THRESHOLDS[type_sym]

      price = estimated_price.to_i
      return invalid_result("추정가격을 입력해주세요.") if price <= 0

      type_info = CONTRACT_THRESHOLDS[type_sym]

      # 해당 금액 구간 찾기
      threshold = type_info[:thresholds].find { |t| price <= t[:max] }

      # 특례기업 적용 여부 확인
      special_info = nil
      if special_enterprise && SPECIAL_ENTERPRISES[special_enterprise.to_sym]
        special_info = SPECIAL_ENTERPRISES[special_enterprise.to_sym]
        if price <= special_info[:threshold] && price > 20_000_000
          # 특례기업은 5천만원까지 1인 수의계약 가능
          threshold = threshold.merge(
            method_detail: "1인 견적 수의계약 (특례)",
            note: "#{special_info[:name]} 특례 적용 (#{format_currency(special_info[:threshold])}원 이하 1인 수의 가능)",
            special_applied: true
          )
        elsif price > special_info[:threshold] && price <= 100_000_000 && [ :goods, :service ].include?(type_sym)
          # 5천만원 초과 ~ 1억원 이하: 특례기업 2인 이상 견적 수의계약 가능
          threshold = threshold.merge(
            note: "#{special_info[:name]} 해당 시 수의계약 가능 (#{format_currency(price)}원, 2인 이상 견적 필수)",
            special_applied: true
          )
        end
      end

      {
        success: true,
        contract_type: {
          key: type_sym,
          name: threshold[:type_display_name] || type_info[:name],
          icon: type_info[:icon]
        },
        estimated_price: price,
        formatted_price: format_currency(price),
        result: {
          method: threshold[:method],
          method_detail: threshold[:method_detail],
          basis: threshold[:basis],
          note: threshold[:note],
          special_condition: threshold[:special_condition],
          documents: threshold[:documents],
          special_applied: threshold[:special_applied] || false
        },
        special_enterprise: special_info,
        lowest_bid_rate: calculate_lowest_bid_rate(type_sym, price, threshold[:method]),
        related_laws: RELATED_LAWS,
        warnings: generate_warnings(type_sym, price),
        tips: generate_tips(type_sym, price, threshold[:method])
      }
    end

    # 계약 유형 목록 조회
    def contract_types
      CONTRACT_THRESHOLDS.map do |key, value|
        {
          key: key,
          name: value[:name],
          icon: value[:icon]
        }
      end
    end

    # 특례기업 목록 조회
    def special_enterprises
      SPECIAL_ENTERPRISES.map do |key, value|
        { key: key, name: value[:name] }
      end
    end

    # 금액 구간별 계약방식 표 조회
    def threshold_table(contract_type)
      type_sym = contract_type.to_sym
      return nil unless CONTRACT_THRESHOLDS[type_sym]

      type_info = CONTRACT_THRESHOLDS[type_sym]
      type_info[:thresholds].map do |t|
        {
          max: t[:max] == Float::INFINITY ? "초과" : format_currency(t[:max]),
          method: t[:method],
          method_detail: t[:method_detail]
        }
      end
    end

    private

    def format_currency(amount)
      return "무제한" if amount == Float::INFINITY
      amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end

    def invalid_result(message)
      { success: false, error: message }
    end

    def calculate_lowest_bid_rate(type, price, method)
      # 입찰이 아니면 낙찰하한율 없음
      return nil unless method == "입찰"

      # 공사 vs 물품·용역 구분
      category = [ :construction_general, :construction_special, :construction_etc ].include?(type) ? :construction : :goods_service
      rates_info = LOWEST_BID_RATES[category]

      # 금액 구간 찾기
      rate_data = rates_info[:rates].find { |r| price >= r[:min] && price < r[:max] }

      return nil unless rate_data

      {
        category: rates_info[:name],
        rate: rate_data[:rate],
        detail: rate_data[:detail],
        note: "예정가격의 #{rate_data[:rate]} 범위 내에서 최저가 낙찰"
      }
    end

    def generate_warnings(type, price)
      warnings = []

      # 수의계약 체결 제한 확인 경고
      threshold = CONTRACT_THRESHOLDS[type][:thresholds].find { |t| price <= t[:max] }
      if threshold && threshold[:method].include?("수의계약")
        warnings << {
          level: "warning",
          title: "수의계약 체결 제한 여부 확인",
          message: "계약상대자가 수의계약 배제사유에 해당하는지 반드시 확인하세요. 체결제한확인서를 징구하고 나라장터(G2B)에서 부정당업자 제재현황을 조회해야 합니다.",
          link: "https://www.g2b.go.kr"
        }
      end

      # 낙찰하한율 안내 (입찰인 경우)
      if threshold && threshold[:method] == "입찰"
        category = [ :construction_general, :construction_special, :construction_etc ].include?(type) ? :construction : :goods_service
        rates_info = LOWEST_BID_RATES[category]
        rate_data = rates_info[:rates].find { |r| price >= r[:min] && price < r[:max] }

        if rate_data
          warnings << {
            level: "info",
            title: "낙찰하한율 — #{rate_data[:rate]}",
            message: "#{rates_info[:name]} #{rate_data[:detail]} 입찰의 낙찰하한율은 예정가격의 #{rate_data[:rate]}입니다. 이 범위 미만으로 입찰하면 무효 처리됩니다. (지방계약법 시행령 제42조, 시행규칙 별표2)",
            link: nil
          }
        end
      end

      # G2B 전자견적 의무 안내 (2천만원 초과 수의계약)
      if threshold && threshold[:method].include?("수의계약") && price > 20_000_000
        warnings << {
          level: "info",
          title: "G2B 전자견적 필수",
          message: "추정가격 2천만원 초과 수의계약 시 나라장터(G2B) 전자견적을 통해 견적서를 접수해야 합니다. (시행령 제39조)",
          link: "https://www.g2b.go.kr"
        }
      end

      # 중소기업 경쟁제품 확인 경고
      if price > 50_000_000 && [ :goods, :service ].include?(type)
        warnings << {
          level: "warning",
          title: "중소기업 경쟁제품 확인 필요",
          message: "추정가격 5천만원 초과 시 중소기업자간 경쟁제품 해당 여부를 반드시 확인하세요.",
          link: "https://www.smpp.go.kr"
        }
      end

      # 건설업 등록 확인 경고
      if [ :construction_general, :construction_special, :construction_etc ].include?(type) && price > 50_000_000
        warnings << {
          level: "warning",
          title: "건설업 등록 확인 필요",
          message: "경미한 건설공사 범위를 초과하면 해당 건설업 등록업체만 참여 가능합니다. (건설산업기본법 시행령 제8조)",
          link: "https://www.kiscon.net"
        }
      end

      # 전자입찰 안내
      if price > 100_000_000
        warnings << {
          level: "info",
          title: "전자입찰 필수",
          message: "추정가격 1억원 초과 시 나라장터(G2B) 또는 학교장터(S2B) 전자입찰이 필수입니다.",
          link: "https://www.g2b.go.kr"
        }
      end

      # 유찰→수의 전환 안내 (입찰 대상인 경우)
      if threshold && threshold[:method] == "입찰"
        warnings << {
          level: "info",
          title: "유찰 시 수의계약 전환 가능",
          message: "2회 유찰(재공고 포함) 시 수의계약으로 전환할 수 있습니다. 이 경우 최초 입찰에 부친 내용과 동일한 조건이어야 하며, 예정가격 이내로 계약해야 합니다. (지방계약법 시행령 제25조제1항제2호)"
        }
      end

      warnings
    end

    def generate_tips(type, price, method)
      tips = []

      if method.include?("수의계약")
        tips << "수의계약 체결 전 배제사유 확인: 체결제한확인서를 징구하고 G2B에서 부정당업자 제재현황을 조회하세요."
        tips << "견적서 접수 시 유효기간과 인감(직인) 날인 여부를 반드시 확인하세요."
        tips << "수의계약 시에도 2개 이상의 견적을 받아 비교하면 예산 절감 효과가 있습니다."
        tips << "특정 업체와 연속 3회 이상 수의계약 시 청렴성 문제가 제기될 수 있으니 주의하세요."
        if price <= 20_000_000
          tips << "추정가격 2천만원 이하 수의계약은 예정가격 작성을 생략할 수 있습니다. (시행령 제9조)"
        end
        if price > 20_000_000
          tips << "추정가격 2천만원 초과 수의계약은 G2B 전자견적을 통해 견적서를 접수해야 합니다. (시행령 제39조)"
        end
      end

      if method.include?("입찰")
        tips << "입찰공고 기간은 최소 7일 이상 확보해야 합니다. (긴급 시 5일)"
        tips << "낙찰하한율 미만으로 입찰하면 무효 처리되므로, 예정가격 대비 적정 입찰가를 산정하세요."
        tips << "적격심사 또는 최저가낙찰제 적용 여부를 공고문에서 반드시 확인하세요."
        tips << "2회 유찰 시 수의계약 전환이 가능합니다. (지방계약법 시행령 제25조제1항제2호)"
      end

      if [ :goods, :service ].include?(type)
        tips << "조달청 나라장터 종합쇼핑몰에서 동일 품목 가격을 비교해보세요."
      end

      tips << "분할계약(쪼개기) 금지: 동일 목적의 계약을 나누어 수의계약 범위에 맞추는 것은 감사 지적 대상입니다."

      tips
    end
  end
end
