# 감사사례 Truth Closure G1 — 경기도교육청 2021 감사사례집 재구성 사례 P0·P1 정정 (2026-09-29)
#
# 입력: tasks/silmu-audit-case-truth-closure-0929/workers/{g1,g2,g5}/verdicts.md 의 P0·P1 행(EVIDENCE·FIX)만.
#   P0 = budget-formation-violation(회계연도 개시 30일 전 «2.1»·«예산 무효»), credit-card-self-inspection(직속기관),
#        daily-audit-89-cases(교육지원청), suspense-cash-single-approval(교육지원청),
#        temporary-building-violation(간선 공급설비 «별도 허가» · 감독청=시·군·구청장 혼합)
#   P1 = beneficiary-cost-direct-use(«관련자 경고» 누락), bid-announcement-period(지역제한 현행 조문),
#        contract-method-2stage-bidding(«6억원 초과 학교운영위 사전 심의» 근거 없음), credit-card-payment-account,
#        deemed-budget-violation, explicit-carryover-violation(공립 단독 표시), suspense-cash-embezzlement(국가공무원법 §82·83),
#        suspense-cash-management(공·사립 혼재), suspension-pay-deduction(지적사항·처분 분리), vehicle-management-failure(직속기관·규칙명)
#
# 원문: 경기도교육청 감사사례집 2021 (workers/g1/src/goe2021.txt · 인쇄쪽 = PDF쪽 − 6).
# 현행 법령(국가법령정보센터 DRF, OC=test, 2026-09-29):
#   지방계약법 시행령 [MST 286149] 제18조①·제20조①6 · 시행규칙 [MST 287365] 제24조·제25조③
#   초ㆍ중등교육법 [MST 283903] 제30조의3①② · 공무원보수규정 [MST 288433] 제22조①
#   공무원수당 등에 관한 규정 [MST 282475] 제11조의3(③·④ 삭제) · 건축법 시행령 제15조①3 · 학교시설사업 촉진법 제5조의2⑥
#   경기도 공립학교회계 규칙(자치법규 2065549, 2025-09-01) 제19조② · 경기도교육비특별회계 소관 공무용 차량 관리 규칙(2025-02-28)
#
# old 는 운영 페이지(https://silmu.kr/audit-cases/<slug>?cb=…, 2026-09-29 익명 GET)의 렌더 문자열과 같다(마크다운 기호 제외).
# edits 는 필드에 old 가 정확히 1회 있어야 바꾼다. 이미 new 면 건너뛴다. 하나라도 어긋나면 전체 롤백.
# agency 는 target_agency=["PUBLIC_SCHOOL"]·HIGH 일 때만 바꾼다(운영 «적용 대상: 공립학교»). 기관 혼재·미특정 = [] + LOW(표시 안 함).
#   운영 페이지에 «적용 대상»이 없는 2건(budget-formation-violation·suspense-cash-management)은 이미 [] 이면 confidence 만 LOW 로 맞춘다.
#   ⚠ `silmu:p1:agency_backfill`(수동 rake)을 다시 돌리면 sector=edu·org_type=school 인 이 사례들을 PUBLIC_SCHOOL 로 되돌린다.
# DRY_RUN=1 이면 레코드별 fields_to_change 만 출력한다. view_count·slug·title 불변.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929100000_audit_truth_g1.rb})"'
#   → 기대: changes=73 (문장 61 · agency 11 · source_page 1; 운영에서 이미 []·LOW 인 agency 가 있으면 그만큼 적음, 최소 71) · 두 번째 실행 changes=0
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화)
# 롤백: edits 는 new → old 역적용, agency 는 ["PUBLIC_SCHOOL"]·HIGH, source_page 는 86.

