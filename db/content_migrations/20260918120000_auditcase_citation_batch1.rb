# 감사사례 조문 인용 오류 정정 1차 — HIGH 74건 (2026-09-17 전수감사 G-48)
#
# 257건 970인용 전수 대조(law.go.kr 원문 93법령: 하네스 tasks/silmu-full-audit-rebuild-0917/sources/laws·laws_extra):
#   OK 780 · WRONG_ARTICLE 80 · WRONG_CLAIM 45 · NONEXISTENT 7 · NEEDS_REVIEW 58.
# 이 migration 은 원문으로 대체 조문이 확정된 HIGH 73건만 적용한다(late-penalty-wrong-rate 임대차 요율 1건은 20260918110000 이 같은 문장을 정정하므로 제외). 대체 조문을 확정할 수 없으면 인용을 삭제했다(창작 금지).
# 예: 지방재정법 §47(목적 외 사용금지) → §47의2(예산의 이용·이체, 2020.6.9. 신설) · 지방계약법 §7(계약사무의 위임) «경쟁의 원칙» → §9
#     · 없는 법령 «지방공무원 여비규정» 인용 삭제 · 보조금법 목적 외 사용 벌칙 §40 → §41 · 정보공개법 비공개 이유 §11③ → §13⑤.
# 편집 근거 전문 = 하네스 artifacts/20_AUDIT_CASE_CITATION_EDITS_0917.json (evidence·note).
# 각 old 는 해당 필드에 정확히 1회 있어야 하고(20260918100000 적용 후 기준 검증), 하나라도 어긋나면 전체 롤백한다. DRY_RUN=1 이면 쓰지 않는다.

