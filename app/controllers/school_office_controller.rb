# frozen_string_literal: true

# P1-1 (LECTURE_READINESS_AUDIT · QUICK_START_RECOMMENDATION) — 학교 행정실 상설 허브.
#
# 왜 별도 경로인가: 홈(`/?sector=edu`)은 전체가 계약·지방자치단체 중심이라 학교 담당자의
# 진입점으로 쓰기 어렵고, `/start` 는 «신규자 첫달 **계약** 코스» 라 이름을 바꾸면 기존 의미가 깨진다.
# 그래서 새 콘텐츠를 만들지 않고 **기존 자산만 링크하는** 상설 목록 페이지를 둔다.
#
# 규칙
#   · 여기서 새 사실을 만들지 않는다. 모든 항목은 이미 있는 페이지다.
#   · 링크가 죽으면 허브 자체가 거짓이 되므로 전 경로를 테스트가 실제로 GET 한다.
#
# ── P0 (2026-09-20 · STANDARD_SEPARATION) ────────────────────────────────────
# 이전 판본은 지자체 기준 자산에 `note` 만 붙이고 **핵심 카드 자리에 그대로 뒀다**.
# 그런데 이 화면의 이름이 «학교 행정실 바로가기» 다 — 사용자는 여기 있는 것을
# «학교에서 바로 쓰는 도구» 로 읽는다. 경고문은 그 구조적 약속을 뒤집지 못한다.
# 그래서 표시가 아니라 **자리**를 바꾼다. 판정표 = artifacts/01_CARD_STANDARD_CENSUS.md.
#
#   tier: (없음)      SCHOOL_DIRECT        — 학교 기준으로 바로 쓴다. 핵심 카드.
#         :conditional SCHOOL_WITH_CONDITION — 쓸 수 있으나 학교 적용 전에 확인할 것이 있다.
#                                             핵심 카드에 두되 **무엇이 다른지** 카드에 적는다.
#         :reference   LOCAL_GOV_ONLY       — 지자체 기준이라 학교 기준이 아니다.
#                                             핵심 카드에서 빼고 접힌 참고자료로 내린다.
#
# 판정 근거는 추측이 아니라 코드다 — `config/tool_trust.yml` 의 `jurisdiction.school_differs`
# 와 각 guide seed 의 `laws:` 원문. 근거를 못 찾은 자산은 강등하지 않는다(모름 ≠ 지자체).
#
# 아예 뺀 것: `/tools/budget-category-finder`. 등록부가 스스로
#   «이 도구가 추천하는 편성목(201·410~430 등)은 학교회계 과목이 아닙니다» 라고 적는다.
#   학교 사용자에게 **틀린 과목코드**를 주는 도구라 참고자료로도 가치가 없다.
#   대신 «학교회계 과목 도구는 없다» 를 화면에 적는다 — 없는 기능을 만들지 않는다.
class SchoolOfficeController < ApplicationController
  # 접힌 참고자료 영역의 이름 — 축마다 같은 문구를 쓴다.
  REFERENCE_HEADING = "지방자치단체 기준 참고자료"
  REFERENCE_LEAD    = "학교회계 기준이 아닙니다. 절차·과목·심의 주체가 달라 그대로 적용할 수 없습니다."
  CONDITIONAL_BADGE = "학교 적용 전 확인"

  # PHASE B — 축 판정은 artifacts/24_SCHOOL_IA_AXIS_JUDGMENT.md 가 소유한다(운영 실측 기반).
  #   AVAILABLE : 자산이 충분해 축으로 세운다
  #   NEEDS     : 링크는 주되 **얇다는 사실을 화면에 적는다**. «지침을 준다» 고 포장하지 않는다
  # 학교 IA 를 `sector: edu` 필터로 만들 수 없다는 것이 이 설계의 출발점이다 —
  # 토픽 114건 중 edu 태그는 6건이고 행정실이 쓰는 지식은 대부분 common 에 있다.
  # 그래서 단위가 «필터» 가 아니라 «축 + 적용 차이 표시» 다.
  SECTIONS = [
    {
      id: "contract",
      title: "계약·감사",
      icon: "gavel",
      items: [
        # P2 (2026-09-20 · CONNECTED_WORKFLOW) — 이 축의 **입구**. 종전에는 도구 6개가 나란히 있어
        # 「무엇부터 하는가」를 화면이 답하지 않았다. 흐름도는 물품·용역·공사 각 8단계에
        # 그 단계에서 쓸 도구·서식을 결속하고 있으므로, 개별 도구보다 먼저 온다.
        # 학교 기준 여부: 학교 계약도 **지방계약법**이 적용된다(tool_trust budget-estimator
        # jurisdiction.agency = 「지방자치단체 · 국·공립학교(학교장이 체결하는 계약)」). 그래서 강등하지 않는다.
        { label: "계약 전 과정 흐름도 — 물품·용역·공사", path: "/guides/contract-flow" },
        { label: "계약방식 결정",            path: "/tools/contract-method" },
        { label: "분할계약 점검",            path: "/tools/split-contract-checker" },
        { label: "계약 전 확인 목록",        path: "/guides/pre-contract-checklist" },
        { label: "학교장터·나라장터 가이드",  path: "/guides/e-procurement-guide" },
        { label: "교육 분야 감사 지적사례",  path: "/audit-cases?sector=edu" },
        { label: "실무 검증실 Beta — 견적서·공고문 검토", path: "/review-lab",
          note: "문서 업로드는 로그인 후 · 사전검토용(최종 판단은 담당자)" }
      ]
    },
    {
      id: "budget",
      title: "예산·학교회계",
      icon: "account_balance_wallet",
      items: [
        # P3 — 이 축에서 유일하게 «학교회계 자체» 를 기준으로 계산하는 자산이다.
        # 근거가 법률(초·중등교육법 §30의3)이라 조건부 표시를 붙이지 않는다.
        { label: "학교회계 일정 — 지금 무엇을 할 때인가", path: "/school-office/calendar" },
        { label: "학교회계 예산편성 절차",   path: "/topics/school-budget-compilation" },
        # 산식(집행액÷예산액)은 기준 중립이고 **회계연도 시작월만** 다르다. 그래서 버리지 않고
        # 학교회계(3월)로 맞춘 채 연다 — 사용자에게 «바꿔서 쓰세요» 를 시키지 않는다.
        # `?fy=3` 는 Cloudflare 캐시 키에 포함된다(2026-09-20 실측: 무쿼리 UPDATING / ?fy=3 MISS).
        { label: "예산 집행률 계산기",       path: "/tools/budget-execution-rate", href: "/tools/budget-execution-rate?fy=3",
          tier: :conditional,
          note: "학교회계(3월 시작)로 맞춰 열립니다 · 참고선은 산술이며 법정 목표율이 아닙니다" },
        { label: "이용·전용 점검",           path: "/tools/budget-transfer-checker", tier: :reference,
          note: "학교회계는 학교운영위원회 심의라 이 판단기의 «의회 심의» 요건이 그대로 적용되지 않습니다" },
        { label: "지출 품의·결의 서류 작성법", path: "/guides/budget-execution-complete-3", tier: :reference,
          note: "지방회계법 시행령·지자체 세출예산 집행기준 기준" }
      ]
    },
    {
      id: "payroll",
      title: "급여·복무",
      icon: "payments",
      items: [
        { label: "연가 계산기",              path: "/tools/annual-leave-calculator" },
        { label: "초과근무수당 계산기",      path: "/tools/overtime-calculator" },
        { label: "수당 계산기",              path: "/tools/allowance-calculator" },
        { label: "봉급 실수령액 계산기",     path: "/tools/salary-calculator" },
        { label: "4대보험 정산보험료 계산기", path: "/tools/insurance-calculator" },
        # 계산기 3종은 등록부가 국가·지방 규정을 병기한다(G-24). 아래 두 가이드는 본문 근거가
        # **국가**공무원 규정 단독이라 교육행정직(지방공무원)에게는 한 단계 확인이 남는다.
        { label: "보수 체계 기초",           path: "/guides/hr-welfare-complete-6", tier: :conditional,
          note: "국가공무원 보수규정 기준 — 교육행정직은 지방공무원 보수규정을 확인하세요" },
        { label: "각종 수당 기초",           path: "/guides/hr-welfare-complete-7", tier: :conditional,
          note: "국가공무원 수당규정 기준 — 교육행정직은 지방공무원 수당규정을 확인하세요" },
        { label: "연말정산",                 path: "/topics/year-end-settlement" },
        { label: "병가",                     path: "/topics/sick-leave" },
        { label: "퇴직월 초과근무",          path: "/topics/edu-overtime-retirement-month" },
        { label: "기간제교사 경력 가산",     path: "/topics/edu-allowance-temp-teacher-tenure" },
        { label: "비대상 경력의 가산 여부",  path: "/topics/edu-allowance-tenure-non-eligible-career" },
        { label: "육아휴직수당 상한",        path: "/topics/edu-childcare-allowance-cap" },
        { label: "육아휴직수당 2025 개정",   path: "/topics/edu-childcare-pay-2025-revision" },
        { label: "감사사례 — 병가 진단서",   path: "/audit-cases/sen-2025-school-d-sick-leave-certificate",
          note: "재구성 사례입니다 — 실제 감사결과가 아닙니다" },
        { label: "감사사례 — 특별휴가 증빙", path: "/audit-cases/sen-2025-school-s-special-leave-evidence" }
      ]
    },
    {
      id: "goods",
      title: "물품·검수",
      icon: "inventory_2",
      # NEEDS — 운영 실측: Topic property 1건 · 검수/검사 감사사례 1건. 링크는 주되 얇다고 적는다.
      thin: "이 축은 자료가 적습니다(재물조사 도구는 없습니다). 기관 물품관리 규칙과 교육청 지침을 함께 확인하세요.",
      items: [
        { label: "견적서 검토 — 실무 검증실 Beta", path: "/review-lab/quote",
          note: "문서 업로드는 로그인 후 · 계산·대조까지(최종 판단은 담당자)" },
        { label: "2인 이상 견적",            path: "/topics/dual-quote" },
        { label: "구매와 검사·검수",         path: "/guides/purchase-and-inspection", tier: :conditional,
          note: "물품관리 절차는 지자체 조례 기준 — 학교는 교육청 물품관리 규칙을 확인하세요" },
        { label: "검사·검수",                path: "/topics/inspection" },
        { label: "물품선정위원회",           path: "/topics/goods-selection-committee", tier: :conditional,
          note: "법정 위원회가 아닙니다 — 기관 자치법규·교육청 지침 소관" },
        { label: "물품 검사검수조서 서식",   path: "/templates/3" },
        { label: "물품 인수증 서식",         path: "/templates/4" },
        { label: "검수조서 작성 가이드",     path: "/guides/inspection-report", tier: :conditional,
          note: "물품관리 절차는 지자체 조례 기준 — 학교는 교육청 물품관리 규칙을 확인하세요" },
        { label: "물품 구매 기안문 서식",    path: "/templates/17" },
        { label: "감사사례 — 직접생산 확인", path: "/audit-cases/sen-2025-school-s-supply-direct-prod-cert" }
      ]
    },
    {
      id: "newcomer",
      title: "신규 담당자",
      icon: "school",
      items: [
        { label: "첫달 코스",                path: "/start", tier: :conditional,
          note: "계약 업무 중심 코스입니다" },
        { label: "인사·복무 기초",           path: "/guides/hr-welfare-complete-1", tier: :conditional,
          note: "국가공무원법 기준 — 교육행정직은 지방공무원법을 확인하세요" },
        { label: "연가 실무",                path: "/guides/hr-welfare-complete-2", tier: :conditional,
          note: "국가공무원 복무규정 기준 — 교육행정직은 지방공무원 복무규정을 확인하세요" },
        { label: "자주 나오는 감사 지적",    path: "/guides/audit-frequent-issues" },
        # 전수점검(§4)에서 새로 찾은 혼입 — 회계 일정이 1~12월 회계연도 가정이다
        # (12/31 «회계연도 마감», 1/31 «전년도 세입·세출 결산», 3·6·9월 분기결산).
        { label: "업무 달력",                path: "/tools/task-calendar", tier: :conditional,
          note: "회계 일정은 지자체 회계연도(1~12월) 기준 — 학교회계(3월~다음 해 2월) 일정은 «학교회계 일정» 에 있습니다" }
      ]
    }
  ].freeze

  # 허브가 참조하는 모든 경로 — 테스트가 이 목록을 그대로 순회한다.
  def self.all_paths = SECTIONS.flat_map { |s| s[:items].map { |i| i[:path] } }

  # 핵심 카드(접힌 참고자료가 아닌 것)만. «지자체 기준이 핵심에 0건» 을 테스트가 이것으로 잰다.
  def self.primary_items = SECTIONS.flat_map { |s| s[:items].reject { |i| i[:tier] == :reference } }

  def self.reference_items = SECTIONS.flat_map { |s| s[:items].select { |i| i[:tier] == :reference } }

  # ── P3 (2026-09-20 · SCHOOL_ACCOUNTING_CALENDAR) ─────────────────────────────
  # `/tools/task-calendar` 는 1~12월 회계연도를 전제한 월별 반복 업무 달력이라 학교에서는
  # 「회계」 항목이 통째로 틀린다. 그 달력을 고치지 않고 **학교회계 전용 면**을 따로 둔다 —
  # 한 달력에 두 회계연도를 억지로 합치면 어느 쪽 사용자에게도 거짓이 되기 때문이다.
  #
  # 계산은 전부 `SchoolAccountingCalendar`(순수 날짜 산술)가 한다. 이 액션은 입력을 좁히고
  # 결과를 넘길 뿐이다. LLM·추정 없음.
  CALENDAR_TITLE = "학교회계 일정"

  def calendar
    @today  = Time.zone.today
    @status = SchoolAccountingCalendar.status(on: @today)
    @rules  = SchoolAccountingCalendar.regional_rules
    @selected_rule = SchoolAccountingCalendar.regional_rule(params[:edu].to_s)
    @closing_split = SchoolAccountingCalendar.rule_value_split(:closing_type)

    # 준예산 판정 — 사용자가 고른 «법률 각 호» 만 본다. 지출 목적 문장을 우리가 분류하지 않는다.
    @provisional_selected = Array(params[:pb]).map(&:to_s)
                                              .select { |n| n.match?(/\A[1-5]\z/) }
                                              .map(&:to_i).uniq.sort
    @provisional_unsure = params[:pb_unsure].present?
    @provisional_answered = params[:pb_submitted].present?
    @provisional_verdict =
      if !@provisional_answered then nil
      elsif @provisional_unsure then :check_required
      elsif @provisional_selected.any? then :matched
      else :not_matched
      end

    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_meta_tags(
      title: CALENDAR_TITLE,
      description: "학교회계 회계연도(3월 1일~다음 해 2월 말일) 기준으로 예산안 제출·학교운영위원회 심의·결산서 제출 등 법정 기한까지 남은 일수를 계산합니다.",
      keywords: "학교회계 일정, 학교회계 회계연도, 학교회계 예산편성 기한, 학교운영위원회 예산 심의, 학교회계 결산, 준예산",
      canonical: request.original_url.split("?").first
    )
  end

  def index
    @sections = SECTIONS

    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_meta_tags(
      title: "학교 행정실 바로가기",
      description: "학교 행정실 담당자가 계약·예산·급여·복무·물품 업무에서 바로 쓰는 실무.kr 도구와 자료 모음입니다.",
      keywords: "학교 행정실, 학교회계, 교육행정직, 학교 계약, 연가, 초과근무",
      canonical: request.original_url.split("?").first
    )
  end
end
