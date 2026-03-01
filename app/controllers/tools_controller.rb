class ToolsController < ApplicationController
  def index
    # HTTP 캐싱: 도구 목록은 변경이 드물므로 1시간 캐시
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    description_text = "계약방식 결정, 예정가격 계산, 계약보증금 계산, 여비계산, 법정기간 산출 등 공무원 업무를 자동화하는 #{ApplicationHelper::ACTIVE_TOOL_COUNT}개 실무 도구. 복잡한 법령과 절차를 원클릭으로 해결하고, 업무 시간을 단축하세요."

    set_meta_tags(
      title: "실무 도구 — 계약·예산 자동화 계산기 모음",
      description: description_text,
      keywords: "계약방식, 예정가격 계산기, 계약보증금, 여비계산기, 법정기간, PDF 도구",
      og: {
        title: "실무 도구 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
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
      }
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
      }
    )
  end
end
