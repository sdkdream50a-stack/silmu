# 감사사례 P2/P3 정정 — 경기도교육청 2021 감사사례집 재구성 사례 goe batch (2026-09-29)
#
# 입력: tasks/silmu-audit-case-p2p3-closure-0929/sources/p2p3_verdict_blocks.md 의 goe-2021-* P2/P3 블록 FIX(원문 PDF 인용)만.
#   원문 외 단정·창작 수치·징계/형사/무효 확대 서술 축소 · 법령 귀속(지방계약법 → 재무회계 규칙 §68①) · 법령명 현행 표기
#   · 페이지 내부 불일치 수치(1,131만원 ↔ 11,613,360원) · 위키 마크업([[slug]]) 노출 제거 · 적용 대상 혼재 4건 [] + LOW.
#   적용하지 않음: action_taken · topic_slug · source_page · slug/title/view_count · «(선택)»·«검토» FIX · FIX 없음 3건
#   (development-fund-misuse · supplies-selection-committee · travel-expense-improper).
#
# 원문: 경기도교육청 감사사례집 2021 (인쇄쪽 = PDF쪽 − 6).
# 현행 법령(블록 인용): 경기도 공립학교회계 규칙 §13①·§21(2024-12-19 개정)·§34 · 경기도교육비특별회계 재무회계 규칙 §68①
#   · 공유재산 및 물품 관리법 시행령 §6·§78③ · 지방계약법 시행령 §19③·§26③ · 초ㆍ중등교육법 시행령 §64⑤⑧
#   · 공무원수당 등에 관한 규정·지방공무원 수당 등에 관한 규정 §18의5
#
# old 는 운영 페이지(https://silmu.kr/audit-cases/<slug>, 2026-09-29 익명 GET)의 렌더 문자열과 같다(마크다운 기호 제외).
# edits 는 필드에 old 가 정확히 1회 있어야 바꾼다. 이미 new 면 건너뛴다. 하나라도 어긋나면 전체 롤백.
# agency 는 target_agency=["PUBLIC_SCHOOL"]·HIGH 일 때만 바꾼다(운영 «적용 대상: 공립학교»). 기관 혼재 = [] + LOW(표시 안 함).
#   ⚠ `silmu:p1:agency_backfill`(수동 rake)을 다시 돌리면 이 사례들을 PUBLIC_SCHOOL 로 되돌린다.
# DRY_RUN=1 이면 레코드별 fields_to_change 만 출력한다. view_count·slug·title 불변.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929120000_audit_truth_p2p3_goe.rb})"'
#   → 기대: changes=75 (문장 71 · agency 4; 운영에서 이미 []·LOW 인 agency 가 있으면 그만큼 적음) · 두 번째 실행 changes=0
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화)
# 롤백: edits 는 new → old 역적용, agency 는 ["PUBLIC_SCHOOL"]·HIGH.

PUBLIC = [ [ "PUBLIC_SCHOOL" ], "HIGH" ].freeze
agency = {
  "goe-2021-budget-transfer-violation"     => [ [], "LOW" ], # 이사회 의결 소사례 = 사립
  "goe-2021-business-promotion-improper"   => [ [], "LOW" ], # 교육청 직속기관 소사례
  "goe-2021-contract-review-omission"      => [ [], "LOW" ], # 교육지원청 일상감사 사례
  "goe-2021-instructor-allowance-improper" => [ [], "LOW" ]  # 교육지원청·직속기관·사학 지침
}.freeze

sponsor = "경기도 공립학교회계 규칙 §21, 2024-12-19 개정"