PUBLIC = [ [ "PUBLIC_SCHOOL" ], "HIGH" ].freeze
agency = {
  "goe-2021-credit-card-self-inspection"     => [ [ "EDUCATION_OFFICE" ], "HIGH" ],
  "goe-2021-daily-audit-89-cases"            => [ [ "EDUCATION_SUPPORT_OFFICE" ], "HIGH" ],
  "goe-2021-suspense-cash-single-approval"   => [ [ "EDUCATION_SUPPORT_OFFICE" ], "HIGH" ],
  "goe-2021-budget-formation-violation"      => [ [], "LOW" ],
  "goe-2021-contract-method-2stage-bidding"  => [ [], "LOW" ],
  "goe-2021-credit-card-payment-account"     => [ [], "LOW" ],
  "goe-2021-deemed-budget-violation"         => [ [], "LOW" ],
  "goe-2021-explicit-carryover-violation"    => [ [], "LOW" ],
  "goe-2021-suspense-cash-management"        => [ [], "LOW" ],
  "goe-2021-temporary-building-violation"    => [ [], "LOW" ],
  "goe-2021-vehicle-management-failure"      => [ [], "LOW" ]
}.freeze

# 출처 쪽수: 직속기관 카드 자체점검 사례는 원문 p.87(p.86 은 카드대금 계좌 사례).
source_page = { "goe-2021-credit-card-self-inspection" => [ 86, 87 ] }.freeze

