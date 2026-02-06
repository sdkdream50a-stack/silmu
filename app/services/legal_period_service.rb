# 법정기간 계산기 서비스
# 계약 관련 법정 기간을 계산
class LegalPeriodService
  # 기간 유형
  PERIOD_TYPES = {
    announcement: {
      name: "입찰공고기간",
      icon: "campaign",
      desc: "추정가격별 최소 공고일수"
    },
    contract_signing: {
      name: "계약체결기간",
      icon: "draw",
      desc: "낙찰 후 계약체결 기한"
    },
    payment: {
      name: "대금지급기간",
      icon: "payments",
      desc: "검사 후 대금 지급기한"
    },
    defect_warranty: {
      name: "하자보증기간",
      icon: "shield",
      desc: "공종별 하자보증 기간"
    },
    late_penalty: {
      name: "지체상금",
      icon: "hourglass_bottom",
      desc: "지체일수 및 상금 계산"
    }
  }.freeze

  # 입찰공고기간 (일)
  ANNOUNCEMENT_PERIODS = [
    { label: "10억 미만", min: 0, max: 1_000_000_000, days: 7 },
    { label: "10억 ~ 50억 미만", min: 1_000_000_000, max: 5_000_000_000, days: 15 },
    { label: "50억 이상", min: 5_000_000_000, max: Float::INFINITY, days: 40 }
  ].freeze

  ANNOUNCEMENT_URGENT_DAYS = 5

  # 계약체결 기한 (영업일)
  CONTRACT_SIGNING_DEADLINE = 10

  # 대금지급 기한 (일)
  PAYMENT_DEADLINES = {
    national: { name: "국가기관", days: 5, note: "검사완료 후 5일 이내 (국가계약법 시행령 제58조)" },
    local: { name: "지방자치단체", days: 14, note: "검사완료 후 14일 이내 (지방계약법 시행령 제69조)" },
    advance: { name: "선금 지급", days: 14, note: "청구일로부터 14일 이내" },
    subcontract: { name: "하도급 대금", days: 15, note: "원수급인 대금 수령 후 15일 이내 (하도급법 제13조)" }
  }.freeze

  # 하자보증기간 (년)
  DEFECT_WARRANTY_PERIODS = [
    { id: "structure", name: "구조체 공사", years: 5, note: "철근콘크리트·철골 구조" },
    { id: "roof_waterproof", name: "지붕·방수공사", years: 3, note: "지붕공사, 방수공사" },
    { id: "painting", name: "도장공사", years: 1, note: "내·외부 도장" },
    { id: "plaster", name: "미장·타일공사", years: 1, note: "미장, 타일, 돌붙임" },
    { id: "metal_window", name: "창호공사", years: 2, note: "금속·목재 창호" },
    { id: "electrical", name: "전기·설비공사", years: 2, note: "전기, 기계설비, 소방" },
    { id: "landscaping", name: "조경공사", years: 2, note: "조경식재, 시설물" },
    { id: "road", name: "도로·포장공사", years: 3, note: "아스팔트·콘크리트 포장" },
    { id: "civil", name: "토목공사", years: 3, note: "토공, 배수, 옹벽 등" },
    { id: "interior", name: "실내건축공사", years: 2, note: "바닥재, 벽체, 천장" }
  ].freeze

  # 지체상금 요율 (1일당)
  LATE_PENALTY_RATES = {
    construction: { name: "공사", rate: Rational(1, 2000), display: "1/2,000" },
    goods: { name: "물품", rate: Rational(3, 4000), display: "3/4,000" },
    service: { name: "용역", rate: Rational(3, 4000), display: "3/4,000" },
    lease: { name: "임대차", rate: Rational(1, 1000), display: "1/1,000" }
  }.freeze

  WEEKDAY_NAMES = %w[일요일 월요일 화요일 수요일 목요일 금요일 토요일].freeze

  class << self
    def get_period_types
      PERIOD_TYPES.map { |key, val| { id: key.to_s, name: val[:name], icon: val[:icon], desc: val[:desc] } }
    end

    def calculate(params)
      type = params[:period_type].to_s.to_sym
      return { success: false, error: "유효하지 않은 기간유형입니다." } unless PERIOD_TYPES.key?(type)

      case type
      when :announcement then calc_announcement(params)
      when :contract_signing then calc_contract_signing(params)
      when :payment then calc_payment(params)
      when :defect_warranty then calc_defect_warranty(params)
      when :late_penalty then calc_late_penalty(params)
      end
    end

    private

    def calc_announcement(params)
      amount = params[:estimated_amount].to_i
      start_date = parse_date(params[:announcement_date])
      urgent = params[:urgent] == "true" || params[:urgent] == true
      return { success: false, error: "공고일을 입력해주세요." } unless start_date

      if urgent
        days = ANNOUNCEMENT_URGENT_DAYS
        period_label = "긴급입찰 (5일)"
      else
        period = ANNOUNCEMENT_PERIODS.find { |p| amount >= p[:min] && amount < p[:max] }
        days = period ? period[:days] : 7
        period_label = period ? "#{period[:label]} (#{period[:days]}일)" : "7일"
      end

      end_date = start_date + days
      end_date = adjust_weekend(end_date)

      {
        success: true,
        result: {
          type: "announcement",
          period_label: period_label,
          days: days,
          start_date: format_date(start_date),
          start_weekday: weekday_name(start_date),
          end_date: format_date(end_date),
          end_weekday: weekday_name(end_date),
          urgent: urgent,
          note: urgent ? "긴급입찰: 천재지변·비상재해 등 긴급한 경우 (국가계약법 시행령 제33조)" : "일반입찰 공고기간 (국가계약법 시행령 제33조)"
        }
      }
    end

    def calc_contract_signing(params)
      notification_date = parse_date(params[:notification_date])
      return { success: false, error: "낙찰통지일을 입력해주세요." } unless notification_date

      deadline = notification_date + CONTRACT_SIGNING_DEADLINE
      deadline = adjust_weekend(deadline)

      {
        success: true,
        result: {
          type: "contract_signing",
          notification_date: format_date(notification_date),
          notification_weekday: weekday_name(notification_date),
          deadline: format_date(deadline),
          deadline_weekday: weekday_name(deadline),
          days: CONTRACT_SIGNING_DEADLINE,
          note: "낙찰통지를 받은 날부터 10일 이내 (국가계약법 시행령 제49조)"
        }
      }
    end

    def calc_payment(params)
      payment_type = params[:payment_type].to_s.to_sym
      inspection_date = parse_date(params[:inspection_date])
      return { success: false, error: "검사완료일을 입력해주세요." } unless inspection_date
      return { success: false, error: "유효하지 않은 지급유형입니다." } unless PAYMENT_DEADLINES.key?(payment_type)

      info = PAYMENT_DEADLINES[payment_type]
      deadline = inspection_date + info[:days]
      deadline = adjust_weekend(deadline)

      {
        success: true,
        result: {
          type: "payment",
          payment_type_name: info[:name],
          inspection_date: format_date(inspection_date),
          inspection_weekday: weekday_name(inspection_date),
          deadline: format_date(deadline),
          deadline_weekday: weekday_name(deadline),
          days: info[:days],
          note: info[:note]
        }
      }
    end

    def calc_defect_warranty(params)
      completion_date = parse_date(params[:completion_date])
      selected_ids = params[:work_types] || []
      return { success: false, error: "준공일을 입력해주세요." } unless completion_date
      return { success: false, error: "공종을 선택해주세요." } if selected_ids.empty?

      results = selected_ids.map do |id|
        period = DEFECT_WARRANTY_PERIODS.find { |p| p[:id] == id.to_s }
        next unless period
        end_date = completion_date >> (period[:years] * 12)
        {
          name: period[:name],
          years: period[:years],
          end_date: format_date(end_date),
          end_weekday: weekday_name(end_date),
          note: period[:note]
        }
      end.compact

      {
        success: true,
        result: {
          type: "defect_warranty",
          completion_date: format_date(completion_date),
          completion_weekday: weekday_name(completion_date),
          warranties: results,
          note: "하자담보책임기간 (국가계약법 시행령 제70조, 지방계약법 시행령 제78조)"
        }
      }
    end

    def calc_late_penalty(params)
      penalty_type = params[:penalty_type].to_s.to_sym
      contract_amount = params[:contract_amount].to_i
      due_date = parse_date(params[:due_date])
      actual_date = parse_date(params[:actual_date])

      return { success: false, error: "계약종료일을 입력해주세요." } unless due_date
      return { success: false, error: "실제완료일을 입력해주세요." } unless actual_date
      return { success: false, error: "유효하지 않은 계약유형입니다." } unless LATE_PENALTY_RATES.key?(penalty_type)

      if actual_date <= due_date
        return {
          success: true,
          result: {
            type: "late_penalty",
            delay_days: 0,
            penalty_amount: 0,
            message: "지체 없음 — 기한 내 완료",
            note: "계약기간 내 이행완료"
          }
        }
      end

      delay_days = (actual_date - due_date).to_i
      rate_info = LATE_PENALTY_RATES[penalty_type]
      penalty_amount = (contract_amount * rate_info[:rate] * delay_days).to_i

      # 지체상금은 계약금액을 초과할 수 없음
      capped = penalty_amount > contract_amount
      penalty_amount = [penalty_amount, contract_amount].min

      {
        success: true,
        result: {
          type: "late_penalty",
          penalty_type_name: rate_info[:name],
          rate_display: rate_info[:display],
          contract_amount: contract_amount,
          due_date: format_date(due_date),
          due_weekday: weekday_name(due_date),
          actual_date: format_date(actual_date),
          actual_weekday: weekday_name(actual_date),
          delay_days: delay_days,
          penalty_amount: penalty_amount,
          capped: capped,
          note: "지체상금 (국가계약법 시행령 제74조, 지방계약법 시행령 제80조)"
        }
      }
    end

    def parse_date(str)
      return nil if str.blank?
      Date.parse(str.to_s)
    rescue ArgumentError
      nil
    end

    def format_date(date)
      date.strftime("%Y-%m-%d")
    end

    def weekday_name(date)
      WEEKDAY_NAMES[date.wday]
    end

    def adjust_weekend(date)
      case date.wday
      when 6 then date + 2  # 토 → 월
      when 0 then date + 1  # 일 → 월
      else date
      end
    end
  end
end
