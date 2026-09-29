# 감사사례 Truth Closure G3 — 경기도교육청 「2021 감사사례집」 재구성 사례 19건 P0·P1 정정(2026-09-29)
#
# 입력: tasks/silmu-audit-case-truth-closure-0929/workers/g3/verdicts.md · workers/g4/verdicts.md 의 P0·P1 행(원문 PDF 인용).
#   g3 = family·gift(P0) · fiscal·football·foreign·management·misc·overtime·payment·performance(P1)
#   g4 = 2bid·s2b·retirement·specialized·supplies(P0) · public-property·reserve·temp-use·split(P1)
#   P2·P3(cleaning·personal-card·instructor·special-duty·split-care·supplies-joint·split-after-school) 는 범위 밖.
# 원문: 경기도교육청 감사관실 「2021 감사사례집」(BBS_202111190247253801.pdf, 수록 2017~2020, 인쇄쪽 = PDF쪽 − 6).
# 현행 법령: 국가법령정보센터 DRF(OC=test) — 공무원수당 등에 관한 규정 제10조 · 경기도 공립학교회계 규칙 제4조·제19조·제41조
#   (2025-09-01 시행) · 초·중등교육법 제32조① · 지방계약법 시행령 제25조①5·제30조①2·제67조①·제77조 · 공유재산 및 물품 관리법
#   제4조①4·제60조①·제81조 · 교육공무원임용령 제7조의3 · 건설산업기본법 시행령(2020.12.29.) 부칙 제2조·제7조 ·
#   전기공사업법 제11조③ · 같은 법 시행령 제8조.
#
# old 는 운영 페이지(https://silmu.kr/audit-cases/<slug>?cb=…, 2026-09-29 익명 GET)의 렌더 문자열과 같다.
# edits 는 필드(issue·lesson·detail)에 old 가 정확히 1회 있어야 바꾼다. attrs(target_agency·agency_scope_confidence·
# source_page)는 현재값이 old 와 같아야 바꾼다. 이미 new 이면 건너뛴다. 하나라도 어긋나면 전체 롤백.
# DRY_RUN=1 이면 레코드별 fields_to_change 만 출력한다. slug·title·view_count 불변.
#
# target_agency: 공·사립 또는 기관 혼재(misc·s2b·reserve·supplies) → [] + LOW (AgencyScope: 부정확한 metadata 보다 빈 값).
#   ⚠️ `silmu:p1:agency_backfill`(수동 rake)을 다시 돌리면 sector=edu·org_type=school 로 PUBLIC_SCHOOL/HIGH 가 덮인다.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929110000_audit_truth_g3.rb})"'
#   → 기대: changes=112 (edits 102 + attrs 10) · 두 번째 실행 changes=0
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화)
# 롤백: edits 는 new → old 역적용, attrs 는 old 값으로.

g = ->(s) { "goe-2021-#{s}" }

attrs = {
  g.call("family-allowance-misdeclaration") => { "source_page" => [ 127, 128 ] },
  g.call("performance-bonus-mispayment") => { "source_page" => [ 124, 125 ] },
  g.call("misc-allowance-improper") => { "target_agency" => [ %w[PUBLIC_SCHOOL], [] ], "agency_scope_confidence" => %w[HIGH LOW] },
  g.call("private-contract-s2b-mismatch") => { "target_agency" => [ %w[PUBLIC_SCHOOL], [] ], "agency_scope_confidence" => %w[HIGH LOW] },
  g.call("reserve-fund-improper") => { "target_agency" => [ %w[PUBLIC_SCHOOL], [] ], "agency_scope_confidence" => %w[HIGH LOW] },
  g.call("supplies-management-neglect") => { "target_agency" => [ %w[PUBLIC_SCHOOL], [] ], "agency_scope_confidence" => %w[HIGH LOW] }
}.freeze