edits = [
  # ── accounting-disorder-construction (P3) ─────────────────────────────
  [ "goe-2021-accounting-disorder-construction", "detail",
    "청구 익일 지급은 검사·검수 절차가 실질적으로 부재했음을 의미하며,",
    "청구 익일 지급은 검사·검수 절차가 확인되지 않는 시간 간격이며," ],
  [ "goe-2021-accounting-disorder-construction", "lesson",
    "청구 익일 지급은 검사 절차가 실질적으로 부재했음을 의미합니다.",
    "청구 익일 지급은 검사·검수 절차가 확인되지 않는 시간 간격입니다." ],
  [ "goe-2021-accounting-disorder-construction", "lesson",
    "완료된 사업에 추가 물품계약이 발주되면 분할 의혹이 자동으로 발생합니다.",
    "완료된 사업에 추가 물품계약이 발주되면 분할 의혹을 받을 수 있습니다(원문은 추가 물품계약 사실만 지적)." ],
  [ "goe-2021-accounting-disorder-construction", "detail",
    "현행 법령 기준일: 지방계약법 2024-04-25 시행본,",
    "현행 법령 기준일: 지방계약법 2024-02-17 시행본," ],

  # ── annual-leave-compensation-mispayment (P2) ─────────────────────────
  [ "goe-2021-annual-leave-compensation-mispayment", "detail",
    "「2021 감사사례집」(p.129)",
    "「2021 감사사례집」(p.130)" ],
  [ "goe-2021-annual-leave-compensation-mispayment", "lesson",
    "| 근거 법령 | 「공무원수당 등에 관한 규정」 §18의5 |",
    "| 근거 법령 | 「공무원수당 등에 관한 규정」·「지방공무원 수당 등에 관한 규정」 §18의5 (교육공무원 제외 단서 확인) |" ],
  [ "goe-2021-annual-leave-compensation-mispayment", "detail",
    "- 합계 과오지급 규모: 약 1,490만원 (3개 사례)",
    "- 사례 ③ 한 건(○○중 3년): 과소지급 2,038,750원 + 과다·근거없는 지급 12,865,810원" ],
  [ "goe-2021-annual-leave-compensation-mispayment", "detail",
    "사례 ③처럼 3년간 1,490만원 규모의 과오지급이 누적될 수 있습니다.",
    "사례 ③ 한 건(○○중 3년)처럼 과소지급 2,038,750원 + 과다·근거없는 지급 12,865,810원의 과오지급이 누적될 수 있습니다." ],

  # ── bad-debt-write-off-violation (P3) ────────────────────────────────
  [ "goe-2021-bad-debt-write-off-violation", "lesson",
    "따라서 학교운영비·수업료·급식비 등은 1년 시효에 해당합니다.",
    "원문은 학교운영비·수업료 미수납액을 «교육비» 채권(1년 시효)으로 봅니다(급식비 등 개별 항목 시효는 원문에 없음)." ],
  [ "goe-2021-bad-debt-write-off-violation", "detail",
    "처리 시점: 미수납 발생 후 약 6개월 (시효 만료 전)",
    "처리 시점: 회계연도 이월 후 시효 만료 전" ],

  # ── beneficiary-cost-settlement (P2) ─────────────────────────────────
  [ "goe-2021-beneficiary-cost-settlement", "lesson",
    "### 정산·공개 절차 (사업 종료 10일 이내)",
    "### 정산·공개 절차 (사업 종료 후 10일 이내 정산, 정산 후 10일 이내 정산내역 공개 — #{sponsor})" ],
  [ "goe-2021-beneficiary-cost-settlement", "detail",
    "첫째, 사업 종료 후 10일 이내 정산내역을 학부모에게 공개해야 하며,",
    "첫째, 사업 종료 후 10일 이내 정산하고 정산 후 10일 이내 정산내역을 학부모에게 공개해야 하며(#{sponsor})," ],
  [ "goe-2021-beneficiary-cost-settlement", "detail",
    "| 정산 기한 | 사업 종료 10일 이내 |",
    "| 정산 기한 | 사업 종료 후 10일 이내 정산, 정산 후 10일 이내 정산내역 공개(#{sponsor}) |" ],
  [ "goe-2021-beneficiary-cost-settlement", "detail",
    "| 학교운영위 보고 | 정산 결과 사후 보고 |",
    "| 학교운영위 보고(권장) | 정산 결과 사후 보고(원문·규칙 외 권장) |" ],
  [ "goe-2021-beneficiary-cost-settlement", "lesson",
    "4. **학교운영위 보고**: 정산 결과 사후 보고",
    "4. **학교운영위 보고(권장)**: 정산 결과 사후 보고(원문·규칙 외 권장)" ],
  [ "goe-2021-beneficiary-cost-settlement", "lesson",
    "- [ ] 학교운영위에 정산 결과를 사후 보고했는가?",
    "- [ ] (권장) 학교운영위에 정산 결과를 사후 보고했는가?" ],
  [ "goe-2021-beneficiary-cost-settlement", "lesson",
    "정산 결과 사후 보고도 학교운영위의 감독 권한이며, 보고 누락은 학교운영위의 법적 권한을 우회하는 결과로 이어져 학부모·지역사회 신뢰를 훼손합니다.",
    "정산 결과의 학교운영위 사후 보고는 원문·규칙에 없는 권장 사항입니다." ],

  # ── budget-account-mixed-execution (P3) ──────────────────────────────
  [ "goe-2021-budget-account-mixed-execution", "detail",
    "- **패턴 ④ 회계연도 종료 후 소급 지출**: 프린터·노트북·의자 등 16,236,180원을 회계연도 종료 후 소급 처리",
    "- **패턴 ④ ○○중: 회계연도 종료 후 소급 지출 및 비목 부적합 자산취득성 물품 구입 등**: 총 11건 16,236,180원(원문은 두 유형 합산)" ],
  [ "goe-2021-budget-account-mixed-execution", "detail",
    "누적 부적정 집행 규모 약 2,260만원에 이르렀습니다.",
    "원문에 금액이 명시된 2건 합계는 약 2,264만원입니다(나머지 3건은 금액 미기재)." ],

  # ── budget-transfer-violation (P2) ───────────────────────────────────
  [ "goe-2021-budget-transfer-violation", "lesson",
    "학교운영위 회의 소집 가능 여부 (통상 14일 전 안건 통지)",
    "학교운영위 회의 소집 가능 여부 (학교운영위원회 예산안 통지 = 회의 7일 전까지, 경기도 공립학교회계 규칙 §13①)" ],
  [ "goe-2021-budget-transfer-violation", "lesson",
    "- **사안 시급성 미검증**: 객관적 사유 부재\n\n추경 예정일 14일 이내 전용은 거의 모두 의도성 입증 사례로 분류됩니다.",
    "- **사안 시급성 미검증**: 객관적 사유 부재" ],
  [ "goe-2021-budget-transfer-violation", "lesson",
    "행정실장의 직접 책임입니다. 절차 위반 다수 발생 시 견책 이상 처분 + 변상 책임 동시 대상이 될 수 있으며, 학교운영위 권한 우회 시 처분이 무거워집니다.",
    "행정실장의 직접 책임입니다." ],

  # ── building-registration-delay (P3) ─────────────────────────────────
  [ "goe-2021-building-registration-delay", "lesson",
    "### 60일 카운트다운 시작점\n\n- **준공검사 완료일**: 신축·증축 시설",
    "### 60일 기산점\n\n60일 기산점 = 공유재산이 해당 지방자치단체 소관에 속하게 된 날(공유재산 및 물품 관리법 시행령 §6). 원문 사례는 준공검사 완료 기준으로 지적했습니다.\n\n- **준공검사 완료일**: 신축·증축 시설" ],

  # ── business-promotion-improper (P2) ─────────────────────────────────
  [ "goe-2021-business-promotion-improper", "detail",
    "6. **클린카드 우선** — 현금지출은 학교장 책임 하에 카드 사용 불가 지역에 한정",
    "6. **현금 선집행 지적** — 현금지출이 불가피한 경우가 아님에도 접대성 경비·다과비를 현금 선집행 후 영수증 환급한 방식이 지적됨(원문 지적사항)" ],
  [ "goe-2021-business-promotion-improper", "lesson",
    "단일 행사 아닌 누적 집행 — 매년 반복 시 적발 누적 규모 폭증. \"현금 선집행 후 영수증 환급\" 패턴은 업무추진비 회피 + 횡령 직전 단계로 가장 위험한 패턴.",
    "단일 행사 아닌 누적 집행. \"현금 선집행 후 영수증 환급\" 패턴은 업무추진비 회피 패턴(원문 지적사항)." ],

  # ── clothing-expense-improper (P3) ───────────────────────────────────
  [ "goe-2021-clothing-expense-improper", "detail",
    "- 누적 부적정 집행: 약 1,840만원 (가상)\n- 결재선:",
    "- 결재선:" ],
  [ "goe-2021-clothing-expense-improper", "lesson",
    "- 시·도 교육청 무기계약근로자 관리 규정 적용\n- 결재 문서에",
    "- 결재 문서에" ],

  # ── condolence-money-improper (P3) ───────────────────────────────────
  [ "goe-2021-condolence-money-improper", "lesson",
    "목사·전임위원장·교직원 가족(직계 외)에 지급하는 순간 부정청탁법까지 적용 가능. 5만원 한도 초과는 1건당이므로 분할 지급으로 회피 시도도 위반.",
    "원문 지침: 1건당 5만원 초과 불가." ],

  # ── contract-review-omission (P2) ────────────────────────────────────
  [ "goe-2021-contract-review-omission", "lesson",
    "자체 원가 검토 절차를 갖춰야 하며, 일상감사는 적용되지 않지만 자체 감사 체계를 운영해야 합니다.",
    "자체 원가 검토 절차를 갖춰야 하며, 일상감사는 적용되지 않지만 자체 감사 체계를 운영해야 합니다(원문 외 실무 의견)." ],
  [ "goe-2021-contract-review-omission", "lesson",
    "변명은 통하지 않으며, 누적 누락 시 견책 이상 처분 + 변상 책임 동시 대상이 될 수 있습니다.",
    "변명은 통하지 않습니다(원문 처분: 관련자 주의)." ],

  # ── credit-card-usage-improper (P3) ──────────────────────────────────
  [ "goe-2021-credit-card-usage-improper", "lesson",
    "5. **학교운영위 보고**: 분기·연간 결산에 포함",
    "5. **학교운영위 보고(실무 권고 — 원문 외)**: 분기·연간 결산에 포함" ],

  # ── development-fund-handover (P3) ───────────────────────────────────
  [ "goe-2021-development-fund-handover", "lesson",
    "인계인수자·인수자 + 입회자(통상 행정실장) 3인 서명·날인",
    "인계인수자·인수자 + 입회자 3인 서명·날인" ],
  [ "goe-2021-development-fund-handover", "detail",
    "| 학교운영위 보고 | 인계인수 결과 사후 보고 |",
    "| 학교운영위 보고(원문 외) | 인계인수 결과 사후 보고 |" ],

  # ── development-fund-misclassified (P3) ──────────────────────────────
  [ "goe-2021-development-fund-misclassified", "lesson",
    "| 법적 근거 | 초·중등교육법 + 시·도 회계관리요령 | 지방회계법 + 회계관리에 관한 규칙 |",
    "| 법적 근거 | 초·중등교육법 + 시·도 회계관리요령 | (원문 근거 미제시) |" ],
  [ "goe-2021-development-fund-misclassified", "lesson",
    "| 결산 | 분기·연간 결산 공시 |",
    "| 결산 | 분기별 집행내역 서면 보고(시행령 제64조⑤)·결산 후 학부모 통지(⑧) |" ],
  [ "goe-2021-development-fund-misclassified", "lesson",
    "- [ ] 분기 결산 공시(수입·지출·잔액)를 했는가?",
    "- [ ] 분기별 집행내역 서면 보고(시행령 제64조⑤)와 결산 후 학부모 통지(⑧)를 했는가?" ],
  [ "goe-2021-development-fund-misclassified", "lesson",
    "시설 대관 보증금, 학교운영위 회비 일시 보관 |",
    "시설 대관 보증금 |" ],

  # ── disposal-procedure-violation (P2) ────────────────────────────────
  [ "goe-2021-disposal-procedure-violation", "lesson",
    "| **수의계약·경매** (예외 ②) | 처분단가 500만원 이하 + 처분총액 1천만원 이하의 불용농기계를 해당 자치단체 거주 농업인에게 매각 |",
    "| **수의계약·경매** (예외 ②) | 처분단가 500만원 이하 + 처분총액 1천만원 이하의 불용농기계를 해당 자치단체 거주 농업인에게 매각 |\n| **일반입찰 예외** (③) | 국가나 다른 지방자치단체에 매각하는 경우 (공유재산 및 물품 관리법 시행령 제78조③ 현행) |" ],
  [ "goe-2021-disposal-procedure-violation", "lesson",
    "위 두 예외에 해당하지 않으면 **반드시 일반입찰**입니다.",
    "위 예외 ①·② + ③ 국가나 다른 지방자치단체에 매각하는 경우(시행령 제78조③ 현행)에 해당하지 않으면 **일반입찰**입니다." ],
  [ "goe-2021-disposal-procedure-violation", "lesson",
    "4. 입찰 공고 (최소 1주일)",
    "4. 입찰 공고 (공고 기간 «최소 1주일»은 원문 외 실무 예시)" ],
  [ "goe-2021-disposal-procedure-violation", "detail",
    "| 입찰 공고 | 최소 1주일 공고 |",
    "| 입찰 공고 | 입찰 공고(«최소 1주일»은 원문 외) |" ],

  # ── failed-bid-private-contract (P3) ─────────────────────────────────
  [ "goe-2021-failed-bid-private-contract", "detail",
    "또한 행안부 예규 「지방자치단체 입찰 및 계약 집행기준」은 유찰 후 수의계약 시 최초 입찰 조건(가격·자격·기간 등)을 변경하지 못하도록 명시합니다.",
    "또한 지방계약법 시행령 제19조③·제26조③은 재공고입찰·수의계약 시 최초 입찰 조건(보증금·기한 제외)을 변경하지 못하도록 규정합니다." ],
  [ "goe-2021-failed-bid-private-contract", "detail",
    "- 결재선: 행정실장 → 교감 → 교장\n- 발견 경위: 학부모회 정보공개 요청 → 절차 부재 확인",
    "- 결재선: 행정실장 → 교감 → 교장" ],
  [ "goe-2021-failed-bid-private-contract", "detail",
    "가격·조건을 변경하면 수의계약 자체가 무효가 됩니다.",
    "가격·조건을 변경하면 부적정 수의계약이 됩니다." ],
  [ "goe-2021-failed-bid-private-contract", "lesson",
    "자격 요건을 완화하면 수의계약 사유 자체가 무효가 됩니다.",
    "자격 요건을 완화하면 부적정 수의계약이 됩니다." ],
  [ "goe-2021-failed-bid-private-contract", "lesson",
    "가격 인상은 수의계약 무효 사유",
    "가격 인상은 부적정 수의계약 사유" ],

  # ── improper-payee-cleaning-service (P2) ─────────────────────────────
  [ "goe-2021-improper-payee-cleaning-service", "lesson",
    "지방계약법 시행령은 대가 지급을 정당채주(채권자) 본인에게 직접 지급하도록 규정합니다. 「지방자치단체 교육비특별회계 세출예산 집행기준」도 동일 적용됩니다.",
    "지출은 정당한 채주에게 지급해야 합니다(경기도교육비특별회계 재무회계 규칙 §68①, 경기도 공립학교회계 규칙 §34, 세출예산 집행기준)." ],

  # ── improper-payee-personal-card (P2) ────────────────────────────────
  [ "goe-2021-improper-payee-personal-card", "lesson",
    "지방계약법·교육비특별회계 세출예산 집행기준에 따라",
    "경기도교육비특별회계 재무회계 규칙 §68①·세출예산 집행기준에 따라" ],
  [ "goe-2021-improper-payee-personal-card", "detail",
    "개인카드 업무용 사용 금지 위반** ([[goe-2021-credit-card-usage-improper]] 참조)",
    "개인카드 업무용 사용 금지 위반**" ],

  # ── instructor-allowance-improper (P2) ───────────────────────────────
  [ "goe-2021-instructor-allowance-improper", "lesson",
    "1. **인사혁신처 예규 확인** (매년 1월)",
    "1. **경기도교육비특별회계 예산편성 기본지침·세출예산 집행기준 확인**" ],

  # ── special-duty-allowance-mispayment (P2) ───────────────────────────
  [ "goe-2021-special-duty-allowance-mispayment", "detail",
    "「2021 감사사례집」(p.126)",
    "「2021 감사사례집」(p.127)" ],
  [ "goe-2021-special-duty-allowance-mispayment", "detail",
    "누적 과오지급 규모가 약 1,131만원에 이른 사례입니다.",
    "누적 과오지급 규모가 약 1,161만원(11,613,360원)에 이른 사례입니다." ],
  [ "goe-2021-special-duty-allowance-mispayment", "detail",
    "30개 학교 누적 1,161만원 규모는",
    "31개 학교(중복 여부는 원문 미표기) 누적 1,161만원 규모는" ],
  [ "goe-2021-special-duty-allowance-mispayment", "detail",
    "공로연수·교육훈련파견 등 30일 이상 파견은 NEIS에서 자동 차감되지 않습니다.",
    "원문은 NEIS 보직구분 설정 착오를 원인으로 지적했습니다(자동 차감 여부는 원문에 없음)." ],
  [ "goe-2021-special-duty-allowance-mispayment", "detail",
    "NEIS 자동 산정에 의존한 결과 시스템에서 자동 차감되지 않는 파견·휴직 등 예외 케이스가 누락되면",
    "파견·휴직 등 예외 케이스 점검이 누락되면" ],
  [ "goe-2021-special-duty-allowance-mispayment", "lesson",
    "### 자동 차감 불가 케이스 (수동 점검 필수)\n\n다음 케이스는 NEIS에서 자동 차감되지 않으므로 행정실 수동 점검이 필요합니다.",
    "### 수동 점검 필요 케이스\n\n원문은 NEIS 보직구분 설정 착오를 원인으로 지적했습니다(자동 차감 여부는 원문에 없음). 다음 케이스는 행정실 수동 점검이 필요합니다." ],
  [ "goe-2021-special-duty-allowance-mispayment", "lesson",
    "— 파견·휴직 자동 차감 안 됨",
    "— 파견·휴직 등 예외 케이스는 행정실 점검 필요" ],

  # ── split-after-school-program (P3) ──────────────────────────────────
  [ "goe-2021-split-after-school-program", "detail",
    "특히 학교장 도장 수기 계약은 학교장이 분할 의도를 인지·승인했음을 강하게 시사하며, 사후 8회 분할은 계약 일자 조작 의혹까지 동반합니다.",
    "원문은 관련자 주의·관리자(교장) 경고까지만 서술합니다." ],
  [ "goe-2021-split-after-school-program", "lesson",
    "해석됩니다. 이는 학교장이 절차 위반을 인지·승인했음을 강하게 시사하며, ",
    "해석될 수 있습니다(원문은 관련자 주의·관리자(교장) 경고까지만 서술). " ],
  [ "goe-2021-split-after-school-program", "lesson",
    "형법 §227(허위공문서작성)까지 확장될 위험이 있으며, 형사 책임은 변상·징계와 별개로 진행됩니다.",
    "형사책임 가능성은 원문에 근거가 없습니다(원문 처분: 관련자 주의·관리자(교장) 경고)." ],

  # ── split-care-trip-copier-paint (P2) ────────────────────────────────
  [ "goe-2021-split-care-trip-copier-paint", "detail",
    "G2B 입찰 없이 1인 견적 수의계약",
    "지정정보처리장치를 이용하되 입찰방식을 거치지 않고 수의계약" ],
  [ "goe-2021-split-care-trip-copier-paint", "detail",
    "G2B 입찰이 필요했음에도 1인 견적 수의계약으로 처리됐고, 사례 ④는 14,631 + 9,958 = 24,589천원이 당시 분기점(공사 2천만원·물품 1천만원)에 정확히 걸치도록 분할된 점에서 의도성이 가장 명확합니다.",
    "입찰방식을 거쳐야 했음에도 지정정보처리장치를 이용한 수의계약으로 처리됐고, 사례 ④는 원문이 24,589천원(도장공사)을 14,631천원과 9,958천원으로 분할한 사실을 지적했습니다(공사 1인 견적 한도 2천만원 이하로 나뉨)." ],
  [ "goe-2021-split-care-trip-copier-paint", "detail",
    "또한 도장공사 14,631 + 9,958 = 24,589천원이 당시 분기점(공사 2천만원·물품 1천만원)에 정확히 걸치도록 분할된 점은 의도성 입증의 가장 명확한 증거입니다.",
    "또한 원문은 24,589천원(도장공사)을 14,631천원과 9,958천원으로 분할한 사실을 지적했습니다(공사 1인 견적 한도 2천만원 이하로 나뉨)." ],
  [ "goe-2021-split-care-trip-copier-paint", "lesson",
    "### 운영주체 분할 판단 기준\n",
    "### 운영주체 분할 판단 기준 (실무 해석 — 원문 근거 없음)\n" ],

  # ── supplies-joint-purchase (P2) ─────────────────────────────────────
  [ "goe-2021-supplies-joint-purchase", "lesson",
    "= 학교당 자체 단가\n- 공동구매 시 약 10~20% 단가 절감 가능",
    "= 학교당 자체 단가" ],
  [ "goe-2021-supplies-joint-purchase", "lesson",
    "### 자체 구매가 가능한 예외\n\n중점대상 품목이라도 다음 경우 자체 구매가 가능합니다(시·도 교육청별 차이).\n\n- 긴급 사유 (천재지변·갑작스러운 손상 등)\n- 교육청 공동구매 일정 안 맞음 (사전 협의 필수)\n- 소량 보충 (전체 학생 대상 아닌 일부)\n\n예외 적용 시 사전 사유서 결재 + 교육청 협의가 필수입니다.",
    "### 자체 구매 예외 여부\n\n교육청 공문상 예외 유무는 해당 연도 공문 확인 필요(원문 미제시)." ],

  # ── tenure-allowance-mispayment (P2) ─────────────────────────────────
  [ "goe-2021-tenure-allowance-mispayment", "lesson",
    "## 확인사항 (PDF §확인사항)",
    "## 근거 요지(원문 p.126 관련자 요건)" ],
  [ "goe-2021-tenure-allowance-mispayment", "lesson",
    "직전 6개월 산정 (회의자료 ① 2,000,270원 과소)",
    "직전 6개월 산정" ],
  [ "goe-2021-tenure-allowance-mispayment", "lesson",
    "산입 불가 경력 (회의자료 ② 1,008,200원 과다)",
    "산입 불가 경력" ],

  # ── vending-machine-fee-miscalculation (P3): 법령명 현행 표기만 ─────────
  [ "goe-2021-vending-machine-fee-miscalculation", "legal_basis",
    "공유재산 및 물품관리법,",
    "공유재산 및 물품 관리법," ],
  [ "goe-2021-vending-machine-fee-miscalculation", "legal_basis",
    "경기도교육청 공공시설 내의 매점 자동판매기 수익·사용허가에 관한 조례",
    "경기도교육청 공공시설 내의 매점 및 자동판매기 사용ㆍ수익허가에 관한 조례" ]
].freeze