edits = [
  [ "quote-collection-same-vendor-double", "legal_basis", ", 지방계약법 시행규칙 제43조 (견적서 제출 업체 독립성)", "" ],
  [ "quote-collection-same-vendor-double", "legal_basis", "제25조 제1항 제1호 (소액 수의계약)", "제25조 제1항 제5호 (소액 수의계약)" ],
  [ "private-contract-split-over-limit", "legal_basis", "제25조 제1항 제1호 (소액 수의계약)", "제25조 제1항 제5호 (소액 수의계약)" ],
  [ "performance-guarantee-waiver-loss", "legal_basis", ", 지방계약법 시행규칙 제66조 (계약보증금 면제 대상)", "" ],
  [ "budget-item-wrong-category", "legal_basis", ", 지방재정법 시행령 제68조(지출결의)", "" ],
  [ "budget-execution-no-receipt", "legal_basis", "지방재정법 시행령 제68조(지출결의서), ", "" ],
  [ "travel-expense-settlement-no-receipt", "legal_basis", ", 지방재정법 시행령 제68조(지출결의서의 증빙)", "" ],
  [ "travel-expense-settlement-no-receipt", "lesson", "지방재정법 시행령 제68조는 지출결의서에 증빙서류를 첨부하도록 규정합니다. ", "" ],
  [ "cost-calculation-indirect-cost-overrate", "legal_basis", "지방계약법 제9조 (예정가격의 결정)", "지방계약법 시행령 제9조 (예정가격의 결정방법)" ],
  [ "performance-bonus-score-manipulation", "legal_basis", "지방공무원 수당 등에 관한 규정 제7조의2(성과상여금)", "지방공무원 수당 등에 관한 규정 제6조의2(성과상여금 등)" ],
  [ "performance-bonus-score-manipulation", "legal_basis", "공무원 성과평가 등에 관한 규정 제26조·", "공무원 성과평가 등에 관한 규정·" ],
  [ "direct-production-confirm-missing", "legal_basis", "법률 제9조의2 (직접생산 확인)", "법률 제9조 (직접생산의 확인 등)" ],
  [ "direct-production-confirm-missing", "legal_basis", "같은 법 시행령 제9조 (직접생산확인증명서 발급 및 제출)", "같은 법 시행령 제10조 (직접생산의 확인 등)" ],
  [ "direct-production-confirm-missing", "detail", "중소기업제품 구매촉진법 제9조의2 위반", "중소기업제품 구매촉진법 제9조 위반" ],
  [ "travel-expense-double-claim", "legal_basis", ", 지방공무원 여비규정 제4조(여비의 계산)", "" ],
  [ "accommodation-allowance-false-claim", "legal_basis", ", 지방공무원 여비규정 제16조(숙박비)", "" ],
  [ "accommodation-allowance-false-claim", "detail", "공무원여비규정 제16조 제1항 및 지방공무원 여비규정은 숙박비를", "공무원여비규정 제16조 제1항은 숙박비를" ],
  [ "vehicle-travel-allowance-distance-fraud", "legal_basis", ", 지방공무원 여비규정 자동차운임 동일 조문", "" ],
  [ "vehicle-travel-allowance-distance-fraud", "detail", " 및 지방공무원 여비규정 제13조·별표 2(자동차운임)", "" ],
  [ "domestic-travel-transport-overclaim", "legal_basis", ", 지방공무원 여비규정 별표(자가용 여비)", "" ],
  [ "travel-expense-settlement-no-receipt", "legal_basis", ", 지방공무원 여비규정 동일 조문", "" ],
  [ "budget-transfer-limit-violation", "issue", "지방재정법 제47조는 정책사업 간 예산 이용은", "지방재정법 제47조의2는 정책사업 간 예산 이용은" ],
  [ "budget-transfer-limit-violation", "detail", "| 근거 조문 | 지방재정법 제49조 | 지방재정법 제47조 |", "| 근거 조문 | 지방재정법 제49조 | 지방재정법 제47조의2 |" ],
  [ "budget-transfer-limit-violation", "action_taken", "이용(移用, §47)", "이용(移用, §47의2)" ],
  [ "budget-transfer-limit-violation", "lesson", "| 근거 | 지방재정법 제47조 | 지방재정법 제49조 |", "| 근거 | 지방재정법 제47조의2 | 지방재정법 제49조 |" ],
  [ "budget-transfer-limit-violation", "lesson", "(§47 또는 §49)", "(§47의2 또는 §49)" ],
  [ "budget-misuse", "issue", "금지하고, 정책사업 간 이용은 의회 의결을", "금지하고, 제47조의2는 정책사업 간 이용은 의회 의결을" ],
  [ "budget-misuse", "detail", "| 근거 조문 | 지방재정법 제49조 | 지방재정법 제47조 |", "| 근거 조문 | 지방재정법 제49조 | 지방재정법 제47조의2 |" ],
  [ "budget-misuse", "lesson", "| 지방재정법 §47 제1항 본문 |", "| 지방재정법 §47 |" ],
  [ "budget-misuse", "lesson", "| 지방재정법 §47 단서 |", "| 지방재정법 §47의2 제1항 단서 |" ],
  [ "budget-misuse", "lesson", "| 지방재정법 §47 제2항 |", "| 지방재정법 §47의2 제2항 |" ],
  [ "budget-misuse", "lesson", "(§47 또는 §49)", "(§47의2 또는 §49)" ],
  [ "budget-overrun", "lesson", "(지방재정법 §47 단서)", "(지방재정법 §47의2 제1항 단서)" ],
  [ "budget-overrun", "detail", "§47 목적 외 사용금지·이용·이체", "§47 목적 외 사용금지·§47의2 이용·이체" ],
  [ "goe-2021-split-after-school-program", "lesson", "- **지방계약법 §7**: 경쟁의 원칙", "- **지방계약법 §9**: 계약의 방법(일반입찰 원칙)" ],
  [ "goe-2021-split-private-contracts", "detail", "지방계약법 §7은 경쟁의 원칙,", "지방계약법 §9는 계약의 방법(일반입찰 원칙)," ],
  [ "goe-2021-football-team-extension-contract", "detail", "지방계약법 §7은 경쟁의 원칙을 명시하며, §9는 계약 방법을 규정합니다.", "지방계약법 §9는 계약 방법(일반입찰 원칙)을 규정합니다." ],
  [ "goe-2021-failed-bid-private-contract", "lesson", "경쟁 원칙(지방계약법 §7) 위반", "경쟁 원칙(지방계약법 §9) 위반" ],
  [ "goe-2021-contract-method-2stage-bidding", "lesson", "- **지방계약법 §7 (경쟁 원칙)** 위반\n", "" ],
  [ "goe-2021-failed-bid-private-contract", "detail", "시행령 §25 제1항(유찰 후 수의계약 사유)", "시행령 §26 제1항(재공고입찰과 수의계약)" ],
  [ "inspector-qualification-violation", "legal_basis", "지방계약법 시행령 제64조 (검사자의 자격)", "지방계약법 제17조 (검사)" ],
  [ "inspector-qualification-violation", "lesson", " (지방계약법 시행령 §53·§54·§55 종합)", "" ],
  [ "defective-inspection", "lesson", "준공검사 충실성 기준 (지방계약법 시행령 §64)", "준공검사 충실성 기준" ],
  [ "inspection-delayed", "legal_basis", "지방계약법 시행령 제66조", "지방계약법 시행령 제64조" ],
  [ "supervision-absent", "legal_basis", "지방계약법 시행령 제63조", "지방계약법 제16조" ],
  [ "supervision-absent", "lesson", "지방계약법 시행령 제63조에 따라 발주기관은", "지방계약법 제16조 제1항에 따라 발주기관은" ],
  [ "substitution-material-unapproved", "legal_basis", "지방계약법 시행령 제63조, ", "" ],
  [ "private-contract-retroactive", "legal_basis", "지방계약법 제13조", "지방계약법 제14조" ],
  [ "emergency-contract-unjustified", "lesson", "시행령 제25조 제1항 제2호가 정한", "시행령 제25조 제1항 제1호가 정한" ],
  [ "false-private-contract-reason", "lesson", "**허위 작성 시 위조공문서죄** (형법 제229조)", "**허위 작성 시 허위공문서작성죄** (형법 제227조)" ],
  [ "software-dev-misclassified-as-goods", "detail", "시행령 제25조 제1항 제1호의 물품 수의계약 기준", "시행령 제25조 제1항 제5호 나목의 물품 수의계약 기준" ],
  [ "private-contract-split-over-limit", "detail", "\"각 중앙관서의 장 또는 계약담당공무원은 수의계약의 한도금액을 초과하기 위하여 1건의 계약을 분할하여서는 아니 된다.\"", "\"지방자치단체의 장 또는 계약담당자는 행정안전부장관이 정하는 동일 구조물공사 또는 단일공사로서 설계서 등에 따라 전체 사업내용이 확정된 공사는 이를 시기적으로 분할하거나 공사량을 분할하여 계약할 수 없다.\"" ],
  [ "mas-contract-non-listed-product", "detail", "| 구매 근거 | 조달법 제9조의2 |", "| 구매 근거 | 조달법 제13조 |" ],
  [ "mas-contract-non-listed-product", "detail", "1. 조달사업에 관한 법률 제9조의2 위반", "1. 조달사업에 관한 법률 제13조 위반" ],
  [ "accounting-data-falsification", "legal_basis", "형법 제355조(업무상횡령)", "형법 제356조(업무상의 횡령과 배임)" ],
  [ "foreign-travel-private-tourism", "legal_basis", "「공무원여비규정」 제3조(여비의 종류)·제25조(국외여비)", "「공무원여비규정」 제2조(여비의 종류)" ],
  [ "domestic-travel-transport-overclaim", "detail", "공무원여비규정 제8조가 규정하는", "공무원여비규정 별표 2(국내 여비 지급표)가 규정하는" ],
  [ "domestic-travel-transport-overclaim", "lesson", "공무원여비규정 제8조는 운임을", "공무원여비규정 별표 2(국내 여비 지급표)는 운임을" ],
  [ "budget-carryover-violation", "issue", "지방재정법 시행령 제47조는 연도 내 계약 체결 완료를 사고이월 요건으로 규정하고 있으나", "지방재정법 제50조 제2항 제1호는 회계연도 내에 지출원인행위를 하고 불가피한 사유로 지출하지 못한 경비를 사고이월 대상으로 규정하고 있으나" ],
  [ "budget-timing-violation", "issue", "지방재정법 제37조는 회계연도 개시 전까지 예산을 의회에 제출하도록 규정하고 있으나", "지방자치법 제142조 제1항은 시·도는 회계연도 시작 50일 전까지, 시·군 및 자치구는 회계연도 시작 40일 전까지 예산안을 지방의회에 제출하도록 규정하고 있으나" ],
  [ "budget-timing-violation", "detail", "의회는 회계연도 개시 15일 전까지 의결해야 합니다.", "의회는 시·도의 경우 회계연도 개시 15일 전, 시·군·구의 경우 10일 전까지 의결해야 합니다." ],
  [ "subsidy-settlement-false-report", "legal_basis", "제30조(실적보고)", "제27조(보조사업 또는 간접보조사업의 실적 보고)" ],
  [ "national-subsidy-purpose-misuse", "legal_basis", ", 제40조(벌칙)", ", 제41조(벌칙)" ],
  [ "national-subsidy-purpose-misuse", "detail", "| 형사 고발 | 보조금법 제40조 위반 (수사 중) |", "| 형사 고발 | 보조금법 제41조 위반 (수사 중) |" ],
  [ "silmu-2026-position-suspension-senior-officer-review", "detail", "「공무원보수규정」 §29 ①에 따라 봉급 차액 소급 지급", "「공무원보수규정」 §30 ①에 따라 봉급 차액 소급 지급" ],
  [ "silmu-2026-position-suspension-criminal-prosecution", "legal_basis", "공무원수당 등에 관한 규정 제19조 제7항", "지방공무원 수당 등에 관한 규정 제19조 제7항" ],
  [ "silmu-2026-position-suspension-discipline-pending", "lesson", "### 4. 사유 경합 시 ②2~4호 우선", "### 4. 사유 경합 시 ①2~4호 우선" ],
  [ "goe-2021-special-duty-allowance-mispayment", "detail", "「공무원수당 등에 관한 규정」 §15·§17과", "「공무원수당 등에 관한 규정」 §14·§19와" ],
  [ "retirement-allowance-service-period-error", "detail", "| 공무원 재직 중 징계로 인한 정직·직위해제 기간 (일부) | 공무원연금법 제25조 ④항(퇴직수당 재직기간 합산 제외) |", "| 공무원 재직 중 징계로 인한 정직·직위해제 기간 (일부) | 공무원연금법 제25조 ⑤항(직위해제·정직기간 등 2분의 1 차감) |" ],
  [ "year-end-settlement-duplicate-deduction", "lesson", "소득세법 제53조에 따라 동일한", "소득세법 시행령 제106조에 따라 동일한" ],
  [ "silmu-2026-concurrent-external-lecture-no-report", "legal_basis", "공무원 행동강령 제14조", "공무원 행동강령 제15조" ],
  [ "information-disclosure-delay", "detail", "공공기관의 정보공개에 관한 법률 제11조 제3항은 비공개 결정 시", "공공기관의 정보공개에 관한 법률 제13조 제5항은 비공개 결정 시" ],
  [ "goe-2021-public-property-occupation-violation", "lesson", "「공유재산 및 물품관리법」 §81에 따라 지방자치단체 외의 자는", "「공유재산 및 물품관리법」 §13에 따라 지방자치단체 외의 자는" ]
]

dry = ENV["DRY_RUN"] == "1"
changes = 0
missing = []
ActiveRecord::Base.transaction do
  edits.group_by { |slug, field, _, _| [ slug, field ] }.each do |(slug, field), list|
    ac = AuditCase.find_by(slug: slug)
    next missing << slug unless ac

    text = ac.public_send(field).to_s
    list.each do |_, _, old, new|
      next if text.include?(new) && !text.include?(old)
      raise "[citation-batch1] fingerprint missing: #{slug}.#{field}" unless text.scan(old).size == 1

      text = text.sub(old) { new }
      changes += 1
    end
    ac.update_columns(field => text, updated_at: Time.current) if !dry && text != ac.public_send(field).to_s
  end
end
puts "  [citation-batch1] #{"DRY_RUN " if dry}changes=#{changes} missing=#{missing.uniq.size}"
