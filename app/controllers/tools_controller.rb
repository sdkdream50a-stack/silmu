class ToolsController < ApplicationController
  include SeoHelper
  include ToolsMeta

  # 모든 도구 페이지는 JS 기반 계산기 (서버 측 동적 데이터 없음)
  before_action -> { expires_in 1.hour, public: true, stale_while_revalidate: 1.day }
  # 업무달력은 today를 서버 렌더링하므로 캐시 금지 (자정 이후 날짜 오차 방지)
  before_action -> { response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate" }, only: :task_calendar

  def index
    description_text = "계약방식 결정·예정가격 계산·계약보증금·여비계산·법정기간 산출 등 공무원 업무를 자동화하는 #{ApplicationHelper::ACTIVE_TOOL_COUNT}개 실무 도구. 법령 기준으로 복잡한 계산을 원클릭으로 해결합니다. 수의계약 분할 판단·물가변동 조정까지 업무 시간을 대폭 단축하세요."

    set_og_image(category: "tools")
    set_meta_tags(
      title: "실무 도구 — 계약·예산 자동화 계산기 모음",
      description: description_text,
      keywords: "계약방식, 예정가격 계산기, 계약보증금, 여비계산기, 법정기간, PDF 도구",
      og: {
        title: "실무 도구 — 실무.kr",
        description: description_text,
        url: canonical_url,
        type: "website"
      },
      json_ld: {
        "@context" => "https://schema.org",
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          { "@type" => "ListItem", "position" => 1, "name" => "홈", "item" => root_url },
          { "@type" => "ListItem", "position" => 2, "name" => "실무 도구", "item" => tools_url }
        ]
      }
    )
  end

  def task_calendar = render_tool_page(:task_calendar)
  def salary_calculator = render_tool_page(:salary_calculator)
  def pension_calculator = render_tool_page(:pension_calculator)
  def subsidy_settlement_checker = render_tool_page(:subsidy_settlement_checker)
  def budget_category_finder = render_tool_page(:budget_category_finder)
  def contract_legality_check = render_tool_page(:contract_legality_check)
  def budget_transfer_checker = render_tool_page(:budget_transfer_checker)
  def allowance_calculator = render_tool_page(:allowance_calculator)
  def audit_readiness_checker = render_tool_page(:audit_readiness_checker)
  def split_contract_checker = render_tool_page(:split_contract_checker)

  # POST /tools/split-contract-checker/evaluate
  # 판정을 서버에서 한다. 조문 요건을 클라이언트 JS 에 두면 테스트도 뮤테이션도
  # 걸 수 없고, 실제로 근거 없는 임계값("체크 3개 이상 = 위험 높음")이 그렇게 들어와 있었다.
  def split_contract_evaluate
    result = ContractDecision::SplitProcurementEvaluator.call(
      contract_type: params[:contract_type],
      factors: params[:factors]&.permit!&.to_h || {},
      separation_ground: params[:separation_ground],
      current_amount: params[:current_amount],
      prior_amounts: Array(params[:prior_amounts])
    )
    render json: { success: true }.merge(result.to_h)
  end
  def price_adjustment_calculator = render_tool_page(:price_adjustment_calculator)
  def predetermined_price = render_tool_page(:predetermined_price)
  def budget_execution_rate = render_tool_page(:budget_execution_rate)
  def contingency_fund = render_tool_page(:contingency_fund)
  def overtime_calculator = render_tool_page(:overtime_calculator)
  def annual_leave_calculator = render_tool_page(:annual_leave_calculator)
  def severance_calculator = render_tool_page(:severance_calculator)
  def performance_bonus_calculator = render_tool_page(:performance_bonus_calculator)
  def travel_calculator = render_tool_page(:travel_calculator)

  # P3 Sprint 1: 공공기관 표준어 검사기 PoC (행정안전부 공통표준용어 13,176건 기반)
  def standard_term_checker
    @input_text = params[:text].to_s
    @result = StandardTermCorrector.call(@input_text) if @input_text.present?
    render_tool_page(:standard_term_checker)
  end

  # POST /tools/annual-leave/pdf
  def annual_leave_pdf
    pdf_data = PdfExportService.annual_leave_pdf(
      hire_date:    params[:hire_date],
      ref_year:     params[:ref_year],
      used_leave:   params[:used_leave],
      monthly_wage: params[:monthly_wage],
      daily_wage:   params[:daily_wage]
    )

    if pdf_data
      send_data pdf_data,
        filename: "연가일수_계산결과_#{Time.zone.today.strftime('%Y%m%d')}.pdf",
        type: "application/pdf",
        disposition: "attachment"
    else
      render json: { success: false, error: "임용일 형식이 올바르지 않습니다." }, status: :unprocessable_entity
    end
  end

  def annual_leave_hwpx
    # 클라이언트가 보낸 granted_leave·remaining_leave를 그대로 문서화하면 위조된 결과가
    # 그대로 공문서 서식으로 나간다. 입력값(임용일·기준연도·사용연가·임금)만 받아 서버에서 재계산한다.
    data = PdfExportService.annual_leave_data(
      hire_date:    params[:hire_date],
      ref_year:     params[:ref_year],
      used_leave:   params[:used_leave],
      monthly_wage: params[:monthly_wage],
      daily_wage:   params[:daily_wage]
    )

    unless data
      return render json: { success: false, error: "임용일 형식이 올바르지 않습니다." }, status: :unprocessable_entity
    end

    binary = HwpxExportService.generate_annual_leave(annual_leave_hwpx_fields(data))

    if binary
      send_data binary,
                filename: "연가일수_계산결과_#{Time.zone.today.strftime('%Y%m%d')}.hwpx",
                type: "application/octet-stream",
                disposition: "attachment"
    else
      render json: { success: false, error: "HWPX 파일 생성에 실패했습니다." }, status: :unprocessable_entity
    end
  end

  def task_calendar_ics
    send_data GovernmentCalendarIcsService.generate,
      filename: "silmu-kr-업무달력.ics",
      type: "text/calendar; charset=utf-8",
      disposition: "attachment"
  end

  private

  # 서버 재계산 결과(PdfExportService.annual_leave_data)를 HWPX 서식 필드로 변환한다.
  def annual_leave_hwpx_fields(data)
    period = [ ("#{data[:years]}년" if data[:years] > 0), ("#{data[:months]}개월" if data[:months] > 0) ]
              .compact.join(" ").presence || "1개월 미만"
    oa   = data[:ordinary_allowance]
    comp = data[:compensation]

    {
      hire_date:               data[:hire_date].strftime("%Y-%m-%d"),
      ref_year:                data[:ref_year].to_s,
      service_period:          period,
      granted_leave:           "#{data[:granted]}일",
      used_leave:              "#{data[:used_leave].to_f.round(1)}일",
      remaining_leave:         "#{data[:remaining]}일",
      annual_allowance_pay:    oa ? "#{helpers.number_with_delimiter(oa[:total])}원" : "",
      annual_allowance_detail: oa ? "1일 통상임금 #{helpers.number_with_delimiter(oa[:daily_ordinary])}원 × #{oa[:days]}일" : "",
      compensation_pay:        comp ? "#{helpers.number_with_delimiter(comp[:total])}원" : "",
      compensation_detail:     comp ? "1일 봉급액 기준 × #{comp[:days]}일(최대 20일)" : ""
    }
  end
end