edits = [
  # ── g3 #1 family(P0): 부양가족 두 요건은 «모두 충족»해야 한다 — 하나(세대)만 깨져도 별거 예외가 아니면 제외(원문 p.128 · 규정 §10②)
  [ g.call("family-allowance-misdeclaration"), "detail",
    '세대 분리가 가족수당 환수 사유가 되려면 "주민등록표상 세대 동일"과 "실제 생계 동일"이 모두 깨져야 하며, 형식적 세대 분리(주거 형편상 별거)는 환수 대상이 아닙니다.',
    '두 요건을 모두 충족해야 부양가족이므로, 세대가 분리되면 별거 예외에 해당하지 않는 한 부양가족에서 제외되고 그 뒤 지급된 가족수당은 회수 대상입니다. 별거 예외는 감사 당시 사례집(p.128) 기준 «취학·요양 또는 주거의 형편이나 근무형편에 따라 별거하고 있는 배우자·자녀나 배우자와 주소·생계를 같이 하는 직계존속», 현행 기준은 «별거하고 있는 가족(배우자, 직계존속 중 공무원의 배우자와 세대를 같이 하는 사람, 공무원 본인과 배우자의 자녀로 한정)»입니다(공무원수당 등에 관한 규정 제10조제2항 단서 · 지방공무원 수당 등에 관한 규정 제10조제2항 단서).' ],
  [ g.call("family-allowance-misdeclaration"), "detail",
    '다만 환수 판단은 "주민등록상 세대 동일 + 실제 생계 동일" 두 요건이 모두 깨졌는지로 결정되므로, 형식적 세대 분리(취학·근무 형편상 별거 등)는 환수 대상이 아니라는 점도 본인 보호를 위해 인지해야 합니다.',
    '세대 동일과 생계 동일은 둘 다 갖춰야 하는 요건이므로 세대 분리만으로도 부양가족에서 빠질 수 있고, 예외는 취학·요양·주거·근무 형편상 별거하는 배우자·자녀와 공무원의 배우자와 세대를 같이 하는 직계존속(현행 규정 제10조제2항 단서 · 감사 당시 사례집은 «배우자와 주소·생계를 같이 하는 직계존속»)에 한정된다는 점을 본인 보호를 위해 인지해야 합니다.' ],
  [ g.call("family-allowance-misdeclaration"), "detail", "「2021 감사사례집」(p.127)", "「2021 감사사례집」(p.128)" ],
  [ g.call("family-allowance-misdeclaration"), "lesson",
    '2. **"세대 분리만 되면 환수 안 됨"** — 실제 생계 동일 시 부양가족 포함 (취학·요양 등)',
    '2. **"생계만 같이하면 세대를 분리해도 된다"** — 세대 동일·생계 동일을 모두 갖춰야 함. 예외는 취학·요양·주거·근무 형편상 별거하는 배우자·자녀와 공무원의 배우자와 세대를 같이 하는 직계존속뿐(현행 규정 제10조제2항 단서 · 감사 당시 사례집: «배우자와 주소·생계를 같이 하는 직계존속»)' ],
  [ g.call("family-allowance-misdeclaration"), "lesson",
    '— 매년 1월 갱신, 인사혁신처 예규 확인',
    '— 단가는 지방공무원 수당 등에 관한 규정 제10조제1항에서 확인' ],
  [ g.call("family-allowance-misdeclaration"), "lesson",
    '취학·요양·주거·근무 형편상 별거하는 경우 부양가족에 포함됨에도',
    '취학·요양·주거·근무 형편상 별거하는 배우자·자녀는 부양가족에 포함됨에도' ],

  # ── g3 #2 fiscal(P1): 출납 폐쇄 = 회계연도 종료일, 3.20 은 지방회계법 §7① 단서 사유만(공립학교회계 규칙 §4, 2024.12.19. 개정) · 사고이월 = 규칙 §19②
  [ g.call("fiscal-year-independence-violation"), "lesson",
    '| 세입·세출 사무 폐쇄 | 3월 20일 |',
    '| 출납 폐쇄 | 회계연도 종료일(2월 말). 다만 「지방회계법」 제7조제1항 단서 사유가 있으면 다음 회계연도 3월 20일까지 수입·지출 처리 가능(경기도 공립학교회계 규칙 제4조) |' ],
  [ g.call("fiscal-year-independence-violation"), "lesson",
    '- [ ] 3월 20일 폐쇄일 이후 소급 처리를 시도하지 않았는가?',
    '- [ ] 회계연도 종료(2월 말) 후 처리는 「지방회계법」 제7조제1항 단서 사유에 해당하는 수입·지출에 한해 3월 20일까지만 했는가?' ],
  [ g.call("fiscal-year-independence-violation"), "lesson",
    '— 2월 말 종료가 원칙, 3.20은 사무 폐쇄일',
    '— 출납은 회계연도 종료일(2월 말) 폐쇄가 원칙, 3월 20일은 지방회계법 제7조제1항 단서 사유가 있을 때만 수입·지출 처리가 허용되는 기한' ],
  [ g.call("fiscal-year-independence-violation"), "lesson",
    '- **사고이월**: 회계연도 종료 직전 발생한 불가피 사유 (사고 사실 입증서 + 학교운영위 보고)',
    '- **사고이월**: 해당 회계연도 내에 지출원인행위를 하고 불가피한 사유로 그 연도 내에 지출하지 못한 경비 (경기도 공립학교회계 규칙 제19조②)' ],
  [ g.call("fiscal-year-independence-violation"), "detail",
    '- 세입·세출 사무 폐쇄일: 3월 20일',
    '- 출납 폐쇄: (감사 당시) 세입·세출 사무 3월 20일 기준 폐쇄 → (현행, 경기도 공립학교회계 규칙 제4조 2024.12.19. 개정) 회계연도가 끝나는 날 폐쇄, 다만 지방회계법 제7조제1항 단서 사유가 있으면 다음 회계연도 3월 20일까지 수입·지출 처리 가능' ],
  [ g.call("fiscal-year-independence-violation"), "detail",
    '| 사무 폐쇄 | 3.20 폐쇄 | 폐쇄일 이후 소급 |',
    '| 출납 폐쇄 | 회계연도 종료일 폐쇄(단서 사유만 3.20까지 처리) | 종료 후 소급 |' ],
  [ g.call("fiscal-year-independence-violation"), "detail",
    '초·중등교육법 2024-03-28 시행본',
    '초·중등교육법 2026-09-11 시행본' ],

  # ── g3 #3 football(P1): 시행령 §25 에 «위탁사업 후속» 사유 없음 · 학교운영위 «1억 초과 사전 심의» 근거 없음(초·중등교육법 §32①10·12호) · 학술연구 등 1억 이하(§25①5마)
  [ g.call("football-team-extension-contract"), "lesson",
    "- 위탁사업의 후속 사업으로서 일정 요건 충족\n",
    "" ],
  [ g.call("football-team-extension-contract"), "lesson",
    '5천만원 이하 (학술연구·특례 등) / 1억원 이하 (특례기업)',
    '1억원 이하 (특례기업 · 학술연구·원가계산·건설기술 등 용역은 시행령 §25①5마)' ],
  [ g.call("football-team-extension-contract"), "lesson",
    '- [ ] 1억 원 초과 사업은 학교운영위 사전 심의를 거쳤는가?',
    '- [ ] 학교급식·학교운동부 운영 등 학교운영위원회 심의사항(초·중등교육법 제32조제1항제10호·제12호)은 심의를 거쳤는가?' ],
  [ g.call("football-team-extension-contract"), "lesson",
    '— 1억 원 초과는 사전 심의 필수',
    '— 학교급식·학교운동부 운영은 학교운영위원회 심의사항(초·중등교육법 제32조제1항제10호·제12호)' ],
  [ g.call("football-team-extension-contract"), "detail",
    '| 학교운영위 | 1억 원 초과 사업 사전 심의 | 연장 결정 사후 보고 |',
    '| 학교운영위 | 학교급식·학교운동부 운영 심의(초·중등교육법 제32조제1항) | 연장 결정 사후 보고 |' ],

  # ── g3 #4 foreign(P1): 공유재산 범위 = 전세권 등 «권리»(공유재산 및 물품 관리법 §4①4), 보증금 채권이 아님 · 편람 = 경기도교육청
  [ g.call("foreign-teacher-housing-deposit"), "detail",
    '「공유재산 및 물품관리법」은 학교 자금으로 지출한 보증금을 공유재산의 일종으로 분류하며, 전세권 등 권리도 공유재산으로 봅니다.',
    '「공유재산 및 물품 관리법」은 전세권과 그 밖에 이에 준하는 권리를 공유재산의 범위에 포함합니다(제4조제1항제4호).' ],
  [ g.call("foreign-teacher-housing-deposit"), "detail",
    '시·도 교육청별 「원어민 영어 보조교사 업무편람」은',
    '경기도교육청 「원어민 영어 보조교사 업무편람」(융합교육정책과)은' ],

  # ── g3 #5 gift(P0): 원문 연도 20××(사례집 2021 발간) · 둘째 사례 처분 = 관련자 주의, 과오지급액(60,000원) 회수(원문 p.84) · «7일» 기한 원문 없음
  #   (수령인 자필 서명 행은 원문 근거 «수령인 자필 서명을 의무화»가 있어 유지)
  [ g.call("gift-voucher-management"), "detail",
    '  - 2024.7월 지급 상품권 5,000원×12매 (60,000원) 사용용도 불분명',
    '  - 20××.7월 지급 상품권 5,000원×12매 (60,000원) 사용용도 불분명' ],
  [ g.call("gift-voucher-management"), "detail",
    '5,000원×12매 = 60,000원이 4년 후 정확히 적발된 점은',
    '5,000원×12매 = 60,000원처럼 소액도 사용용도가 불분명하면 적발·회수된 점은' ],
  [ g.call("gift-voucher-management"), "detail",
    '인사이동 시 수불부 인수인계는 90일 미루지 말고 7일 이내 처리하는 것이 본인 보호의 핵심입니다.',
    '인사이동 시 수불부·잔액 인수인계를 미루지 않는 것이 본인 보호의 핵심입니다(원문은 종합감사 자료 제출 전까지 인계하지 않은 점을 지적).' ],
  [ g.call("gift-voucher-management"), "detail",
    '- 사례집 원문 처분: «관련자 경고 및 주의» (경기도교육청 감사사례집, 2021)',
    '- 사례집 원문 처분: «관련자 경고 및 주의»(사전 일괄구매) / «관련자 주의, 과오지급액(60,000원) 회수»(사용용도 불분명·인수인계 누락) (경기도교육청 감사사례집, 2021)' ],
  [ g.call("gift-voucher-management"), "detail",
    '넷째, 인사이동 즉시 인수인계.',
    '넷째, 인사이동 시 수불부·잔액 인수인계.' ],
  [ g.call("gift-voucher-management"), "lesson",
    '| ④ 인수인계 | 인사이동 7일 이내 수불부·잔액 인계 |',
    '| ④ 인수인계 | 인사이동 시 수불부·잔액을 후임자에게 인계 |' ],
  [ g.call("gift-voucher-management"), "lesson",
    '- [ ] 인사이동 시 7일 이내 수불부·잔액을 후임자에게 인계했는가?',
    '- [ ] 인사이동 시 수불부·잔액을 후임자에게 인계했는가?' ],
  [ g.call("gift-voucher-management"), "lesson",
    '— 4년 후에도 60,000원 정확히 적발',
    '— 60,000원도 사용용도 불분명으로 적발·회수' ],
  [ g.call("gift-voucher-management"), "lesson",
    '— 7일 이내 미처리는 책임 단절',
    '— 인계 누락은 책임 단절(원문: 종합감사 자료 제출 전까지 미인계)' ],
  [ g.call("gift-voucher-management"), "lesson",
    '### 인수인계 7일 절차',
    '### 인수인계 절차' ],
  [ g.call("gift-voucher-management"), "lesson",
    '1. **인사이동 결정 즉시**: 인계인수 일정 확정 (이동일 7일 이내)',
    '1. **인사이동 결정 즉시**: 인계인수 일정 확정' ],

  # ── g3 #9 management(P1): 교육공무직원 4명 임의 급여 건 + 처분 «관련자 경고, 관리자(교장) 주의» 누락(원문 p.122)
  [ g.call("management-allowance-mispayment"), "issue",
    '652,410원 과다지급함.',
    '652,410원 과다지급함. ○○초등학교에서는 교육공무직원 4명의 근로 계약 시 급여를 산출 근거나 특별한 사유 없이 경기도교육청 교육공무직원 일할단가를 적용하지 않고 임의의 금액으로 정해 지급함.' ],
  [ g.call("management-allowance-mispayment"), "detail",
    '- 사례집 원문 처분: «관련자 주의, 과소지급액 추가지급 및 과다지급액 회수» (경기도교육청 감사사례집, 2021)',
    '- 사례집 원문 처분: «관련자 주의, 과소지급액 추가지급 및 과다지급액 회수»(관리업무수당·연가초과 결근·연차 초과) / «관련자 경고, 관리자(교장) 주의»(교육공무직원 급여 임의 산정) (경기도교육청 감사사례집, 2021)' ],
  [ g.call("management-allowance-mispayment"), "lesson",
    '## 확인사항 (PDF §확인사항)',
    '## 확인사항 (2021 감사사례집 기준 — 현행 산식은 보수규정·업무지침 재확인)' ],

  # ── g3 #10 misc(P1): 사례 기관 = 교육지원청(교육비특별회계) → target 혼재 · «지급 가능 명목 4종» 근거 없음
  [ g.call("misc-allowance-improper"), "lesson",
    "자문·점검 위원에게 지급 가능한 명목은 다음으로 한정됩니다.\n\n- 회의수당 (지침에 명시된 단가)\n- 자문료 (공식 자문 사업)\n- 여비 (실비 정산)\n- 강사료 (강의·연수 사업)\n\n\"컨설팅 수당\"·\"점검 수당\"은 위 4종에 해당하지 않으면 자체 신설로 분류됩니다.",
    "자문·점검 위원에게는 예산편성 기본지침 등 지침이 정한 명목·단가로만 지급할 수 있습니다(지급 가능 명목은 해당 연도 지침에서 확인). 원문 사례는 「경기도교육비특별회계 예산편성 기본 지침」에서 정하지 않은 컨설팅·점검수당 명목의 지급을 지적했습니다." ],
  [ g.call("misc-allowance-improper"), "lesson",
    '— 지급 가능 명목 4종 외 불가',
    '— 지침이 정한 명목 외 불가' ],
  [ g.call("misc-allowance-improper"), "lesson",
    '- 지급 가능 명목 (회의수당·자문료·여비·강사료)',
    '- 지급 가능 명목 (해당 연도 예산편성 기본지침 기준)' ],

  # ── g3 #11 overtime(P1): 원문 처분 4종(현지조치 · 기관주의 포함, 원문 p.128~129)
  [ g.call("overtime-allowance-mispayment"), "detail",
    '- 사례집 원문 처분: «관련자 주의, 부당지급액 회수(근무일수 감액·방과후 수당 중복) / 관련자 주의(요구)(초과근무확인대장)» (경기도교육청 감사사례집, 2021)',
    '- 사례집 원문 처분: «현지조치, 과다지급액 회수»(정액분 근무일수 미달) / «관련자 주의, 부당지급액 회수»(방과후 수당 중복, 교사 9명·16명) / «관련자 주의(요구)»(초과근무확인대장) / «기관주의, 관련자 주의, 과다지급액 회수»(교사 44명 중복 지급) (경기도교육청 감사사례집, 2021)' ],

  # ── g3 #12 payment(P1): 지연 건 처분 «담당자 경고, 관리자(행정실장) 주의» 누락 · «30일 이내» 근거 없음(시행령 §67① = 청구일부터 5일) · 187일 가공
  [ g.call("payment-processing-improper"), "detail",
    '- 사례집 원문 처분: «관련자 주의, 부당집행액 회수» (경기도교육청 감사사례집, 2021)',
    '- 사례집 원문 처분: «담당자 경고, 관리자(행정실장) 주의»(지출결의 100일 이상 지연 10건) / «관련자 주의, 부당집행액 회수»(자료장 과다 집행 214,500원 등) (경기도교육청 감사사례집, 2021)' ],
  [ g.call("payment-processing-improper"), "detail",
    '  - 지연 일수: 100~187일',
    '  - 지연 일수: 100일 이상' ],
  [ g.call("payment-processing-improper"), "lesson",
    '- [ ] 업체 청구 후 30일 이내 지출결의를 했는가?',
    '- [ ] 검사 완료 후 대가 청구를 받으면 청구일부터 5일(공휴일·토요일 제외) 이내에 지급했는가? (지방계약법 시행령 제67조제1항)' ],

  # ── g3 #13 performance(P1): 임용령 §7의3 은 «파견»(①4·7호)만 — 휴직·직위해제·공로연수 귀속·«30일 이상» 조건 삭제(원문 p.125)
  [ g.call("performance-bonus-mispayment"), "lesson",
    '30일 이상 파견 기간 = 근무기간 미포함, 일할계산',
    '교육훈련파견 기간 = 근무기간 미포함, 일할계산' ],
  [ g.call("performance-bonus-mispayment"), "detail",
    '30일 이상 파견 기간 = 근무기간 미포함, 일할계산',
    '교육훈련파견 기간 = 근무기간 미포함, 일할계산' ],
  [ g.call("performance-bonus-mispayment"), "lesson",
    "### 「교육공무원임용령」 §7의3 적용 케이스\n\n교육공무원임용령 §7의3 ① 4호·7호에 따라 다음 기간은 성과상여금 산정 시 근무기간에 포함되지 않습니다.\n\n- 휴직 (육아·질병·연수 등)\n- 직위해제\n- 교육훈련파견 (30일 이상)\n- 공로연수",
    "### 근무기간에서 제외하는 기간 (사례집 기준)\n\n사례집 기준으로 다음 기간은 성과상여금 산정 시 근무기간에 포함하지 않고 일할 계산합니다(세부는 해당 연도 교육청 성과상여금 지급 지침 확인).\n\n- 휴직\n- 직위해제\n- 교육훈련파견 (「교육공무원임용령」 제7조의3제1항제4호·제7호)" ],
  [ g.call("performance-bonus-mispayment"), "lesson",
    '- [ ] 30일 이상 교육훈련파견 기간을 근무기간에서 차감했는가?',
    '- [ ] 휴직·직위해제·교육훈련파견 기간을 근무기간에서 차감했는가?' ],
  [ g.call("performance-bonus-mispayment"), "lesson",
    '— 30일 이상 파견은 근무기간 미포함',
    '— 교육훈련파견 기간은 근무기간 미포함(일할 계산)' ],
  [ g.call("performance-bonus-mispayment"), "lesson",
    '3. **파견 점검**: 30일 이상 교육훈련파견 기록 대조',
    '3. **파견 점검**: 교육훈련파견 기록 대조' ],
  [ g.call("performance-bonus-mispayment"), "detail",
    '둘째, 「교육공무원임용령」 §7의3 ① 4호·7호에 따른 휴직·직위해제·교육훈련파견 등은 근무기간 미포함으로 일할계산.',
    '둘째, 사례집 기준 휴직·직위해제·교육훈련파견(「교육공무원임용령」 제7조의3제1항제4호·제7호) 기간은 근무기간 미포함으로 일할계산.' ],
  [ g.call("performance-bonus-mispayment"), "detail", "「2021 감사사례집」(p.124)", "「2021 감사사례집」(p.125)" ],

  # ── g4 #1 2bid(P0): 현행 1억 한도는 특례 상대방만(시행령 §25①5 라·바) — 일반 업체 53,564천원 용역은 현행에도 입찰 · «분할발주» 원문 없음
  [ g.call("private-contract-2bid-violation"), "lesson",
    '53,564천원이 (2017~2020 기준) 5천만원 한도를 3,564천원만 초과한 점에서 의도적 한도 회피 의혹 농후. 의도적 분할발주 패턴.',
    '53,564천원은 사례 시점(2017~2020) 2인 견적 수의계약 한도(5천만원)를 넘어 입찰 대상이었는데 2인 이상 견적 수의계약으로 처리했다(원문 지적). 원문은 분할발주를 언급하지 않는다.' ],
  [ g.call("private-contract-2bid-violation"), "lesson",
    '## ⚠️ 2025년 현행 기준 변경 (실무 적용 시 주의)',
    '## ⚠️ 현행 기준 (2026-09-29 확인 · 실무 적용 시 주의)' ],
  [ g.call("private-contract-2bid-violation"), "lesson",
    "2020.7.15 시행령 한시적 특례 → 2023.1.1 영구 적용으로 **2인 견적 수의계약 한도가 2배 상향**:\n- 종합공사: 2억 → 4억원 이하\n- 전문공사: 1억 → 2억원 이하\n- 전기·통신·소방공사: 8천만원 → 1억6천만원 이하\n- **물품·용역: 5천만원 → 1억원 이하**\n\n현재 53,564천원 용역은 2인 견적 수의계약 가능 한도(1억원)에 들어감 — 이 사례 그대로 적용하면 잘못된 판단. 단, 분할발주 의혹 패턴은 시점 무관 유효.",
    "현행 지방계약법 시행령 제25조제1항제5호에서 물품·용역 수의계약은 원칙적으로 **추정가격 2천만원 이하**이고, 2천만원 초과 1억원 이하는 소기업·소상공인·여성기업·장애인기업·사회적기업 등 시행령이 열거한 상대방과 체결할 때만 가능하다(청년창업기업은 5천만원 이하). **일반 업체와의 53,564천원 용역은 현행에서도 입찰 대상이다.**\n- 공사 수의계약 한도: 종합공사 4억원 · 전문공사 2억원 · 그 밖의 공사 1억6천만원 이하\n\n사례 시점(2017~2020)에는 5천만원 이하 2인 견적 수의계약이 가능했고 초과분은 입찰 대상이었다." ],

  # ── g4 #2 s2b(P0): 원문 익명 연도(2023·2024 창작 삭제) · 특례기업 1인 견적 5천만원(시행령 §30①2 단서) · 사례 시점 2천만~5천만 = 2인 견적
  [ g.call("private-contract-s2b-mismatch"), "detail",
    '- **○○고등학교 ①**: 2023년 교육활동 프로그램 용역 44,000천원',
    '- **○○고등학교 ①**: 20××년 교육활동 프로그램 용역 44,000천원' ],
  [ g.call("private-contract-s2b-mismatch"), "detail",
    '- **○○고등학교 ②**: 2024년 동일 용역 26,873천원',
    '- **○○고등학교 ②**: 20$$년(원문 익명 연도, 사례집 수록 기간 2017~2020) 동일 용역 26,873천원' ],
  [ g.call("private-contract-s2b-mismatch"), "detail",
    '| 유치원 교구 23,447천원 | 1인 견적 한도(2천만원) 초과 → 입찰 대상 | 1인 견적 처리 |',
    '| 유치원 교구 23,447천원 | 1인 견적 한도(2천만원) 초과 → 사례 시점 2인 이상 견적 수의계약 대상(현행 일반 업체는 입찰) | 1인 견적 처리 |' ],
  [ g.call("private-contract-s2b-mismatch"), "detail",
    '| 교육 프로그램 44,000천원 | 1인 견적 한도(2천만원) 초과 → 입찰 대상 | 사전 결정 업체 형식 견적 |',
    '| 교육 프로그램 44,000천원 | 1인 견적 한도(2천만원) 초과 → 사례 시점 2인 이상 견적 수의계약 대상(현행 일반 업체는 입찰) | 사전 결정 업체 형식 견적 |' ],
  [ g.call("private-contract-s2b-mismatch"), "detail",
    '2019.11.5. 행안부 예규 개정 이후 1인 견적 수의계약 한도는 추정가격 2천만원으로 통일됐고, 일반 업체와의 계약은 그 이상이면 입찰이 원칙입니다(특례기업은 5천만원·1억원 한도 별도 적용).',
    '2019.11.5. 조정(재무기획관-36241) 이후 1인 견적 수의계약 한도는 추정가격 2천만원으로 통일됐고, 사례 시점에는 용역·물품 2천만원 초과 5천만원 이하는 2인 이상 견적 수의계약, 5천만원 초과는 입찰이었습니다. 현행(시행령 제25조제1항제5호)은 일반 업체와 2천만원 초과 수의계약이 불가하며, 청년창업·여성·장애인기업·사회적기업 등은 1인 견적 5천만원 이하(시행령 제30조제1항제2호 단서) 한도가 별도 적용됩니다.' ],
  [ g.call("private-contract-s2b-mismatch"), "lesson",
    '| 물품·용역 1인 견적 수의계약 | 2천만원 이하 | 2천만원 이하 |',
    '| 물품·용역 1인 견적 수의계약 | 2천만원 이하 | 5천만원 이하 (청년창업·여성·장애인기업·사회적기업 등, 시행령 §30①2 단서) |' ],

  # ── g4 #3 public-property(P1): 10년은 적법 «대부» 기간, 무단점유는 그 뒤 · §81②의 5년 = 징수 유예·분납 · «묵시적 갱신 무효» 근거 없음
  [ g.call("public-property-occupation-violation"), "detail",
    '특히 10년간 5필지 공유재산을 무단점유한 케이스에서',
    '특히 10년간(200×~20$$) 대부하던 5필지의 대부계약이 끝난 뒤 갱신·대부료 징수 없이 △△△ 외 3인이 무단점유한 케이스에서' ],
  [ g.call("public-property-occupation-violation"), "detail",
    '- **사례 ③ 10년 무단점유 (5필지)**:',
    '- **사례 ③ 10년 대부 후 무단점유 (5필지)**:' ],
  [ g.call("public-property-occupation-violation"), "detail",
    '또한 대부계약 만료 후 묵시적 갱신은 법적으로 무효이며, 즉시 갱신 절차 또는 변상금 부과 결정이 필요합니다.',
    '또한 대부계약이 끝난 뒤 갱신 절차 없이 계속 사용하면 무단점유가 되므로, 즉시 갱신 절차 또는 변상금 부과 결정이 필요합니다.' ],
  [ g.call("public-property-occupation-violation"), "detail",
    '"대부계약 만료 후 묵시적 갱신"은 법적으로 무효입니다.',
    '"대부계약 만료 후 묵시적 갱신"에 기대면 안 됩니다 — 사례 ③처럼 갱신·대부료 징수 없이 계속 사용하면 무단점유로 변상금 부과 대상이 됩니다.' ],
  [ g.call("public-property-occupation-violation"), "lesson",
    '「공유재산 및 물품관리법」 §6·§81에 따라:',
    '「공유재산 및 물품 관리법」 §6(무단 사용·수익 금지)·§81(변상금)과 사례집 서술에 따라:' ],
  [ g.call("public-property-occupation-violation"), "lesson",
    '- **소급 기간**: 최대 5년',
    '- **소급 기간**: 사례집은 5년까지 소급부과한 것으로 서술 (제81조제2항의 5년은 징수 유예·분납 범위)' ],
  [ g.call("public-property-occupation-violation"), "lesson",
    '— 법적으로 무효, 갱신 절차 또는 변상금 부과 필요',
    '— 갱신 절차 없이 계속 사용하면 무단점유로 변상금 부과 대상(사례 ③)' ],

  # ── g4 #4 reserve(P1): 이자율 높은 예금 = «할 수 있다»(공립학교회계 규칙 §41②) · «분기 1회 의무»·«결산 공시» 원문 없음
  [ g.call("reserve-fund-improper"), "lesson",
    '### 이자율 관리 의무',
    '### 이자율 관리' ],
  [ g.call("reserve-fund-improper"), "lesson",
    '정기예금 이자율은 은행·예금 종류별로 차이가 큽니다. 분기 1회 시중 이자율을 비교해 가장 높은 예금으로 재예치하는 것이 의무이며, 저이자율 예금 방치는 학교 자산 손실 사유가 됩니다. 비교 결재 문서는 본인 보호 자료가 됩니다.',
    '학교의 장은 학교운영에 지장이 없는 범위에서 이자수입 증대를 위해 유휴자금을 이자율이 높은 예금으로 별도 관리할 수 있습니다(경기도 공립학교회계 규칙 제41조제2항). 사례집은 이자율이 높은 예금으로 예치하지 않은 것도 지적했습니다. 예치 결정 결재 문서는 본인 보호 자료가 됩니다.' ],
  [ g.call("reserve-fund-improper"), "lesson",
    '- [ ] 정기예금 이자율을 분기 비교해 가장 높은 예금에 예치하는가?',
    '- [ ] 학교운영에 지장이 없는 범위에서 유휴자금을 이자율이 높은 예금으로 관리하는가?' ],
  [ g.call("reserve-fund-improper"), "lesson",
    '— 학교운영 지장 없는 범위에서 높은 이자 선택 의무',
    '— 사례집은 이자율 높은 예금 미예치도 지적(학교운영 지장 없는 범위)' ],
  [ g.call("reserve-fund-improper"), "lesson",
    '— 학교운영위·이사회·교육청 3중 보고 의무',
    '— 학교운영위·이사회 보고 + 관할 교육청 공문 제출' ],
  [ g.call("reserve-fund-improper"), "lesson",
    '### 결산 시 3중 보고',
    '### 결산 시 보고' ],
  [ g.call("reserve-fund-improper"), "lesson",
    '적립금 운영 결과는 ① 학교운영위(공립) 또는 이사회(사립), ② 관할 교육청, ③ 결산 공시 3중 보고가 의무입니다.',
    '학교회계 결산 시 시설적립금 현황을 ① 학교운영위원회 및 이사회(사립)에 보고하고 ② 관할 교육청에 적립금 집행현황 등을 공문으로 제출해야 합니다(원문 지침).' ],

  # ── g4 #5 retirement(P0): 금액·기간이 학교 간 뒤바뀜 — ○○학교 111,719,310원·약 6년 / ○○초등학교 약 1년 2개월(원문 p.118)
  [ g.call("retirement-pension-mismanagement"), "detail",
    '○○도 ○○초등학교의 교육공무직원 확정급여형(DB형) 퇴직연금 적립금 약 1억 1,170만원이 6년간 세입세출외현금으로 별도 관리되지 않은 사실이 자체 감사에서 적발됐습니다. 같은 자치단체의 △△학교에서도 약 1년 2개월간 동일한 적립금 분리 보관 누락이 확인된 사례입니다.',
    '○○도 ○○학교에서 교육공무직원 확정급여형(DB형) 퇴직적립금 111,719,310원(약 1억 1,170만원)을 약 6년간(20××.3.28.~20$$.2.28.) 세입세출외현금으로 별도 관리하지 않은 사실이 자체 감사에서 적발됐습니다. ○○초등학교에서도 약 1년 2개월간(20××.3.1.~20$$.1.16.) DB형 퇴직연금을 세입세출외현금으로 세입처리하지 않은 사실이 확인된 사례입니다.' ],
  [ g.call("retirement-pension-mismanagement"), "detail",
    '- ○○초등학교 적립금: 약 111,719,310원 (6년 누적)',
    '- ○○학교 퇴직적립금: 111,719,310원 (약 6년, 20××.3.28.~20$$.2.28.)' ],
  [ g.call("retirement-pension-mismanagement"), "detail",
    '- △△학교 적립금: 약 1년 2개월 미관리 (금액은 본 사례 가상 설정)',
    '- ○○초등학교: 약 1년 2개월(20××.3.1.~20$$.1.16.) 세입처리 누락 (금액은 원문 미기재)' ],

  # ── g4 #6 temp-use(P1): 원문은 매주 금요일 사용도 일시사용허가로 보고 증빙 미비를 지적 — «정형 사용 = 사용계약서»·«학교운영위 보고» 근거 없음
  [ g.call("school-facility-temp-use-permit"), "lesson",
    "### 정형 사용 vs 일시사용 구분\n\n매주·매월 등 정형 사용은 일시사용허가 대상이 아닙니다. 다음과 같이 구분하세요.\n\n- **일시사용허가**: 1회성 사용 (행사·동호회 단발 활동 등)\n- **사용계약서**: 정형 사용 (매주·매월 반복 사용)\n\n\"분기별 520,000원\" 같은 정형 사용은 별도 사용계약서를 체결하고, 사용 조건·기간·해지 사유 등을 명시해야 합니다.",
    "### 반복(정형) 사용도 증빙 필수\n\n원문은 매주 금요일 오후 시청각실 사용(2년 10개월, 분기별 520,000원 징수)도 일시사용허가로 처리된 사례로 보고, 시설사용료·사용시간 및 기간·사용조건 등의 증빙서류를 갖추지 않은 점을 지적했습니다(경기도교육비특별회계 소관 공유재산 관리조례 제22조, 같은 조례 시행규칙 제27조). 반복 사용이라도 허가신청서·허가대장·사용료 사전 납부 증빙을 갖춰야 합니다." ],
  [ g.call("school-facility-temp-use-permit"), "lesson",
    '- [ ] 정형 사용은 별도 사용계약서를 체결했는가?',
    '- [ ] 반복 사용도 사용료·사용시간 및 기간·사용조건 증빙을 갖췄는가?' ],
  [ g.call("school-facility-temp-use-permit"), "lesson",
    '### 정형 사용 사용계약서 필수 항목',
    '### 반복 사용 허가 시 증빙 항목 (원문 지적 기준)' ],
  [ g.call("school-facility-temp-use-permit"), "lesson",
    "### 학교운영위 보고\n\n정형 사용은 학교운영위 보고 사항입니다. 분기·연간 사용 현황을 보고하면 사용료 적정성·특혜 의혹을 사후 검증할 수 있으며, 학교운영위 결재 자료는 사후 감사 시 본인 보호 자료가 됩니다.",
    "" ],
  [ g.call("school-facility-temp-use-permit"), "detail",
    '"분기별 520,000원" 같은 정형 사용은 일시사용 허가가 아니라 별도 사용계약서 체결 대상으로 처리해야 하며, 매 회 허가대장 기록이 본인 보호의 핵심입니다.',
    '"분기별 520,000원" 같은 반복 사용도 사용료·사용시간 및 기간·사용조건 증빙을 갖추고 매 회 허가대장에 기록하는 것이 본인 보호의 핵심입니다.' ],

  # ── g4 #8 specialized(P0): 시설물유지관리업 = 2023.12.31.까지 효력(시행령 2020.12.29. 부칙 제2조·제7조) · «50만원 미만» 예외 근거 없음(전기공사업법 §11③·시행령 §8)
  [ g.call("specialized-construction-license"), "lesson",
    '| 일반 시설 유지관리 | 시설물유지관리업 |',
    '| (참고) 시설물유지관리업 | 2023.12.31.까지만 효력 — 건설산업기본법 시행령 개정(2020.12.29.) 부칙 제2조·제7조로 건축·토목공사업 또는 전문공사 업종으로 전환 |' ],
  [ g.call("specialized-construction-license"), "lesson",
    '시설물유지관리업은 일반 시설 유지관리(전구 교체·간단한 도장 등)에 적용되며, 내진보강 같은 구조적 공사에는 부적합합니다.',
    '사례 시점(2017~2020)에는 구조부 보강인 내진보강을 시설물유지관리업자와 계약한 점이 지적됐습니다. 시설물유지관리업은 건설산업기본법 시행령 개정(2020.12.29.) 부칙에 따라 2023.12.31.까지만 효력을 가진 업종으로, 종전 업자는 건축공사업·토목공사업 또는 전문공사 업종으로 전환했습니다(부칙 제2조·제7조).' ],
  [ g.call("specialized-construction-license"), "lesson",
    "- 본 공사에 부수되는 매우 간단한 작업\n- 50만원 미만 소액 (시·도 교육청별 차이)",
    "- 재난 긴급복구공사, 국방·국가안보 등 기밀 유지 공사(전기공사업법 제11조제3항제1호·제2호)\n- 가설 전기공사, 전기시설용량 10kW 이하 소규모 전기공사(국가·지방자치단체 발주 공사는 제외) 등 시행령 제8조의 공사(같은 항 제3호)" ],

  # ── g4 #11 split(P1): «하나만 충족해도 분할 추정» 근거 없음(시행령 §77 = 사업내용 확정된 동일 구조물·단일공사) · 33,032×2 균등 분할 창작
  [ g.call("split-private-contracts"), "lesson",
    '## 분할 추정 3요건: 동일 업체·시기·사업내용',
    '## 분할 판단 요소: 사업내용·시기·업체' ],
  [ g.call("split-private-contracts"), "lesson",
    '### 분할 의도 추정 기준',
    '### 분할 판단 기준' ],
  [ g.call("split-private-contracts"), "lesson",
    '행안부 예규 「지방자치단체 입찰 및 계약 집행기준」에 따라 다음 요건 중 **하나만 충족해도** 분할로 추정될 수 있습니다.',
    '분할 여부는 사업내용이 확정된 동일 구조물공사·단일공사인지(지방계약법 시행령 제77조)와 시기·업체·사업내용의 유사성 등을 종합해 판단합니다. 아래 요소는 판단 시 살펴보는 신호이며, 예규 원문 확인 없이 «하나만 충족하면 분할»로 단정하지 않습니다.' ],
  [ g.call("split-private-contracts"), "lesson",
    '3요건 모두 충족이 아니라 **하나만 충족**해도 추정이 시작되며, 특히 입찰 의무 기준(일반 업체 2천만원) 직전·직후 금액으로 나뉘는 패턴은 의도성이 거의 확정적으로 입증됩니다.',
    '원문 사례는 유사물품을 2건으로 나눠 동일 업체와 수의계약한 점, 동일 시기 유사 시설공사를 여러 업체에 나눠 수의계약한 점을 지적했습니다.' ],
  [ g.call("split-private-contracts"), "detail",
    '→ 2건으로 분할 (33,032천원 ×2) 동일 업체와 수의계약',
    '→ 2건으로 분할해 동일 업체와 수의계약' ],
  [ g.call("split-private-contracts"), "detail",
    '| 66,064천원 → 33,032 ×2 분할 |',
    '| 66,064천원 → 2건 분할 |' ],
  [ g.call("split-private-contracts"), "detail",
    '분할 의도 입증은 ① 동일 업체 ② 동일 시기 ③ 유사 사업내용 3요건 중 하나만 충족해도 추정됩니다.',
    '분할 여부는 사업내용 확정 여부·동일 구조물/단일공사 여부·시기·업체 등을 종합해 판단합니다.' ],
  [ g.call("split-private-contracts"), "detail",
    '분할로 33,032천원으로 나눈 패턴은',
    '2건으로 나눈 패턴은' ],
  [ g.call("split-private-contracts"), "detail",
    '동일 업체 또는 동일 시기 또는 유사 사업내용 중 하나만 충족해도 분할로 추정됩니다. 특히 입찰 의무 기준(일반 업체 2천만원·특례기업 1억원) 직전 금액으로 나뉘는 패턴은 의도성 입증이 가장 명확한 형태이며,',
    '분할 여부는 사업내용·시기·업체 등을 종합해 판단되며,' ],

  # ── g4 #13 supplies(P0): «2년마다 재물조사»는 사립(사학기관 재무·회계 규칙) — 공립은 1년마다(공유재산 및 물품 관리법 §60①) · «14년» = 2024 기준 창작
  [ g.call("supplies-management-neglect"), "lesson",
    '| ③ 재물조사 | 물품관리자 | 2년마다 학년도 말 기준 정기 실시 |',
    '| ③ 재물조사 | 물품관리자 | (공립) 1년마다(공유재산 및 물품 관리법 제60조제1항) · (사립) 2년마다 학년도 말 기준(사학기관 재무·회계 규칙) |' ],
  [ g.call("supplies-management-neglect"), "lesson",
    '- [ ] 2년 주기 재물조사를 학년도 말에 실시하는가?',
    '- [ ] 재물조사를 주기(공립 1년·사립 2년)에 맞춰 실시하는가?' ],
  [ g.call("supplies-management-neglect"), "lesson",
    '14년 누적 같은 시스템적 결함 상태에서는',
    '2010년 이후 누적된 이 사례 같은 시스템적 결함 상태에서는' ],
  [ g.call("supplies-management-neglect"), "lesson",
    '### 14년 누적 결함 시 시정 조치',
    '### 장기 누적 결함 시 시정 조치' ],
  [ g.call("supplies-management-neglect"), "detail",
    '약 14년간 물품관리자',
    '2010년 이후 감사 시점(사례집 수록 2017~2020)까지 약 7~10년간 물품관리자' ],
  [ g.call("supplies-management-neglect"), "detail",
    '(감사일 기준 약 14년)',
    '(사례집 수록 기간 2017~2020 감사 기준 약 7~10년)' ],
  [ g.call("supplies-management-neglect"), "detail",
    '- 재물조사: 미실시 (2년 주기 의무)',
    '- 재물조사: 미실시 (공립 1년·사립 2년 주기 의무)' ],
  [ g.call("supplies-management-neglect"), "detail",
    '셋째, 물품관리자는 2년마다 정기적으로 학년도 말 기준 재물조사를 실시할 의무가 있습니다. 14년간 일체 미실시는',
    '셋째, 재물조사는 공립(교육비특별회계 소관)은 1년마다(공유재산 및 물품 관리법 제60조제1항), 사립은 물품관리자가 2년마다 학년도 말 기준(사학기관 재무·회계 규칙)으로 실시해야 합니다(사례집은 이 세 의무를 사학기관 재무·회계 규칙 기준으로 제시). 2010년 이후 일체 미실시는' ],
  [ g.call("supplies-management-neglect"), "detail",
    '14년 누적 같은 시스템적 결함은',
    '2010년 이후 장기 누적 같은 시스템적 결함은' ],
  [ g.call("supplies-management-neglect"), "detail",
    '2년 주기 재물조사가 누락의 자동 발견 장치이며',
    '정기 재물조사(공립 1년·사립 2년)가 누락의 자동 발견 장치이며' ]
].freeze