edits = [
  # ── g1 P1 · 수익자부담경비 직접 사용: 방과후 수강료 건 «관련자 경고» 누락 ──────────
  [ "goe-2021-beneficiary-cost-direct-use", "detail",
    "사례집 원문 처분: «관련자 주의» (경기도교육청 감사사례집, 2021)",
    "사례집 원문 처분: «관련자 주의»(별도 계좌·현장체험학습 건), «관련자 경고»(방과후 특강 수강료 346,320천원 강사 직접 지급 건) (경기도교육청 감사사례집, 2021)" ],

  # ── g1 P1 · 입찰공고 기간·지역제한: 현행 시행령 제20조①6·시행규칙 제24조·제25조③ ──
  [ "goe-2021-bid-announcement-period", "detail",
    "2. **지역제한** — 행정안전부령 미만 물품·용역(건설기술용역 2.1억, 안전점검 1.5억, 그 외 3.3억): 주된 영업소가 납품지가 소재하는 **시·도 관할구역 안**으로 제한 (인접시군·납품지 관할 시군 제한 불가)",
    "2. **지역제한** — 현행: 법인등기부상 본점소재지가 납품지 등이 있는 **시·도 관할구역 안**에 있는 자로 제한(지방계약법 시행령 제20조①6·시행규칙 제25조③). 대상 금액은 시행규칙 제24조(건설기술·건축사·엔지니어링 용역 3억 3천만원, 안전점검·정밀안전진단 용역 1억 5천만원, 그 밖의 용역·물품은 행정안전부장관 고시금액). 인접 시·도 포함은 시행규칙 제25조③ 단서 사유에만 가능, 시·군 단위 제한 불가 (2021 사례집 당시: «주된 영업소», 건설기술용역 2.1억·안전점검 1.5억·그 외 3.3억)" ],
  [ "goe-2021-bid-announcement-period", "lesson",
    "\"경기도, 서울\"처럼 시·도 두 곳을 동시 허용하는 것도 위반 — 단일 시·도만 가능.",
    "지역제한은 납품지 등이 있는 시·도가 원칙이고, 인접 시·도 포함은 시행규칙 제25조③ 단서(현장이 인접 시·도에 걸침 · 인접 시·도에 납품지나 유지관리 시설물 · 자격자 10인 미만)에 해당할 때만 가능." ],

  # ── g1 P0 · 예산편성: 3.1 개시 30일 전 = 1월 말(«2.1» 아님), «예산 무효» 규정 없음 ──
  [ "goe-2021-budget-formation-violation", "issue",
    "회계연도 개시 30일 전(2.1)이 아닌 2.17·2.15에 학교운영위원회에 제출함.",
    "회계연도 개시 30일 전(3.1 개시 기준 1월 말)까지 제출해야 함에도 2.17·2.15에 학교운영위원회에 제출함." ],
  [ "goe-2021-budget-formation-violation", "lesson",
    "3월 이후 편성은 무효.",
    "3월 이후 편성은 감사 지적 대상(원문은 «2월 중 정리추경»을 요구하며, 무효 여부는 원문에 없음)." ],
  [ "goe-2021-budget-formation-violation", "detail",
    "위반 시 예산 무효 또는 학교운영위원회 권한 침해 사유.",
    "위반 시 감사 지적 대상(원문 처분 «관련자 주의» · «예산 무효» 규정은 원문·회계규칙에 없음)." ],

  # ── g2 P0 · 신용카드 자체점검(직속기관): 출처 쪽수 · 점검 양식은 원문 외 ────────────
  [ "goe-2021-credit-card-self-inspection", "detail",
    "「2021 감사사례집」(p.86)",
    "「2021 감사사례집」(p.87)" ],
  [ "goe-2021-credit-card-self-inspection", "lesson",
    "### 점검 양식 7개 항목",
    "### 점검 양식 7개 항목(실무 예시 · 원문 외)" ],

  # ── g2 P0 · 일상감사 89건(교육지원청): 89+44 합산·결재라인 묵인·«매년 30건 이상» ────
  [ "goe-2021-daily-audit-89-cases", "detail",
    "누적 133건(89+44)의 일상감사 절차 위반은 단순 담당자 실수가 아닌 결재라인 묵인이 동반된 시스템적 결함 사례입니다.",
    "원문은 44건이 89건과 별개인지 밝히지 않으므로 두 수치를 합산하지 않습니다." ],
  [ "goe-2021-daily-audit-89-cases", "detail",
    "- 누적 위반: 133건\n- 평균 연간 위반: 약 44건\n",
    "- 위반 규모: 89건 미의뢰 · 44건 회신 전 집행(중복 여부 원문 미기재)\n" ],
  [ "goe-2021-daily-audit-89-cases", "detail",
    "3년간 누적 133건의 일상감사 절차 위반이 발견됐습니다.",
    "3년간 89건 미의뢰·44건 회신 전 집행이 발견됐습니다." ],
  [ "goe-2021-daily-audit-89-cases", "detail",
    "| 결재라인 검증 | 일상감사 의뢰 결재 확인 | 묵인 |",
    "| 결재라인 검증 | 일상감사 의뢰 결재 확인 | 원문 미기재 |" ],
  [ "goe-2021-daily-audit-89-cases", "detail",
    "교육지원청 단위에서 3년간 누적 133건(89+44)의 일상감사 절차 위반은 시스템적 결함 수준입니다. 단순 담당자 실수가 아니라 결재라인의 묵인이 동반된 결과입니다.",
    "교육지원청 단위에서 3년간 89건 미의뢰·44건 회신 전 집행(중복 여부 원문 미기재)은 반복된 절차 위반입니다." ],
  [ "goe-2021-daily-audit-89-cases", "detail",
    "89건 누적은 매년 30건 이상의 사업이 일상감사 우회로 신규 추진됐음을 의미하며,",
    "89건은 3년간 연평균 약 30건의 사업이 일상감사 없이 집행됐다는 뜻이며," ],
  [ "goe-2021-daily-audit-89-cases", "detail",
    "결재라인 묵인이 동반된 시스템적 결함은 단순 담당자 처분으로 끝나지 않으며, 부서장·기관장 동시 처분 + 기관 단위 가장 무거운 처분으로 귀결됩니다.",
    "원문 처분은 «기관경고»입니다(담당자 개인 처분은 원문에 없음)." ],

  # ── g2 P1 · 2단계 입찰: «6억원 초과 학교운영위 사전 심의» 근거 없음 · 시행령 제18조 문구 ──
  [ "goe-2021-contract-method-2stage-bidding", "lesson",
    "- 기술 평가가 가격보다 중요한 사업",
    "- 그 밖에 계약의 특성상 필요하다고 인정되는 경우(지방계약법 시행령 제18조)" ],
  [ "goe-2021-contract-method-2stage-bidding", "lesson",
    "- [ ] 2단계 입찰 적용 시 사전 감사관실 협의를 거쳤는가?\n- [ ] 6억원 초과 계약은 학교운영위 사전 심의를 거쳤는가?",
    "- [ ] (원문 외 실무 권고) 2단계 입찰 적용 사유를 결재 문서에 남겼는가?\n- [ ] (원문 외) 소속 교육청의 학교 계약 심의 기준을 별도로 확인했는가?" ],
  [ "goe-2021-contract-method-2stage-bidding", "lesson",
    "3. **\"입찰방식 자체 결정\"** — 사전 감사관실 협의 권장",
    "3. **\"입찰방식 자체 결정\"** — 적용 사유 결재 보존(원문 외 실무 권고)" ],
  [ "goe-2021-contract-method-2stage-bidding", "lesson",
    "6.44억원 단일 계약이 위 흐름으로 결정되면 사후 감사에서 의도성 입증 사례로 거의 확정적으로 분류됩니다.",
    "원문은 이 건의 의도성을 판단하지 않았습니다(원문 처분 «관련자 주의»). 위 흐름은 원문 외 해설입니다." ],
  [ "goe-2021-contract-method-2stage-bidding", "lesson",
    "### 6억원 초과 계약 학교운영위 사전 심의\n\n6억원 초과 계약은 학교운영위 사전 심의 대상입니다. 다음을 결재 보존하세요.",
    "### 입찰방식 결정 근거 결재 보존\n\n«6억원 초과 계약 = 학교운영위 사전 심의» 기준은 원문·법령에서 확인되지 않습니다. 금액별 심의 대상은 소속 교육청 기준을 따로 확인하고, 다음을 결재 보존하세요(원문 외 실무 권고)." ],
  [ "goe-2021-contract-method-2stage-bidding", "lesson",
    "### 2단계 입찰 적용 시 사전 감사관실 협의\n\n2단계 입찰 적용이 필요한 사업이라도 사전에 감사관실 협의를 거치세요. 협의 결재 자료는 사후 감사 시 본인 보호 자료가 됩니다. 협의 없이 자체 결정 후 부적정 사례로 적발되면 처분이 무거워집니다.",
    "### 2단계 입찰 적용 사유 기록(원문 외 실무 권고)\n\n2단계 입찰을 적용하려면 시행령 제18조 사유(미리 적절한 규격 등을 작성하기 곤란하거나 계약의 특성상 필요)와 단순 노무용역 제외 여부를 결재 문서에 남기세요. 사전 감사관실 협의는 원문·법령상 의무가 아닙니다." ],

  # ── g2 P1 · 카드대금 계좌: 연도 창작 · 회계연도 독립 위반(원문 외) · 분기 1회(원문 외) ──
  [ "goe-2021-credit-card-payment-account", "detail",
    "2024.3월~2025.5월 동안 법인카드 사용 후 결제대금 미입금 → 15건 2,287,816원 불부합 누적 → 2025.5월에 학교회계에서 일괄 지출처리 (회계연도 독립 추가 위반)",
    "20××년 3월부터 14개월간 법인카드 사용 후 결제대금 미입금 → 15건 2,287,816원 불부합 누적 → 14개월째(5월)에 학교회계에서 지출처리" ],
  [ "goe-2021-credit-card-payment-account", "detail",
    "14개월 미입금 누적은 회계연도 독립 원칙까지 추가 위반(차년도 회계로 소급 처리)을 발생시킵니다.",
    "14개월 미입금 누적은 결제대금 불부합을 쌓아 회계 통제를 무너뜨립니다(원문은 회계연도 독립 위반으로 지적하지 않음)." ],
  [ "goe-2021-credit-card-payment-account", "detail",
    "| 잔액 원인 추적 | 분기 1회 이상 점검 | 감사 당일까지 미파악 |",
    "| 잔액 원인 추적 | 불일치 발견 시 원인 점검 | 감사 당일까지 미파악 |" ],
  [ "goe-2021-credit-card-payment-account", "lesson",
    "- **분기 1회 이상 대조**: 카드 사용 누계 vs 학교회계 지출 누계",
    "- **정기 대조(실무 권고 · 원문 외)**: 카드 사용 누계 vs 학교회계 지출 누계" ],
  [ "goe-2021-credit-card-payment-account", "lesson",
    "- [ ] 분기 1회 카드 사용 누계 vs 학교회계 지출 누계를 대조하는가?",
    "- [ ] 카드 사용 누계와 학교회계 지출 누계를 정기적으로 대조하는가?" ],
  [ "goe-2021-credit-card-payment-account", "lesson",
    "### 회계연도 독립 추가 위반\n\n카드대금 14개월 미입금 후 차년도 학교회계 일괄 지출처리는 회계연도 독립 원칙 추가 위반에 해당합니다.",
    "### 회계연도 구분 유의(해석 · 원문 외)\n\n원문은 이 건을 회계연도 독립 위반으로 지적하지 않았습니다(원문 지적 = 카드대금 미입금·불부합 누적)." ],

  # ── g2 P1 · 명시이월: 사고이월 «사후 운영위 보고»·«1학기 내 집행»·«2년 연속» = 원문·규칙 외 ──
  [ "goe-2021-explicit-carryover-violation", "lesson",
    "| 사전 심의 | 사전 학교운영위 심의 | 사후 학교운영위 보고 |",
    "| 사전 심의 | 사전 학교운영위 심의 | 심의 요건 없음(지출원인행위 후 불가피한 사유 · 경기도 공립학교회계 규칙 제19조②) |" ],
  [ "goe-2021-explicit-carryover-violation", "lesson",
    "명시이월이 사전 심의 사항이라면, 사고이월은 회계연도 종료 직전 발생한 불가피 사유에 대한 사후 보고 사항입니다.",
    "명시이월이 사전 심의 사항이라면, 사고이월은 연도 내에 지출원인행위를 하고 불가피한 사유로 지출하지 못한 경비를 넘기는 것입니다(경기도 공립학교회계 규칙 제19조②)." ],
  [ "goe-2021-explicit-carryover-violation", "lesson",
    "- 명시이월 사업은 차년도 1학기 내 집행이 원칙\n- 차년도 미사용 시 학교운영위에 사유 보고\n- 2년 연속 이월은 사실상 예산 운영 부적정",
    "- 명시이월 사업은 차년도에 조기 집행(실무 권고 · 원문·규칙에 기한 없음)\n- 차년도 미사용 시 학교운영위에 사유 보고(실무 권고)\n- 이월이 반복되지 않도록 점검(실무 권고)" ],

  # ── g5 P1 · 세입세출외현금 횡령: 행정7급 = 지방공무원 → 지방공무원법 징계 조문 ─────
  [ "goe-2021-suspense-cash-embezzlement", "lesson",
    "| 국가공무원법 §82·83 (징계) | 강등·해임·파면 등 |",
    "| 지방공무원법 §69·§70·§71 (징계 사유·종류·효력) | 강등·해임·파면 등 |" ],
  [ "goe-2021-suspense-cash-embezzlement", "detail",
    "1인 결재 + 사후결재 허용이 시스템 결함의 직접 원인이 된 중대 사례입니다.",
    "원문은 이 건의 결재 방식(1인 결재·사후결재)을 적시하지 않았습니다 — 아래 결재 구조 분석은 재구성 해설입니다." ],

  # ── g5 P1 · 세입세출외현금 관리(공·사립 혼재): 사비 대납 «가중 처벌»은 원문 외 ────────
  [ "goe-2021-suspense-cash-management", "lesson",
    "5. **\"4대보험 연체료 사비 대납\"** — 정상 회계 외 거래로 가중 처벌",
    "5. **\"4대보험 연체료 사비 대납\"** — 원문은 관리 부적정 사례로 지적(가중 처벌 언급 없음)" ],
  [ "goe-2021-suspense-cash-management", "lesson",
    "사비 대납은 횡령·은폐 의혹을 동반하며, 징수권 행사 의무 회피라는 추가 위반에 해당합니다.",
    "원문은 급여담당자의 개인비용 대납을 세입세출외현금 관리 부적정 사례로 지적했습니다(가중 처벌 언급 없음)." ],
  [ "goe-2021-suspense-cash-management", "lesson",
    "### 사비 대납의 가중 처벌\n\n\"지출담당자가 사비로 메꿨다\"는 처리는 면책 사유가 아니라 가중 처벌 사유입니다.",
    "### 사비 대납은 면책 사유가 아님\n\n\"지출담당자가 사비로 메꿨다\"는 처리는 면책 사유가 아닙니다(원문은 가중 처벌을 언급하지 않음)." ],
  [ "goe-2021-suspense-cash-management", "detail",
    "4대보험 연체료 개인 대납은 징수권 행사 의무 회피라는 추가 위반에 해당합니다.",
    "4대보험 연체료 개인 대납도 원문에서 관리 부적정 사례로 지적됐습니다." ],
  [ "goe-2021-suspense-cash-management", "detail",
    "4대보험 연체료 개인 대납은 추가 위반(징수권 행사 의무 회피)이며, 정상 회계 외 거래로 분류돼 처분이 가중됩니다.",
    "4대보험 연체료 개인 대납도 원문에서 관리 부적정으로 지적됐습니다(가중 처벌 언급 없음)." ],

  # ── g5 P0 · 세입세출외현금 1인 결재(교육지원청): «약 2년·재이관 포함»은 원문 외 ───────
  [ "goe-2021-suspense-cash-single-approval", "detail",
    "누적 처리 건수: 감사대상 약 2년간 357건 (반환·재이관 포함)",
    "누적 처리 건수: 감사대상 기간 중 세입세출외현금 반환 357건" ],

  # ── g5 P1 · 신분변동자 보수: 원문 지적·처분 분리, 육아휴직수당 현행 개정 ─────────────
  [ "goe-2021-suspension-pay-deduction", "issue",
    "정직 처분을 받은 자에게 보수 전액을 감액하지 않고 일부만 감액한 사례, 신규채용·승진 등 임용 시 발령일 기준 월액 일할계산을 적용하지 않은 사례,",
    "정직2월 처분을 받은 교사에게 보수감액률 착오로 정직기간 보수 3,553,730원을 과다지급한 사례, 육아휴직·복직자의 일할 계산 착오 사례(발령일 기준 일할계산 원칙: 공무원보수규정 제22조①)," ],
  [ "goe-2021-suspension-pay-deduction", "detail",
    "1. 정직 보수 전액 감액 미적용\n2. 발령일 기준 일할계산 미적용",
    "1. 정직 보수감액률 착오(정직기간 보수는 전액 감액)\n2. 육아휴직·복직자 일할계산 착오(발령일 기준 일할계산)" ],
  [ "goe-2021-suspension-pay-deduction", "detail",
    "4. 육아휴직수당 합산금(15%·복직 7개월째 일시불) 누락",
    "4. 육아휴직 복직합산금 과오지급(2021 기준 15%·복직 7개월째 일시불 — 현행 「공무원수당 등에 관한 규정」 제11조의3은 개정되어 사후지급분 삭제)" ],
  [ "goe-2021-suspension-pay-deduction", "detail",
    "사례집 원문 처분: «관련자 주의, 과소지급액 추가지급 및 과다지급액 회수» (경기도교육청 감사사례집, 2021)",
    "사례집 원문 처분: «현지조치, 과다지급액 회수»(정직 보수 과다지급 건 등), «관련자 주의, 과소지급액 추가지급 및 과다지급액 회수»(○○고 4명 건 등) (경기도교육청 감사사례집, 2021)" ],

  # ── g5 P0 · 가설건축물: 새 간선 공급설비 = 허가 요건 불충족(별도 허가 아님) · 감독청 ───
  [ "goe-2021-temporary-building-violation", "lesson",
    "- **건축법 §20**: 감독청(시·군·구청장) 허가·신고\n- **학교시설사업 촉진법 §5의2 ①**: 학교 가설건축물 승인",
    "- **건축법 §20**: 가설건축물 허가·신고 (허가권자 시장·군수·구청장)\n- **학교시설사업 촉진법 §5의2**: 학교시설 건축등은 감독청(교육청) 승인·신고(①), 가설건축물 허가 등도 감독청이 함(⑥)" ],
  [ "goe-2021-temporary-building-violation", "lesson",
    "| 간선 공급설비 | 신규 설치 시 별도 허가 | 무허가 연결 |",
    "| 간선 공급설비 | 새로운 간선 공급설비가 필요 없을 것 | 전기·수도·가스 새 간선 설치 필요 시 허가 요건 불충족(시행령 §15①3) |" ],
  [ "goe-2021-temporary-building-violation", "lesson",
    "- [ ] 전기·수도 등 간선 공급설비 연결 시 별도 허가를 받았는가?",
    "- [ ] 전기·수도·가스 등 새로운 간선 공급설비 설치가 필요 없는 구조인가?(필요하면 가설건축물 허가 요건 불충족)" ],
  [ "goe-2021-temporary-building-violation", "lesson",
    "3. **\"전기·수도 연결은 별개\"** — 신규 간선 공급설비 별도 허가",
    "3. **\"전기·수도 연결은 별개\"** — 새로운 간선 공급설비가 필요하면 가설건축물 허가 자체가 제한" ],
  [ "goe-2021-temporary-building-violation", "lesson",
    "### 전기·수도 연결 시 별도 허가\n\n가설건축물에 전기·수도·가스 등 새로운 간선 공급설비를 설치하려면 별도 허가가 필요합니다.",
    "### 전기·수도 연결과 가설건축물 요건\n\n전기·수도·가스 등 새로운 간선 공급설비의 설치가 필요한 건축물은 가설건축물 허가 기준을 충족하지 못합니다(건축법 시행령 §15①3)." ],
  [ "goe-2021-temporary-building-violation", "detail",
    "  - 축조 시기 불명 (5년 이상 추정)\n- 누적 가설건축물: 약 30~40개동 추정\n",
    "  - 축조 시기: 알 수 없음(원문)\n" ],
  [ "goe-2021-temporary-building-violation", "detail",
    "| 전기·수도 연결 | 별도 허가 + 간선 공급설비 신고 | 무허가 연결 |",
    "| 전기·수도 연결 | 새로운 간선 공급설비가 필요하면 가설건축물 허가 제한 | 전기·수도 연결 |" ],
  [ "goe-2021-temporary-building-violation", "detail",
    "가설건축물 축조는 「건축법」상 감독청(시·군·구청장) 허가·신고와 「학교시설사업 촉진법」상 학교 가설건축물 승인 대상입니다.",
    "가설건축물 축조는 「건축법」 제20조의 허가·신고 대상이며, 학교시설은 「학교시설사업 촉진법」 제5조의2⑥에 따라 감독청(교육청)이 그 허가 등을 합니다." ],
  [ "goe-2021-temporary-building-violation", "detail",
    "전기·수도가 연결된 사례는 별도 허가가 필요하므로 본격 시설로 분류되며, 사후 적발 시 처분이 무거워집니다.",
    "전기·수도 등 새로운 간선 공급설비가 필요한 시설은 가설건축물 허가 요건(건축법 시행령 §15①3)을 충족하지 못합니다." ],

  # ── g5 P1 · 공용차량(직속기관+고): 규칙 현행 명칭 · «30km 기준»·행정실장 징계는 원문 외 ──
  [ "goe-2021-vehicle-management-failure", "legal_basis",
    "경기도교육비특별회계 소관 공용차량 관리 규칙",
    "경기도교육비특별회계 소관 공무용 차량 관리 규칙(2021 사례집 당시 명칭: 공용차량 관리 규칙)" ],
  [ "goe-2021-vehicle-management-failure", "lesson",
    "- [ ] 운행거리 차이가 30km 이상 발생 시 사유서가 첨부됐는가?",
    "- [ ] 목적지 대비 운행거리 차이에 경유지·사유가 기재됐는가?(원문 사례 30~195km 차이 · 30km는 기준 아님)" ],
  [ "goe-2021-vehicle-management-failure", "lesson",
    "3. **\"운행일지는 형식적\"** — 30km 이상 차이는 사적 용도 의혹",
    "3. **\"운행일지는 형식적\"** — 경유지 미기입이면 운행거리 검증 불가(원문 사례 30~195km 차이)" ],
  [ "goe-2021-vehicle-management-failure", "lesson",
    "### 운행거리 차이 30km 초과 시 대응",
    "### 운행거리 차이 발생 시 대응" ],
  [ "goe-2021-vehicle-management-failure", "lesson",
    "운행일지의 목적지 대비 운행거리 차이가 30km 이상이면 다음 중 하나입니다.",
    "운행일지의 목적지 대비 운행거리 차이가 크면(원문 사례 30~195km · 30km는 기준 아님) 다음 중 하나입니다." ],
  [ "goe-2021-vehicle-management-failure", "lesson",
    "차이가 30km 이상이면 즉시 사유서를 첨부하고,",
    "차이가 생기면 경유지·사유를 기재하고(실무 권고)," ],
  [ "goe-2021-vehicle-management-failure", "detail",
    "운행일지에 목적지 대비 운행거리 차이가 30km 이상이면 경유지 누락 또는 사적 용도 가능성을 의미하며,",
    "원문 사례는 목적지 대비 운행거리가 30~195km 차이 나고 경유지가 없어 실제 운행거리를 검증할 수 없었으며(30km는 기준 아님)," ],
  [ "goe-2021-vehicle-management-failure", "detail",
    "운행일지의 운행거리 차이가 30km 이상이면 경유지 누락이거나 사적 용도 가능성을 의미하며,",
    "운행일지에 경유지를 적지 않으면 목적지 대비 운행거리 차이(원문 사례 30~195km)를 검증할 수 없으며," ],
  [ "goe-2021-vehicle-management-failure", "detail",
    "사후 적발 시 행정실장 본인이 견책 이상 징계 + 변상 책임 동시 대상이 될 수 있습니다.",
    "원문 처분은 «관련자 주의»입니다." ],
  [ "goe-2021-vehicle-management-failure", "detail",
    "현행 법령 기준일: 경기도교육비특별회계 소관 공용차량 관리 규칙 최신본.",
    "현행 법령 기준일: 경기도교육비특별회계 소관 공무용 차량 관리 규칙(2021 당시 공용차량 관리 규칙) 최신본." ]
].freeze

