class ToolsController < ApplicationController
  include SeoHelper
  include ToolsMeta

  # 모든 도구 페이지는 JS 기반 계산기 (서버 측 동적 데이터 없음)
  before_action -> { expires_in 1.hour, public: true, stale_while_revalidate: 1.day }
  # 업무달력은 today를 서버 렌더링하므로 캐시 금지 (자정 이후 날짜 오차 방지)
  before_action -> { response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate" }, only: :task_calendar

  def index
    description_text = "계약방식 결정·예정가격 계산·계약보증금·여비계산·법정기간 산출 등 공무원 업무를 자동화하는 #{ApplicationHelper::ACTIVE_TOOL_COUNT}개 실무 도구. 법령 기준으로 복잡한 계산을 원클릭으로 해결합니다. 수의계약 분할 판단·물가변동 조정·적격심사 채점까지 업무 시간을 대폭 단축하세요."

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
  def price_adjustment_calculator = render_tool_page(:price_adjustment_calculator)
  def budget_execution_rate = render_tool_page(:budget_execution_rate)
  def contingency_fund = render_tool_page(:contingency_fund)
  def overtime_calculator = render_tool_page(:overtime_calculator)
  def annual_leave_calculator = render_tool_page(:annual_leave_calculator)
  def severance_calculator = render_tool_page(:severance_calculator)
  def performance_bonus_calculator = render_tool_page(:performance_bonus_calculator)
  def travel_calculator = render_tool_page(:travel_calculator)

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
    binary = HwpxExportService.generate_annual_leave(
      params.permit(
        :hire_date, :ref_year, :service_period,
        :granted_leave, :used_leave, :remaining_leave,
        :annual_allowance_pay, :annual_allowance_detail,
        :compensation_pay, :compensation_detail
      )
    )

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
end
