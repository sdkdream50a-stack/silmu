# 공공조달관리사 시험 일정의 단일 정본.
#
# 시험일을 화면·메일·JS 에 따로 적어 두면 시험이 지난 뒤 D-day 가 조용히 깨진다
# (hero 는 D+N, 메일은 D-0 고정). 일정은 여기서만 고친다.
#
# 출처: Q-Net 공공조달관리사 시험정보(jmCd=9777) — 2026-09-17 확인.
module ExamSchedule
  SOURCE_NAME = "큐넷(Q-Net) 공고".freeze
  SOURCE_URL = "https://www.q-net.or.kr/crf005.do?id=crf00503&jmCd=9777".freeze
  VERIFIED_ON = Date.new(2026, 9, 17)

  ROUND = 1

  # 화면 타임라인 순서 그대로.
  TIMELINE = [
    { step: "필기 원서 접수", icon: "edit_note", period: "2026.09.14(월) 10:00 ~ 09.17(목) 18:00", detail: "큐넷(Q-Net) 인터넷 접수 · 빈자리 추가접수 2026.09.28" },
    { step: "필기 시험", icon: "article", period: "2026.10.03(토)", detail: "3과목 객관식 CBT / 총 80문항 (1과목 30·2과목 20·3과목 30) / 시험 시간 120분" },
    { step: "필기 합격 발표", icon: "campaign", period: "2026.10.12(월)", detail: "큐넷(Q-Net)에서 발표 / 필기 합격자에 한해 실기 시험 응시" },
    { step: "실기 원서 접수", icon: "edit_note", period: "2026.10.12(월) ~ 10.15(목)", detail: "큐넷(Q-Net) 인터넷 접수" },
    { step: "실기 시험", icon: "assignment_turned_in", period: "2026.11.14(토)", detail: "공공조달 관리실무 / 필답형 20문항 내외 / 시험 시간 150분" },
    { step: "최종 합격 발표", icon: "verified", period: "2026.12.18(금)", detail: "최종 합격자에게 국가기술자격증 발급" }
  ].freeze

  # D-day 대상. 날짜 오름차순.
  EXAMS = [
    { key: "written", label: "필기시험", on: Date.new(2026, 10, 3) },
    { key: "practical", label: "실기시험", on: Date.new(2026, 11, 14) }
  ].freeze

  module_function

  # 오늘 이후(오늘 포함) 가장 가까운 시험. 모두 지났으면 nil.
  def next_exam(today = Time.zone.today)
    EXAMS.find { |exam| exam[:on] >= today }
  end

  def days_until_next_exam(today = Time.zone.today)
    exam = next_exam(today)
    exam && (exam[:on] - today).to_i
  end
end
