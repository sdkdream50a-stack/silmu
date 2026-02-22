class ToolsController < ApplicationController
  def index
    # HTTP 캐싱: 도구 목록은 변경이 드물므로 1시간 캐시
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    description_text = "계약방식 결정, 예정가격 계산, 계약보증금 계산, 여비계산, 법정기간 산출 등 공무원 업무를 자동화하는 #{ApplicationHelper::ACTIVE_TOOL_COUNT}개 실무 도구. 복잡한 법령과 절차를 원클릭으로 해결하고, 업무 시간을 단축하세요."

    set_meta_tags(
      title: "실무 도구",
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
      title: "업무 할일 달력",
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

  def travel_calculator
    description_text = "공무원 국내·외 출장 여비를 자동으로 계산합니다. 교통비, 일비, 숙박비, 식비를 한 번에 산출하고, 국내출장과 해외출장을 구분하여 정확한 여비를 계산합니다. 공무원 여비 규정에 따라 자동 계산됩니다."

    set_meta_tags(
      title: "여비계산기",
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