count_in = ->(value, needle) { value.to_s.scan(needle).size }

slugs = (attrs.keys + edits.map(&:first)).uniq
dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  slugs.each do |slug|
    record = AuditCase.find_by(slug: slug)
    raise "[audit-truth-g3] record missing: #{slug}" unless record

    to_write = {}
    %w[issue lesson detail].each do |field|
      original = record.read_attribute(field).to_s
      value = original
      edits.select { |s, f, _, _| s == slug && f == field }.each do |_, _, old, new|
        # 이미 적용됨: old 가 없고 (삭제형이거나 new 가 있음), 또는 new 가 old 를 품는 덧붙임형이 이미 들어가 있음
        next if count_in.call(value, old).zero? && (new.empty? || count_in.call(value, new).positive?)
        next if new.include?(old) && count_in.call(value, new).positive?
        raise "[audit-truth-g3] fingerprint missing: #{slug}/#{field}: #{old[0, 40]}" unless count_in.call(value, old) == 1

        value = value.sub(old) { new }
        changes += 1
      end
      to_write[field] = value unless value == original
    end

    attrs.fetch(slug, {}).each do |field, (old, new)|
      current = record.read_attribute(field)
      next if current == new
      raise "[audit-truth-g3] #{field} mismatch: #{slug}: #{current.inspect}" unless current == old

      to_write[field] = new
      changes += 1
    end
    next if to_write.empty?

    puts "  [audit-truth-g3] AuditCase/#{slug} fields_to_change=#{to_write.keys.join(',')}"
    record.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end
puts "  [audit-truth-g3] #{"DRY_RUN " if dry}changes=#{changes}"
