class ToolsController < ApplicationController
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
      }
    )
  end

  def task_calendar
    description_text = "월별 반복 업무를 한눈에 확인하는 업무 할일 맵. 급여, 세무, 회계, 보고 등 주요 업무 일정을 놓치지 마세요. 달력에 일정을 추가하고, CSV/ICS 파일로 내보내기하여 Google Calendar, Outlook과 연동할 수 있습니다."

    set_meta_tags(
      title: "업무 할일 달력 — 공무원 월별 반복업무 일정 관리",
      description: description_text,
      keywords: "업무달력, 할일목록, 급여일정, 세무신고, 보험료납부, 월별업무",
      og: {
        title: "업무 할일 달력 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def subsidy_settlement_checker
    set_meta_tags(
      title: "보조금 정산 체크리스트 — e나라도움 정산 전 자가점검",
      description: "국고·지방보조금 정산 전 반드시 확인해야 할 항목을 자동으로 점검합니다. 보조금 유형별 필수 증빙서류, 집행 적정성, 잔액 처리 방법까지 감사 빈출 지적 기준으로 즉시 확인하세요.",
      keywords: "보조금 정산,보조금 체크리스트,e나라도움,국고보조금,지방보조금,보조금 정산 서류,보조금 감사",
      og: {
        title: "보조금 정산 체크리스트 — 실무.kr",
        description: "보조금 정산 전 자가점검 도구. 감사 빈출 지적 기준으로 즉시 확인하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "보조금 정산 체크리스트",
        description: "국고·지방보조금 정산 전 자가점검 도구. 감사 빈출 지적 기준으로 즉시 확인하세요.",
        url: subsidy_settlement_checker_url
      )
    )
  end

  def budget_category_finder
    set_meta_tags(
      title: "예산 과목 분류 도우미 — 세출예산 목·세목 자동 추천",
      description: "지출 내용을 입력하면 적합한 세출예산 과목(목·세목)을 자동으로 추천합니다. 예산회계 담당자가 가장 많이 틀리는 과목 분류를 즉시 확인하세요. 지방자치단체 예산편성 운영기준 기반.",
      keywords: "예산 과목,세출예산 과목,예산 목 세목,예산 분류,세출예산 편성,예산 담당자",
      og: {
        title: "예산 과목 분류 도우미 — 실무.kr",
        description: "지출 내용 입력 → 적합한 세출예산 과목(목·세목) 즉시 추천",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "예산 과목 분류 도우미",
        description: "지출 내용을 입력하면 적합한 세출예산 과목(목·세목)을 자동으로 추천하는 무료 도구",
        url: budget_category_finder_url
      )
    )
  end

  def contract_legality_check
    set_meta_tags(
      title: "계약 적법성 자가진단 — 단계별 감사 지적 사전 예방",
      description: "계약 단계별(입찰공고→낙찰→계약체결→이행→준공) 감사원 빈출 지적사항을 체크리스트로 즉시 점검합니다. 계약담당자 필수 자가진단 도구.",
      keywords: "계약 적법성,계약 감사,계약 체크리스트,감사 지적,계약 자가진단,공공계약 감사",
      og: {
        title: "계약 적법성 자가진단 — 실무.kr",
        description: "계약 단계별 감사 빈출 지적사항을 체크리스트로 즉시 점검하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "계약 적법성 자가진단",
        description: "계약 단계별 감사원 빈출 지적사항을 체크리스트로 즉시 점검하는 무료 도구",
        url: contract_legality_check_url
      )
    )
  end

  def budget_transfer_checker
    set_meta_tags(
      title: "이월·전용 적법성 판단기 — 예산 이월·전용 요건 즉시 확인",
      description: "명시이월·사고이월·계속비이월의 요건과 절차를 즉시 확인합니다. 예산전용 가능 여부와 사전 승인 필요 여부를 법령 기준으로 자동 판단하세요. 지방재정법 기반.",
      keywords: "예산 이월,명시이월,사고이월,계속비이월,예산 전용,이월 요건,예산 담당자",
      og: {
        title: "이월·전용 적법성 판단기 — 실무.kr",
        description: "예산 이월·전용 요건과 절차를 법령 기준으로 즉시 확인하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "이월·전용 적법성 판단기",
        description: "예산 이월·전용 요건과 절차를 법령 기준으로 자동 판단하는 무료 도구",
        url: budget_transfer_checker_url
      )
    )
  end

  def allowance_calculator
    set_meta_tags(
      title: "공무원 수당 계산기 — 정근수당·가족수당·명절휴가비 자동 계산",
      description: "정근수당(가산금 포함), 가족수당, 명절휴가비, 직급보조비를 공무원수당 등에 관한 규정 기준으로 자동 계산합니다. 급수·호봉·재직기간·가족 수를 입력하면 즉시 산출됩니다.",
      keywords: "공무원 수당 계산기,정근수당,가족수당,명절휴가비,직급보조비,공무원수당규정,수당 계산",
      og: {
        title: "공무원 수당 계산기 — 실무.kr",
        description: "정근수당·가족수당·명절휴가비를 공무원수당 규정 기준으로 자동 계산합니다.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "공무원 수당 계산기",
        description: "정근수당·가족수당·명절휴가비·직급보조비를 공무원수당 규정 기준으로 자동 계산하는 무료 도구",
        url: allowance_calculator_url
      )
    )
  end

  def audit_readiness_checker
    set_meta_tags(
      title: "부서별 감사 대비 체크리스트 — 계약·예산·인사·보조금 자가점검",
      description: "담당 업무 유형(계약·예산·인사·보조금)을 선택하면 감사 빈출 지적사항 기반 자가점검 체크리스트를 즉시 생성합니다. 감사 전 5분 만에 완성하는 자가진단 도구.",
      keywords: "감사 대비,감사 체크리스트,계약 감사,예산 감사,인사 감사,보조금 감사,자가점검",
      og: {
        title: "부서별 감사 대비 체크리스트 — 실무.kr",
        description: "담당 업무 유형별 감사 빈출 지적 기반 자가점검 체크리스트를 즉시 생성하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "부서별 감사 대비 체크리스트",
        description: "담당 업무 유형별 감사 빈출 지적 기반 자가점검 체크리스트를 즉시 생성하는 무료 도구",
        url: audit_readiness_checker_url
      )
    )
  end

  def split_contract_checker
    set_meta_tags(
      title: "분할계약 판단 체크리스트 — 수의계약 위험도 즉시 확인",
      description: "계약 분할이 감사 지적 대상인지 5가지 기준으로 즉시 확인하세요. 추정가격 합산과 분할계약 판단 기준을 자동으로 검토합니다.",
      keywords: "분할계약,분할계약 판단,수의계약 기준,분할계약 금지,추정가격 합산,감사 지적",
      og: {
        title: "분할계약 판단 체크리스트 — 실무.kr",
        description: "계약 분할이 감사 지적 대상인지 즉시 확인하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "분할계약 판단 체크리스트",
        description: "계약 분할이 감사 지적 대상인지 5가지 기준으로 즉시 확인하는 무료 도구",
        url: split_contract_checker_url
      )
    )
  end

  def price_adjustment_calculator
    set_meta_tags(
      title: "물가변동 계약금액조정 계산기 — ESC 조정금액 자동 계산",
      description: "지수조정률·품목조정률 방식으로 물가변동 계약금액조정(ESC) 금액을 자동 계산합니다. 선금 공제, 가중평균 등락률, 조정 가능 여부까지 즉시 확인하세요.",
      keywords: "물가변동조정,ESC,계약금액조정,지수조정률,품목조정률,선금공제,물가변동 계산기",
      og: {
        title: "물가변동 계약금액조정 계산기 — 실무.kr",
        description: "ESC 조정금액을 지수조정률·품목조정률 방식으로 자동 계산합니다.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "물가변동 계약금액조정 계산기",
        description: "지수조정률·품목조정률 방식으로 물가변동 계약금액조정(ESC) 금액을 자동 계산하는 무료 도구",
        url: price_adjustment_calculator_url
      )
    )
  end

  def budget_execution_rate
    description_text = "예산 항목별 집행액을 입력하면 집행률과 잔액을 자동 계산합니다. 월별 권장 집행률과 비교하여 집행 속도를 즉시 파악하고, 연말 집행 목표 달성 여부를 미리 확인하세요."

    set_meta_tags(
      title: "예산 집행률 계산기 — 예산 집행 현황 즉시 파악",
      description: description_text,
      keywords: "예산집행률, 예산집행, 예산잔액, 집행률계산, 예산관리, 지방예산",
      og: {
        title: "예산 집행률 계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def contingency_fund
    description_text = "예산 총액을 입력하면 지방재정법 제43조에 따른 예비비 법정 한도(1% 이내)와 적정 편성 금액을 자동 계산합니다. 현재 편성액과 비교하여 법적 적정 여부를 즉시 확인하세요."

    set_meta_tags(
      title: "예비비 한도 계산기 — 지방재정법 예비비 법정 한도 계산",
      description: description_text,
      keywords: "예비비, 예비비한도, 지방재정법43조, 예비비편성, 일반예비비, 목적예비비",
      og: {
        title: "예비비 한도 계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def overtime_calculator
    description_text = "공무원 시간외·야간·휴일 초과근무수당을 자동 계산합니다. 월봉급액과 근무 유형·시간을 입력하면 공무원수당 등에 관한 규정에 따라 수당이 즉시 산출됩니다."

    set_meta_tags(
      title: "초과근무수당 계산기 — 공무원 시간외·야간·휴일근무수당 자동 계산",
      description: description_text,
      keywords: "초과근무수당, 시간외근무수당, 야간근무수당, 휴일근무수당, 공무원수당, 월봉급액, 209시간",
      og: {
        title: "초과근무수당 계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def annual_leave_calculator
    description_text = "공무원 재직 기간에 따른 연가일수와 잔여 연가를 자동 계산합니다. 임용일 입력만으로 부여 연가·사용 연가·잔여 연가·연가보상비까지 한 번에 확인하세요."

    set_meta_tags(
      title: "연가일수 계산기 — 공무원 재직 기간별 연가 자동 계산",
      description: description_text,
      keywords: "연가일수, 공무원 연가, 재직기간, 연가보상비, 복무규정, 잔여연가",
      og: {
        title: "연가일수 계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "연가일수 계산기",
        description: "공무원 재직 기간별 연가일수와 연가보상비를 자동 계산하는 무료 도구",
        url: annual_leave_calculator_url
      )
    )
  end

  def severance_calculator
    description_text = "공무원 퇴직수당을 재직기간과 기준 소득월액으로 자동 계산합니다. 공무원연금법 제64조 기준, 재직기간별 지급율(6.5~10%)을 적용하여 퇴직수당 예상액을 즉시 산출합니다."

    set_meta_tags(
      title: "퇴직금 계산기 — 공무원 퇴직수당 자동 계산 (재직기간별)",
      description: description_text,
      keywords: "퇴직금 계산기, 공무원 퇴직수당, 퇴직수당 계산, 공무원연금법, 재직기간, 기준소득월액",
      og: {
        title: "퇴직금 계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def performance_bonus_calculator
    description_text = "공무원 성과상여금을 성과등급과 월봉급액으로 자동 계산합니다. S·A·B등급별 지급율(172.5%/125%/85%)을 적용, 연간 지급액까지 한 번에 확인하세요."

    set_meta_tags(
      title: "성과상여금 계산기 — 공무원 성과등급별 상여금 자동 계산",
      description: description_text,
      keywords: "성과상여금, 성과상여금 계산기, 공무원 성과급, 성과등급, S등급 A등급, 공무원수당",
      og: {
        title: "성과상여금 계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
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
    ics_content = generate_government_ics
    send_data ics_content,
      filename: "silmu-kr-업무달력.ics",
      type: "text/calendar; charset=utf-8",
      disposition: "attachment"
  end

  def travel_calculator
    description_text = "공무원 국내·외 출장 여비를 자동으로 계산합니다. 교통비, 일비, 숙박비, 식비를 한 번에 산출하고, 국내출장과 해외출장을 구분하여 정확한 여비를 계산합니다. 공무원 여비 규정에 따라 자동 계산됩니다."

    set_meta_tags(
      title: "여비계산기 — 공무원 출장 교통비·숙박비·일비 자동 계산",
      description: description_text,
      keywords: "여비계산기, 출장 여비, 공무원 출장비, 교통비, 숙박비",
      og: {
        title: "여비계산기 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      json_ld: tool_json_ld(
        tool_name: "여비계산기",
        description: "공무원 국내·외 출장 여비(교통비·숙박비·일비·식비)를 자동 계산하는 무료 도구",
        url: travel_calculator_url
      )
    )
  end

  private

  # 공무원 연간 업무 사이클 기반 ICS 생성 (외부 gem 없이 문자열 직접 생성)
  def generate_government_ics
    events = [
      {
        uid: "budget-request-jan@silmu.kr",
        dtstart: "20260107",
        dtend: "20260108",
        summary: "신규 예산 배정 요청 마감",
        description: "새해 신규 예산 배정 요청 마감일입니다. 각 부서별 예산 요구서를 제출하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=1WE"
      },
      {
        uid: "settlement-report-feb@silmu.kr",
        dtstart: "20260228",
        dtend: "20260301",
        summary: "전년도 결산보고서 제출",
        description: "전년도 예산 결산보고서를 제출하는 기한입니다. 세입·세출 결산서를 최종 확인하고 제출하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=28"
      },
      {
        uid: "procurement-plan-mar@silmu.kr",
        dtstart: "20260301",
        dtend: "20260401",
        summary: "상반기 발주계획 검토",
        description: "상반기 계약·발주 계획을 검토하고 확정하는 기간입니다. 예산 집행 계획과 연계하여 발주 일정을 수립하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=3"
      },
      {
        uid: "audit-settlement-apr@silmu.kr",
        dtstart: "20260410",
        dtend: "20260411",
        summary: "기획재정부 결산 감사원 제출 기한",
        description: "기획재정부 결산서를 감사원에 제출하는 법정 기한입니다. 국가회계법 제15조에 따른 의무 제출 기한을 준수하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=4;BYMONTHDAY=10"
      },
      {
        uid: "budget-execution-check-jun@silmu.kr",
        dtstart: "20260630",
        dtend: "20260701",
        summary: "상반기 예산 집행률 점검",
        description: "상반기(1~6월) 예산 집행률을 점검하는 기한입니다. 집행 부진 사업은 원인을 분석하고 하반기 집행 계획을 재수립하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=6;BYMONTHDAY=30"
      },
      {
        uid: "intensive-execution-jul@silmu.kr",
        dtstart: "20260701",
        dtend: "20260901",
        summary: "불용 예산 방지 집중 집행 기간",
        description: "7~8월은 연말 예산 불용을 방지하기 위한 집중 집행 기간입니다. 발주 및 계약 추진을 서둘러 연말 집행 목표를 달성하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=7"
      },
      {
        uid: "budget-request-sep@silmu.kr",
        dtstart: "20260901",
        dtend: "20261001",
        summary: "다음 연도 예산요구서 준비",
        description: "다음 연도 예산요구서 작성 및 제출 기간입니다. 사업 우선순위와 소요 예산을 검토하여 예산요구서를 작성하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=9"
      },
      {
        uid: "year-end-budget-dec@silmu.kr",
        dtstart: "20261201",
        dtend: "20270101",
        summary: "연말 예산 집행 마감 / 불용 처리",
        description: "12월은 연말 예산 집행 마감 기간입니다. 미집행 예산의 불용 처리 계획을 수립하고, 계약 및 지출 결의를 12월 말 전에 완료하세요. 실무.kr 상세 가이드: https://silmu.kr/guides",
        rrule: "RRULE:FREQ=YEARLY;BYMONTH=12"
      }
    ]

    lines = []
    lines << "BEGIN:VCALENDAR"
    lines << "VERSION:2.0"
    lines << "PRODID:-//silmu.kr//공무원 업무달력//KO"
    lines << "X-WR-CALNAME:실무.kr 공무원 업무달력"
    lines << "X-WR-TIMEZONE:Asia/Seoul"
    lines << "CALSCALE:GREGORIAN"
    lines << "METHOD:PUBLISH"

    events.each do |event|
      lines << "BEGIN:VEVENT"
      lines << "UID:#{event[:uid]}"
      lines << "DTSTART;VALUE=DATE:#{event[:dtstart]}"
      lines << "DTEND;VALUE=DATE:#{event[:dtend]}"
      lines << "SUMMARY:#{event[:summary]}"
      # ICS DESCRIPTION은 75자 단위 줄 접기 (RFC 5545) — 간략히 처리
      desc = event[:description].gsub(",", "\\,").gsub(";", "\\;")
      lines << "DESCRIPTION:#{desc}"
      lines << "URL:https://silmu.kr/tools/task-calendar"
      lines << event[:rrule]
      lines << "END:VEVENT"
    end

    lines << "END:VCALENDAR"
    lines.join("\r\n") + "\r\n"
  end
end
