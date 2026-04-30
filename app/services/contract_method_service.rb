# 계약방식 결정 서비스
# 추정가격과 계약유형에 따라 적정 계약방식을 판단하고 관련 정보를 제공

class ContractMethodService
  # YAML 데이터 로드 (앱 시작 시 1회)
  CONFIG = YAML.load_file(
    Rails.root.join("config", "contract_thresholds.yml"),
    permitted_classes: [ Symbol ],
    symbolize_names: false
  ).freeze

  # 계약방식 기준 (지방계약법 시행령 기준)
  CONTRACT_THRESHOLDS = CONFIG["contract_thresholds"].transform_keys(&:to_sym).transform_values do |v|
    v.merge(
      "thresholds" => v["thresholds"].map { |t| t.transform_keys(&:to_sym) }
    ).transform_keys(&:to_sym)
  end.freeze

  # 특례 조건 (여성기업, 장애인기업, 사회적기업 등)
  SPECIAL_ENTERPRISES = CONFIG["special_enterprises"].transform_keys(&:to_sym).transform_values do |v|
    v.transform_keys(&:to_sym)
  end.freeze

  # 낙찰하한율 기준 (지방계약법 시행령 제42조, 지방계약법 시행규칙 별표2)
  LOWEST_BID_RATES = CONFIG["lowest_bid_rates"].transform_keys(&:to_sym).transform_values do |v|
    v.merge(
      "rates" => v["rates"].map { |r| r.transform_keys(&:to_sym) }
    ).transform_keys(&:to_sym)
  end.freeze

  # 관련 법령 정보
  RELATED_LAWS = CONFIG["related_laws"].freeze

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
          message: "추정가격 2천만원 초과 수의계약 시 나라장터(G2B) 전자견적을 통해 견적서를 접수해야 합니다. (지방계약법 시행령 제30조 — 지정정보처리장치 이용 견적서 제출, 행정안전부 예규)",
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
          tips << "추정가격 2천만원 초과 수의계약은 G2B 전자견적을 통해 견적서를 접수해야 합니다. (지방계약법 시행령 제30조)"
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
