# frozen_string_literal: true

# P1-1 (LECTURE_READINESS_AUDIT · QUICK_START_RECOMMENDATION) — 학교 행정실 상설 허브.
#
# 왜 별도 경로인가: 홈(`/?sector=edu`)은 전체가 계약·지방자치단체 중심이라 학교 담당자의
# 진입점으로 쓰기 어렵고, `/start` 는 «신규자 첫달 **계약** 코스» 라 이름을 바꾸면 기존 의미가 깨진다.
# 그래서 새 콘텐츠를 만들지 않고 **기존 자산만 링크하는** 상설 목록 페이지를 둔다.
#
# 규칙
#   · 여기서 새 사실을 만들지 않는다. 모든 항목은 이미 있는 페이지다.
#   · 학교회계 기준이 아닌 자산에는 `note` 로 그 사실을 붙인다 — 빼는 대신 «다르다» 고 말한다.
#     (감사 시점에는 예산 도구·물품선정위원회를 «수리 전이라 제외» 했는데, R1·R3 가
#      2026-09-18 배포로 닫혀 적용기관 고지가 붙었으므로 note 를 달고 넣는다.)
#   · 링크가 죽으면 허브 자체가 거짓이 되므로 전 경로를 테스트가 실제로 GET 한다.
class SchoolOfficeController < ApplicationController
  LOCALGOV_NOTE = "지방자치단체 기준 — 학교회계는 시도교육청 규칙을 확인하세요"

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
        { label: "학교회계 예산편성 절차",   path: "/topics/school-budget-compilation" },
        { label: "예산집행 완전정복",        path: "/guides/budget-execution-complete-3", note: LOCALGOV_NOTE },
        { label: "예산 집행률 계산기",       path: "/tools/budget-execution-rate",
          note: "회계연도 시작월을 3월(학교회계)로 바꿔서 쓰세요" },
        { label: "예산과목 찾기",            path: "/tools/budget-category-finder", note: LOCALGOV_NOTE },
        { label: "이용·전용 점검",           path: "/tools/budget-transfer-checker", note: LOCALGOV_NOTE }
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
        { label: "보수 체계 기초",           path: "/guides/hr-welfare-complete-6" },
        { label: "각종 수당 기초",           path: "/guides/hr-welfare-complete-7" },
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
        { label: "구매와 검사·검수",         path: "/guides/purchase-and-inspection" },
        { label: "검사·검수",                path: "/topics/inspection" },
        { label: "물품선정위원회",           path: "/topics/goods-selection-committee",
          note: "법정 위원회가 아닙니다 — 기관 자치법규·교육청 지침 소관" },
        { label: "물품 검사검수조서 서식",   path: "/templates/3" },
        { label: "물품 인수증 서식",         path: "/templates/4" },
        { label: "검수조서 작성 가이드",     path: "/guides/inspection-report" },
        { label: "물품 구매 기안문 서식",    path: "/templates/17" },
        { label: "감사사례 — 직접생산 확인", path: "/audit-cases/sen-2025-school-s-supply-direct-prod-cert" }
      ]
    },
    {
      id: "newcomer",
      title: "신규 담당자",
      icon: "school",
      items: [
        { label: "첫달 코스",                path: "/start", note: "계약 업무 중심 코스입니다" },
        { label: "인사·복무 기초",           path: "/guides/hr-welfare-complete-1" },
        { label: "연가 실무",                path: "/guides/hr-welfare-complete-2" },
        { label: "자주 나오는 감사 지적",    path: "/guides/audit-frequent-issues" },
        { label: "업무 달력",                path: "/tools/task-calendar" }
      ]
    }
  ].freeze

  # 허브가 참조하는 모든 경로 — 테스트가 이 목록을 그대로 순회한다.
  def self.all_paths = SECTIONS.flat_map { |s| s[:items].map { |i| i[:path] } }

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
