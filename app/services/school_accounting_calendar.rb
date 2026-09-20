# frozen_string_literal: true

# 학교회계 일정 엔진 — **결정적 날짜 산술만** 한다. LLM·추정·해석 없음.
#
# 왜 별도 엔진인가
#   `/tools/task-calendar` 는 1~12월 회계연도(지방자치단체·국가)를 전제한 월별 반복 업무 달력이다.
#   학교회계의 회계연도는 3월 1일에 시작한다(「초·중등교육법」제30조의3제1항). 두 기준을 한 달력에
#   섞으면 어느 쪽 사용자에게도 거짓이 되므로 **엔진과 화면을 나눈다**(LOCAL_GOV / SCHOOL_ACCOUNTING).
#
# 근거 층(basis) — 교육청 규칙을 전국 공통 규칙처럼 쓰지 않는다
#   :law       「초·중등교육법」 — 17개 시·도 전부에 같이 적용된다.
#   :edu_rule  시·도 교육규칙 — 교육청별. **17개 전수 실측으로 균일한 것만** 여기서 기한으로 쓴다.
#   :guideline 교육감 예산편성 기본지침 — 연 1회·교육청별. 참고 일정으로만 적고 D-day 로 쓰지 않는다.
#
# 「N일 전까지」의 날짜 환산
#   법문은 날짜를 주지 않는다. 교육청 지침이 같은 조문을 실제로 환산한 값을 대조해 규칙을 정했다 —
#   2026학년도(개시 2026-03-01) 기준
#     · 50일 전 → 2026-01-09  (전남 2026 지침 p.-, 부산 2026 지침 p.-)
#     · 30일 전 → 2026-01-29  (전남·부산 **독립 2건 일치**)
#     ·  5일 전 → 2026-02-23  (전남)
#   세 값 모두 `개시일 − (N+1)일` 과 일치한다. 그래서 그 식을 쓴다 — 우리가 만든 식이 아니라
#   **공식 지침이 쓴 값을 재현하는 식**이다. 원문 인용 = tasks/…-p3-0920/sources/.
#
# 「끝난 후 N개월 이내」의 날짜 환산
#   민법 제157조(초일 불산입)·제160조(역에 의한 계산)를 적용한다 — 기산일은 회계연도 종료 다음 날,
#   만료일은 그 날에 해당하는 날의 전날. 회계연도 종료가 2월 말일이므로 2개월 → **4월 30일**.
#   이것은 해석의 여지가 있는 축이라 화면에 산식을 같이 적는다(`derivation`).
class SchoolAccountingCalendar
  FISCAL_START_MONTH = 3
  FISCAL_START_DAY   = 1

  # 「초·중등교육법」제30조의3 — 2026-09-20 법제처 API 원문 대조(법령일련번호 283903 · 시행 2026-09-11).
  LAW_NAME = "초·중등교육법"

  # 준예산(제30조의3제4항) — 법률이 **닫힌 열거**로 다섯 가지만 적었다.
  # 이 목록을 늘리지 않는다. 늘리는 순간 법률문언을 벗어난 AI 분류가 된다.
  PROVISIONAL_BUDGET_ITEMS = [
    { no: 1, text: "교직원 등의 인건비" },
    { no: 2, text: "학교교육에 직접 사용되는 교육비" },
    { no: 3, text: "학교시설의 유지관리비" },
    { no: 4, text: "법령상 지급 의무가 있는 경비" },
    { no: 5, text: "이미 예산으로 확정된 경비" }
  ].freeze

  PROVISIONAL_BUDGET_CLAUSE =
    "학교의 장은 제3항에 따른 예산안이 새로운 회계연도가 시작될 때까지 확정되지 아니하면 " \
    "다음 각 호의 경비를 전년도 예산에 준하여 집행할 수 있다. 이 경우 전년도 예산에 준하여 " \
    "집행된 예산은 해당 연도의 예산이 확정되면 그 확정된 예산에 따라 집행된 것으로 본다."

  PHASES = {
    settlement:   "결산기",
    execution:    "집행기",
    compilation:  "편성기",
    review:       "심의기",
    confirmation: "확정·마감기"
  }.freeze

  PHASE_NOTES = {
    settlement:   "전년도 결산을 닫으면서 올해 예산을 집행한다. 출납폐쇄 시점은 교육청 규칙에 따라 다르다.",
    execution:    "올해 예산을 집행한다. 법정 기한이 몰려 있지 않은 구간이다.",
    compilation:  "교육감 지침이 온 뒤 다음 회계연도 예산안을 만든다.",
    review:       "예산안을 학교운영위원회에 제출하고 심의를 받는다.",
    confirmation: "예산을 확정·공개하고 올해 지출원인행위를 마감한다."
  }.freeze


  Milestone = Struct.new(
    :key, :label, :date, :fiscal_year, :actor, :basis, :citation,
    :statute_text, :derivation, :next_action, :related, :uniformity,
    keyword_init: true
  ) do
    def days_from(today) = (date - today).to_i
    def past?(today) = date < today
  end

  class << self
    # 어떤 날짜가 속한 학교회계연도(=학년도). 3월 1일에 시작하므로 1·2월은 전년도다.
    def fiscal_year(date) = date.month >= FISCAL_START_MONTH ? date.year : date.year - 1

    def fiscal_start(year) = Date.new(year, FISCAL_START_MONTH, FISCAL_START_DAY)

    # 종료 = 다음 해 2월 **말일**. 윤년은 Date 가 처리한다(-1 = 그 달의 마지막 날).
    def fiscal_end(year) = Date.new(year + 1, 2, -1)

    # 「회계연도가 시작되기 N일 전까지」 — 위 주석의 환산 규칙.
    def days_before_start(year, days) = fiscal_start(year) - (days + 1)

    # 「회계연도가 끝난 후 N개월 이내」 — 민법 §157·§160.
    def months_after_end(year, months) = (fiscal_end(year) + 1).next_month(months) - 1

    # 시·도 교육규칙 레지스트리(17 전수). config/school_accounting_rules.yml 이 정본.
    def regional_rules
      @regional_rules ||= YAML.load_file(Rails.root.join("config", "school_accounting_rules.yml"))
                              .fetch("rules")
                              .map { |r| r.transform_keys(&:to_sym).freeze }
                              .freeze
    end

    def regional_rule(code) = regional_rules.find { |r| r[:code] == code }

    def ordinance_url(rule) = "https://www.law.go.kr/LSW/ordinInfoP.do?ordinSeq=#{rule[:ordin_seq]}"

    # 법제처가 주는 날짜는 `"20161114"` 8자리 문자열이다. 화면용 표기로 바꾼다.
    # ⚠️ `scan(/\d{4}|\d{2}/)` 로 자르면 안 된다 — 대체는 왼쪽부터 시도하므로 남은 `1114` 가
    #    다시 `\d{4}` 에 걸려 «2016.1114» 가 나온다(2026-09-20 독립 리뷰 적발).
    def format_effective_date(value)
      digits = value.to_s
      return digits unless digits.match?(/\A\d{8}\z/)

      "#{digits[0, 4]}.#{digits[4, 2].to_i}.#{digits[6, 2].to_i}"
    end

    # 규칙 층에서 **17개가 같은 값을 갖는 축만** 전국 기한으로 쓴다.
    # 값이 갈리면 nil 을 돌려 화면이 «교육청별로 다르다» 를 말하게 한다.
    def uniform_rule_value(field)
      values = regional_rules.map { |r| r[field] }
      values.uniq.size == 1 ? values.first : nil
    end

    # 17개 중 가장 많은 값과 그 개수. nil(= 그 규칙에 조항이 없다)은 값으로 세지 않는다.
    # 균일하지 않다고 버리면 16/17 이 성립하는 축까지 사라진다 — 개수를 들고 다니면서 화면에 적는다.
    def majority_rule_value(field) = majority_of(regional_rules.map { |r| r[field] })

    # 다수값 계산 자체는 레지스트리와 무관한 순수 함수다. 따로 두면 «nil 이 다수인 입력» 처럼
    # 현재 17개 데이터로는 만들어지지 않는 경우를 검사할 수 있다.
    def majority_of(values)
      counts = values.compact.tally
      return [ nil, 0 ] if counts.empty?

      counts.max_by { |_value, n| n }
    end

    def rule_value_split(field)
      regional_rules.group_by { |r| r[field] }
                    .transform_values { |rs| rs.map { |r| r[:code] } }
    end

    # 한 회계연도의 법정·규칙 일정 전부. 정렬된 Milestone 배열.
    def milestones(year)
      start = fiscal_start(year)
      finish = fiscal_end(year)
      notice_days, notice_count = majority_rule_value(:meeting_notice_days)
      review_months, review_count = majority_rule_value(:settlement_review_months)
      guideline_months = uniform_rule_value(:guideline_months_before)

      list = []

      if guideline_months
        list << Milestone.new(
          key: :guideline, label: "교육감 → 학교: 예산편성 기본지침 시달",
          date: start.prev_month(guideline_months), fiscal_year: year, actor: "교육감(교육장)",
          basis: :edu_rule, citation: "시·도 교육규칙 — 17개 교육청 전부 «회계연도 개시 #{guideline_months}개월 전까지»",
          statute_text: "교육감은 매년 예산편성 기본지침을 작성하여 회계연도 개시 #{guideline_months}개월 전까지 학교의 장에게 시달하여야 한다.",
          derivation: "회계연도 개시일(#{start.strftime('%Y-%m-%d')})에서 #{guideline_months}개월 전",
          next_action: "우리 교육청 지침이 왔는지 확인하고 과목·단가 변경분을 먼저 본다",
          related: [ { label: "학교회계 예산편성 절차", path: "/topics/school-budget-compilation" } ],
          uniformity: "17/17"
        )
      end

      list << Milestone.new(
        key: :budget_submission, label: "학교장 → 학교운영위원회: 세입세출예산안 제출",
        date: days_before_start(year, 30), fiscal_year: year, actor: "학교의 장",
        basis: :law, citation: "#{LAW_NAME} 제30조의3제2항",
        statute_text: "학교의 장은 회계연도마다 학교회계 세입세출예산안을 편성하여 회계연도가 시작되기 30일 전까지 제31조에 따른 학교운영위원회에 제출하여야 한다.",
        derivation: "회계연도 개시일(#{start.strftime('%Y-%m-%d')}) 기준 30일 전 — 교육청 지침 환산값과 동일",
        next_action: "세입 규모 확정 → 예산요구서 조정 → 예산안 확정 후 제출",
        related: [ { label: "학교회계 예산편성 절차", path: "/topics/school-budget-compilation" } ],
        uniformity: "전국 동일(법률)"
      )

      list << Milestone.new(
        key: :committee_review, label: "학교운영위원회: 예산안 심의",
        date: days_before_start(year, 5), fiscal_year: year, actor: "학교운영위원회",
        basis: :law, citation: "#{LAW_NAME} 제30조의3제3항",
        statute_text: "학교운영위원회는 학교회계 세입세출예산안을 회계연도가 시작되기 5일 전까지 심의하여야 한다.",
        derivation: "회계연도 개시일(#{start.strftime('%Y-%m-%d')}) 기준 5일 전 — 교육청 지침 환산값과 동일",
        next_action: notice_days ? "회의 개최 #{notice_days}일 전까지 위원에게 예산안을 개별 통지해야 하므로(#{notice_count}/#{regional_rules.size} 교육청 규칙) 회의 날짜를 먼저 잡고 그 날에서 역산한다" : "학교장 제안설명 준비 · 심의 결과 통보 서식 확인",
        related: [],
        uniformity: "전국 동일(법률)"
      )

      list << Milestone.new(
        key: :fiscal_start, label: "회계연도 개시",
        date: start, fiscal_year: year, actor: "학교",
        basis: :law, citation: "#{LAW_NAME} 제30조의3제1항",
        statute_text: "학교회계의 회계연도는 매년 3월 1일에 시작하여 다음 해 2월 말일에 끝난다.",
        derivation: nil,
        next_action: "예산이 확정되지 않았다면 준예산(제30조의3제4항) 다섯 가지만 집행할 수 있다",
        related: [ { label: "예산 집행률 계산기(학교회계 3월 기준)", path: "/tools/budget-execution-rate", href: "/tools/budget-execution-rate?fy=3" } ],
        uniformity: "전국 동일(법률)"
      )

      list << Milestone.new(
        key: :fiscal_end, label: "회계연도 종료",
        date: finish, fiscal_year: year, actor: "학교",
        basis: :law, citation: "#{LAW_NAME} 제30조의3제1항",
        statute_text: "학교회계의 회계연도는 매년 3월 1일에 시작하여 다음 해 2월 말일에 끝난다.",
        derivation: "다음 해 2월 말일 — 윤년이면 2월 29일",
        next_action: "지출원인행위를 마감하고 잔액·이월 대상을 정리한다",
        related: [ { label: "예산 집행률 계산기(학교회계 3월 기준)", path: "/tools/budget-execution-rate", href: "/tools/budget-execution-rate?fy=3" } ],
        uniformity: "전국 동일(법률)"
      )

      list << Milestone.new(
        key: :settlement_submission, label: "학교장 → 학교운영위원회: 결산서 제출",
        date: months_after_end(year, 2), fiscal_year: year, actor: "학교의 장",
        basis: :law, citation: "#{LAW_NAME} 제30조의3제5항",
        statute_text: "학교의 장은 회계연도마다 결산서를 작성하여 회계연도가 끝난 후 2개월 이내에 학교운영위원회에 제출하여야 한다.",
        derivation: "회계연도 종료(#{finish.strftime('%Y-%m-%d')}) 다음 날부터 2개월 — 민법 제157조·제160조",
        next_action: "예비비 사용·이용/전용·계속비·이월 명세서를 결산서에 첨부한다",
        related: [],
        uniformity: "전국 동일(법률) · 구체 일자는 민법 기간계산"
      )

      if review_months
        list << Milestone.new(
          key: :settlement_review, label: "학교운영위원회 → 학교장: 결산 심의결과 통보",
          date: months_after_end(year, review_months), fiscal_year: year, actor: "학교운영위원장",
          basis: :edu_rule, citation: "시·도 교육규칙 — #{review_count}/#{regional_rules.size} 교육청에 «회계연도 종료 후 #{review_months}개월 이내» 조항",
          statute_text: "학교운영위원회는 결산심의 결과를 회계연도 종료 후 #{review_months}개월 이내에 학교의 장에게 통보하여야 한다.",
          derivation: "회계연도 종료(#{finish.strftime('%Y-%m-%d')}) 다음 날부터 #{review_months}개월 — 민법 제157조·제160조",
          next_action: "심의 결과를 받아 결산을 확정하고 공개 절차로 넘어간다",
          related: [],
          uniformity: "#{review_count}/#{regional_rules.size}"
        )
      end

      list.sort_by(&:date)
    end

    # 오늘 기준 상태. 화면이 이 한 덩어리만 읽으면 되게 한다.
    #
    # 학교 행정실은 한 시점에 **회계연도를 하나만 보지 않는다** — 9월이면 당해연도를 집행하면서
    # 곧 차년도 편성이 시작되고, 3~4월이면 전년도 결산이 함께 돌아간다. 그래서 인접 3개 연도의
    # 일정을 한 줄로 합쳐 정렬한 뒤 «지나간 것/다가오는 것» 으로만 가른다.
    def status(on: Time.zone.today)
      year = fiscal_year(on)
      all = (year - 1..year + 1).flat_map { |y| milestones(y) }.sort_by(&:date)
      upcoming = all.reject { |m| m.past?(on) }

      {
        today: on,
        fiscal_year: year,
        fiscal_year_label: "#{year}학년도",
        fiscal_start: fiscal_start(year),
        fiscal_end: fiscal_end(year),
        days_elapsed: (on - fiscal_start(year)).to_i + 1,
        days_remaining: (fiscal_end(year) - on).to_i,
        phase: phase(on),
        milestones: all,
        upcoming: upcoming,
        next_milestone: upcoming.first
      }
    end

    # 국면 — **날짜 비교만으로** 정해진다. 판단이 들어가지 않는다.
    # 경계는 전부 위 milestones 가 쓰는 것과 같은 기한에서 나온다(새 기준을 만들지 않는다).
    def phase(on = Time.zone.today)
      year = fiscal_year(on)            # 지금 집행 중인 회계연도
      nxt  = year + 1                   # 지금 편성 대상이 되는 회계연도
      prev = year - 1                   # 지금 결산 대상이 되는 회계연도

      return :settlement   if on <= months_after_end(prev, 2)                  # 3/1 ~ 결산서 제출 기한
      return :execution    if on <  fiscal_start(nxt).prev_month(guideline_months_before)
      return :compilation  if on <  days_before_start(nxt, 30)                 # 지침 시달 ~ 제출 기한 전날
      return :review       if on <= days_before_start(nxt, 5)                  # 제출 기한 ~ 심의 기한
      :confirmation                                                            # 심의 기한 다음 날 ~ 2월 말일
    end

    def guideline_months_before = uniform_rule_value(:guideline_months_before) || 3

    def phase_label(key) = PHASES.fetch(key, PHASES[:execution])
  end
end