slugs = (agency.keys + source_page.keys + edits.map(&:first)).uniq
dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  slugs.each do |slug|
    ac = AuditCase.find_by(slug: slug)
    raise "[audit-truth-g1] missing AuditCase: #{slug}" unless ac

    to_write = {}
    %w[issue lesson detail legal_basis].each do |field|
      original = ac.read_attribute(field).to_s
      value = original
      edits.select { |s, f, _, _| s == slug && f == field }.each do |_, _, old, new|
        # 이미 적용됨: new 가 있고 old 가 없거나, new 가 old 를 품는 덧붙임형 edit
        next if value.include?(new) && (!value.include?(old) || new.include?(old))
        raise "[audit-truth-g1] fingerprint missing: #{slug}/#{field}: #{old[0, 40]}" unless value.scan(old).size == 1

        value = value.sub(old) { new }
        changes += 1
      end
      to_write[field] = value unless value == original
    end

    if (target = agency[slug])
      current = [ Array(ac.target_agency), ac.agency_scope_confidence ]
      # 목표가 [] 인데 이미 비어 있으면(운영 «적용 대상» 미표시 — budget-formation·suspense-cash-management) confidence 만 맞춘다.
      already_hidden = target[0].empty? && current[0].empty?
      unless current == target
        raise "[audit-truth-g1] agency fingerprint mismatch: #{slug} #{current.inspect}" unless current == PUBLIC || already_hidden

        to_write["target_agency"] = target[0]
        to_write["agency_scope_confidence"] = target[1]
        changes += 1
      end
    end

    if (pages = source_page[slug])
      old_page, new_page = pages
      unless ac.source_page == new_page
        raise "[audit-truth-g1] source_page mismatch: #{slug} #{ac.source_page}" unless ac.source_page == old_page

        to_write["source_page"] = new_page
        src = (ac.source || {}).deep_stringify_keys
        to_write["source"] = src.merge("page" => new_page) if src["page"] == old_page
        changes += 1
      end
    end
    next if to_write.empty?

    puts "  [audit-truth-g1] AuditCase/#{slug} fields_to_change=#{to_write.keys.join(',')}"
    ac.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end
puts "  [audit-truth-g1] #{"DRY_RUN " if dry}changes=#{changes}"