slugs = (agency.keys + edits.map(&:first)).uniq
dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  slugs.each do |slug|
    ac = AuditCase.find_by(slug: slug)
    raise "[audit-truth-p2p3-goe] missing AuditCase: #{slug}" unless ac

    to_write = {}
    %w[issue lesson detail legal_basis].each do |field|
      original = ac.read_attribute(field).to_s
      value = original
      edits.select { |s, f, _, _| s == slug && f == field }.each do |_, _, old, new|
        # 이미 적용됨: new 가 있고 old 가 없거나, new 가 old 를 품는 덧붙임형 edit
        next if value.include?(new) && (!value.include?(old) || new.include?(old))
        raise "[audit-truth-p2p3-goe] fingerprint missing: #{slug}/#{field}: #{old[0, 40]}" unless value.scan(old).size == 1

        value = value.sub(old) { new }
        changes += 1
      end
      to_write[field] = value unless value == original
    end

    if (target = agency[slug])
      current = [ Array(ac.target_agency), ac.agency_scope_confidence ]
      unless current == target
        raise "[audit-truth-p2p3-goe] agency fingerprint mismatch: #{slug} #{current.inspect}" unless current == PUBLIC

        to_write["target_agency"] = target[0]
        to_write["agency_scope_confidence"] = target[1]
        changes += 1
      end
    end
    next if to_write.empty?

    puts "  [audit-truth-p2p3-goe] AuditCase/#{slug} fields_to_change=#{to_write.keys.join(',')}"
    ac.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end
puts "  [audit-truth-p2p3-goe] #{"DRY_RUN " if dry}changes=#{changes}"
