# 원가계산서 검토 가이드 서비스
# 용역 원가계산서 항목별 적정성 검토
class CostCalculationReviewService
  # 용역 유형
  SERVICE_TYPES = {
    general: {
      name: "일반용역",
      icon: "work",
      desc: "일반 업무 용역·위탁",
      profit_rate_max: 0.10,
      profit_basis: "노무비+경비+일반관리비",
      note: "이윤 상한 10%"
    },
    research: {
      name: "학술연구용역",
      icon: "science",
      desc: "학술·정책·조사 연구",
      profit_rate_max: 0.0,
      profit_basis: "해당없음 (기술료 적용)",
      note: "이윤 대신 기술료 적용 (20~40%)",
      tech_fee: true,
      tech_fee_range: { min: 0.20, max: 0.40, basis: "직접인건비+제경비+직접경비" }
    },
    software: {
      name: "SW개발 용역",
      icon: "code",
      desc: "소프트웨어 개발·유지보수",
      profit_rate_max: 0.25,
      profit_basis: "노무비+경비+일반관리비",
      note: "이윤 상한 25% (SW사업 대가기준)"
    },
    design: {
      name: "설계용역",
      icon: "architecture",
      desc: "건축·토목 설계",
      profit_rate_max: 0.10,
      profit_basis: "직접인건비+제경비+직접경비",
      note: "엔지니어링사업 대가기준 적용"
    },
    supervision: {
      name: "감리용역",
      icon: "visibility",
      desc: "건설 감리·시공관리",
      profit_rate_max: 0.10,
      profit_basis: "직접인건비+제경비+직접경비",
      note: "엔지니어링사업 대가기준 적용"
    }
  }.freeze

  # 비용 항목별 적정 비율 범위
  EXPENSE_RATE_RANGES = {
    general: {
      overhead: { name: "제경비(간접노무비+기타경비)", rate_range: [0.10, 0.20], basis: "직접인건비", note: "통상 110~120%" },
      direct_expense: { name: "직접경비", items: ["여비·교통비", "인쇄·복사비", "소모품비", "회의비", "통신·우편료"], note: "실비 산정, 통상 직접인건비의 5~15%" },
      general_admin: { name: "일반관리비", rate_range: [0.05, 0.06], basis: "노무비+경비", note: "5~6% (회계예규)" }
    },
    research: {
      overhead: { name: "제경비", rate_range: [0.86, 1.20], basis: "직접인건비", note: "학술연구 기준 86~120%" },
      direct_expense: { name: "직접경비", items: ["여비", "유인물비", "전산처리비", "시약·재료비", "회의비", "임차료"], note: "실비 산정" },
      general_admin: { name: "일반관리비", rate_range: [0.05, 0.06], basis: "노무비+경비", note: "해당 시 5~6%" }
    },
    software: {
      overhead: { name: "제경비(직접경비)", rate_range: [0.10, 0.20], basis: "직접인건비", note: "SW 대가기준" },
      direct_expense: { name: "직접경비", items: ["장비사용료", "라이선스", "통신비", "여비"], note: "실비 산정" },
      general_admin: { name: "일반관리비", rate_range: [0.05, 0.06], basis: "노무비+경비", note: "5~6%" }
    },
    design: {
      overhead: { name: "제경비", rate_range: [1.10, 1.20], basis: "직접인건비", note: "엔지니어링 기준 110~120%" },
      direct_expense: { name: "직접경비", items: ["여비", "인쇄비", "관급자재시험비", "측량비", "모형제작비"], note: "실비 산정" },
      general_admin: { name: "일반관리비", rate_range: [0.05, 0.06], basis: "노무비+경비", note: "해당 시 5~6%" }
    },
    supervision: {
      overhead: { name: "제경비", rate_range: [1.10, 1.20], basis: "직접인건비", note: "엔지니어링 기준 110~120%" },
      direct_expense: { name: "직접경비", items: ["여비", "차량유지비", "사무용품", "시험검사비"], note: "실비 산정" },
      general_admin: { name: "일반관리비", rate_range: [0.05, 0.06], basis: "노무비+경비", note: "해당 시 5~6%" }
    }
  }.freeze

  # 검토 결과 상태
  STATUS = {
    ok: { label: "적정", color: "green", icon: "check_circle" },
    warning: { label: "주의", color: "amber", icon: "warning" },
    error: { label: "부적정", color: "red", icon: "error" }
  }.freeze

  class << self
    def get_service_types
      SERVICE_TYPES.map { |key, val| { id: key.to_s, name: val[:name], icon: val[:icon], desc: val[:desc] } }
    end

    def review(params)
      type = params[:service_type].to_s.to_sym
      return { success: false, error: "유효하지 않은 용역유형입니다." } unless SERVICE_TYPES.key?(type)

      type_info = SERVICE_TYPES[type]
      expense_ranges = EXPENSE_RATE_RANGES[type]

      direct_labor = params[:direct_labor].to_i
      overhead = params[:overhead].to_i
      direct_expense = params[:direct_expense].to_i
      general_admin = params[:general_admin].to_i
      profit_or_tech = params[:profit_or_tech].to_i
      vat = params[:vat].to_i

      total = direct_labor + overhead + direct_expense + general_admin + profit_or_tech + vat

      reviews = []

      # 1. 직접인건비 검토 (기본 확인)
      if direct_labor <= 0
        reviews << { name: "직접인건비", status: "error", detail: "직접인건비가 0원입니다. 노임단가 × 투입M/M으로 산출해야 합니다.", amount: direct_labor }
      else
        reviews << { name: "직접인건비", status: "ok", detail: "노임단가 × 투입인월(M/M) 기준으로 산출. 한국엔지니어링협회 또는 SW기술자 노임단가 적용 여부 확인 필요.", amount: direct_labor }
      end

      # 2. 제경비 검토
      if direct_labor > 0
        overhead_rate = overhead.to_f / direct_labor
        range = expense_ranges[:overhead][:rate_range]
        if overhead_rate < range[0] * 0.5
          reviews << { name: expense_ranges[:overhead][:name], status: "warning", detail: "제경비율 #{(overhead_rate * 100).round(1)}%로 기준(#{(range[0]*100).round(0)}~#{(range[1]*100).round(0)}%) 대비 매우 낮습니다. 과소 산정 여부 확인.", amount: overhead, rate: "#{(overhead_rate * 100).round(1)}%" }
        elsif overhead_rate > range[1] * 1.3
          reviews << { name: expense_ranges[:overhead][:name], status: "error", detail: "제경비율 #{(overhead_rate * 100).round(1)}%로 기준(#{(range[0]*100).round(0)}~#{(range[1]*100).round(0)}%) 대비 과다합니다. 감액 검토 필요.", amount: overhead, rate: "#{(overhead_rate * 100).round(1)}%" }
        elsif overhead_rate > range[1]
          reviews << { name: expense_ranges[:overhead][:name], status: "warning", detail: "제경비율 #{(overhead_rate * 100).round(1)}%로 기준 상한(#{(range[1]*100).round(0)}%)을 소폭 초과. 사유 확인 필요.", amount: overhead, rate: "#{(overhead_rate * 100).round(1)}%" }
        else
          reviews << { name: expense_ranges[:overhead][:name], status: "ok", detail: "제경비율 #{(overhead_rate * 100).round(1)}%로 기준 범위 이내 (#{(range[0]*100).round(0)}~#{(range[1]*100).round(0)}%).", amount: overhead, rate: "#{(overhead_rate * 100).round(1)}%" }
        end
      end

      # 3. 직접경비 검토
      if direct_labor > 0 && direct_expense > 0
        de_rate = direct_expense.to_f / direct_labor
        if de_rate > 0.30
          reviews << { name: "직접경비", status: "warning", detail: "직접경비가 직접인건비의 #{(de_rate * 100).round(1)}%로 높은 편입니다. 항목별 실비 산정 근거 확인 필요.", amount: direct_expense, rate: "#{(de_rate * 100).round(1)}%" }
        else
          reviews << { name: "직접경비", status: "ok", detail: "직접경비 #{(de_rate * 100).round(1)}% (직접인건비 대비). 항목별 실비 산정이 적정한지 확인.", amount: direct_expense, rate: "#{(de_rate * 100).round(1)}%" }
        end
      elsif direct_expense == 0
        reviews << { name: "직접경비", status: "ok", detail: "직접경비 미계상. 여비·인쇄비 등 필요 경비가 누락되지 않았는지 확인.", amount: 0 }
      end

      # 4. 일반관리비 검토
      labor_and_expense = direct_labor + overhead + direct_expense
      if labor_and_expense > 0 && general_admin > 0
        ga_rate = general_admin.to_f / labor_and_expense
        range = expense_ranges[:general_admin][:rate_range]
        if ga_rate > range[1]
          reviews << { name: "일반관리비", status: "error", detail: "일반관리비율 #{(ga_rate * 100).round(1)}%로 상한(#{(range[1]*100).round(0)}%)을 초과합니다.", amount: general_admin, rate: "#{(ga_rate * 100).round(1)}%" }
        else
          reviews << { name: "일반관리비", status: "ok", detail: "일반관리비율 #{(ga_rate * 100).round(1)}%로 기준 이내 (상한 #{(range[1]*100).round(0)}%).", amount: general_admin, rate: "#{(ga_rate * 100).round(1)}%" }
        end
      end

      # 5. 이윤/기술료 검토
      if type_info[:tech_fee]
        # 학술연구: 기술료 검토
        tech_basis = direct_labor + overhead + direct_expense
        if tech_basis > 0 && profit_or_tech > 0
          tech_rate = profit_or_tech.to_f / tech_basis
          range = type_info[:tech_fee_range]
          if tech_rate > range[:max]
            reviews << { name: "기술료", status: "error", detail: "기술료율 #{(tech_rate * 100).round(1)}%로 상한(#{(range[:max]*100).round(0)}%)을 초과합니다.", amount: profit_or_tech, rate: "#{(tech_rate * 100).round(1)}%" }
          elsif tech_rate < range[:min]
            reviews << { name: "기술료", status: "warning", detail: "기술료율 #{(tech_rate * 100).round(1)}%로 하한(#{(range[:min]*100).round(0)}%) 미만입니다.", amount: profit_or_tech, rate: "#{(tech_rate * 100).round(1)}%" }
          else
            reviews << { name: "기술료", status: "ok", detail: "기술료율 #{(tech_rate * 100).round(1)}%로 적정 범위 이내 (#{(range[:min]*100).round(0)}~#{(range[:max]*100).round(0)}%).", amount: profit_or_tech, rate: "#{(tech_rate * 100).round(1)}%" }
          end
        end
      else
        # 이윤 검토
        profit_basis = direct_labor + overhead + general_admin
        if profit_basis > 0 && profit_or_tech > 0
          profit_rate = profit_or_tech.to_f / profit_basis
          max_rate = type_info[:profit_rate_max]
          if profit_rate > max_rate
            reviews << { name: "이윤", status: "error", detail: "이윤율 #{(profit_rate * 100).round(1)}%로 상한(#{(max_rate*100).round(0)}%)을 초과합니다.", amount: profit_or_tech, rate: "#{(profit_rate * 100).round(1)}%" }
          else
            reviews << { name: "이윤", status: "ok", detail: "이윤율 #{(profit_rate * 100).round(1)}%로 상한(#{(max_rate*100).round(0)}%) 이내.", amount: profit_or_tech, rate: "#{(profit_rate * 100).round(1)}%" }
          end
        end
      end

      # 6. 부가세 검토
      subtotal = total - vat
      expected_vat = (subtotal * 0.1).round(0)
      if vat > 0 && (vat - expected_vat).abs > 100
        reviews << { name: "부가가치세", status: "warning", detail: "부가세 #{vat}원이 공급가액의 10%(#{expected_vat}원)과 차이가 있습니다.", amount: vat }
      elsif vat > 0
        reviews << { name: "부가가치세", status: "ok", detail: "부가세 10% 적정.", amount: vat }
      end

      {
        success: true,
        result: {
          type_name: type_info[:name],
          type_note: type_info[:note],
          is_tech_fee: type_info[:tech_fee] || false,
          reviews: reviews,
          total: total,
          expense_items: expense_ranges[:direct_expense][:items],
          summary: build_summary(reviews)
        }
      }
    end

    private

    def build_summary(reviews)
      errors = reviews.count { |r| r[:status] == "error" }
      warnings = reviews.count { |r| r[:status] == "warning" }
      if errors > 0
        { status: "error", message: "#{errors}개 항목이 기준을 초과합니다. 수정 후 재검토가 필요합니다." }
      elsif warnings > 0
        { status: "warning", message: "#{warnings}개 항목에 주의가 필요합니다. 세부 내용을 확인하세요." }
      else
        { status: "ok", message: "전체 항목이 적정 범위 이내입니다." }
      end
    end
  end
end
