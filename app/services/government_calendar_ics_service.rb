# 공무원 연간 업무 사이클 ICS 생성 (외부 gem 없이 RFC 5545 문자열 직접 생성).
# tools_controller.rb의 `task_calendar_ics` 액션에서 사용.
class GovernmentCalendarIcsService
  EVENTS = [
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
  ].freeze

  def self.generate
    lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//silmu.kr//공무원 업무달력//KO",
      "X-WR-CALNAME:실무.kr 공무원 업무달력",
      "X-WR-TIMEZONE:Asia/Seoul",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH"
    ]

    EVENTS.each do |event|
      lines << "BEGIN:VEVENT"
      lines << "UID:#{event[:uid]}"
      lines << "DTSTART;VALUE=DATE:#{event[:dtstart]}"
      lines << "DTEND;VALUE=DATE:#{event[:dtend]}"
      lines << "SUMMARY:#{event[:summary]}"
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
