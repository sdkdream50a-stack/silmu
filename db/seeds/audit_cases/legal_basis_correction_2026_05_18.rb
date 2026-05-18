# frozen_string_literal: true
# 2026-05-18 Phase 1 — 운영 DB only 3건의 legal_basis·issue 정정 시드
# 진단: GSC 색인 위기(396→1 deindexing) 해결 전 법령 인용 정합성 확보
# 검증: 일반 에이전트 + WebSearch + silmu-db-analyst 교차 검증
#
# 정정 대상 (운영 DB에는 존재하나 코드베이스 시드 없음):
# - reserve-fund-violation         : 지방재정법 §46(예비비) → §43(예비비). §46은 예산 불성립 시 집행
# - budget-transfer-limit-violation: §47 라벨 "(예산의 전용)" → "(예산의 목적 외 사용금지와 예산 이체)"
#                                    issue "관 간 전용" → "관 간 이동=이용(移用)"
# - budget-transfer-without-council-approval: §47 라벨 "(예산의 이용·전용)" → "(예산의 목적 외 사용금지와 예산 이체)"
#
# 패턴: find_or_initialize_by(slug) + assign_attributes (project_seed_upsert_pattern 메모리)

corrections = [
  {
    slug: "reserve-fund-violation",
    legal_basis: "지방재정법 제43조(예비비)",
    issue: "일반 사무용품 구매(500만원)를 예비비로 지출하여 예비비 사용 요건을 위반함. " \
           "지방재정법 제43조는 예비비를 예측할 수 없는 예산 외의 지출에만 사용할 수 있도록 규정하고 있으나, " \
           "예측 가능한 일반 사무용품 구매에 사용하여 부적정함."
  },
  {
    slug: "budget-transfer-limit-violation",
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지·정책사업 간 이용·예산 이체)",
    issue: "사업비 예산을 인건비 예산으로 3억원 이용(移用)하였으나, 이는 정책사업 간 예산 이용으로 " \
           "지방의회 의결이 필요한 사항임에도 의회 의결 없이 임의로 처리함. " \
           "지방재정법 제47조는 정책사업 간 예산 이용은 의회 의결을 받아야 한다고 규정하고 있으나, 이를 위반함.",
    action_taken: "예산 전용(轉用, §49)은 정책사업 내 단위·목 간만 단체장 결재로 가능하며, " \
                  "정책사업 간 이동은 이용(移用, §47)으로 분류되어 반드시 지방의회 의결을 받아야 함. " \
                  "예산 이동 시 정책사업 코드를 비교하여 이용·전용을 명확히 구분하고, 이용에 해당하면 사전 의결안을 상정해야 함.",
    checkpoints: [
      "정책사업 코드 비교로 이용·전용 구분",
      "정책사업 간 이동은 의회 의결 필수 (§47)",
      "정책사업 내 전용은 단체장 결재로 가능 (§49)",
      "인건비·업무추진비 이동은 추가 한도 확인",
      "이용 결재 문서에 근거 조문·구분 명시"
    ]
  },
  {
    slug: "budget-transfer-without-council-approval",
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지·정책사업 간 이용·예산 이체), 지방자치법 제142조(예산의 편성 및 의결)"
  },
  # 시드 정정 7건 (시드 재실행 사이드이펙트 회피 위해 정정 시드에 통합)
  {
    slug: "budget-execution-before-approval",
    legal_basis: "지방회계법 제29조(지출원인행위), 회계관계직원 등의 책임에 관한 법률 제4조"
  },
  {
    slug: "accounting-officer-dual-role-fraud",
    legal_basis: "회계관계직원 등의 책임에 관한 법률 제4조, 지방회계법 제23조(징수기관과 수납기관의 분리)"
  },
  {
    slug: "business-expense-personal-use",
    legal_basis: "지방자치단체 업무추진비 집행에 관한 규칙, 지방재정법 제47조(예산의 목적 외 사용금지와 예산 이체)"
  },
  {
    slug: "accounting-data-falsification",
    legal_basis: "지방회계법 제20조(세입의 징수와 수납)·제22조(수납기관), 회계관계직원 등의 책임에 관한 법률 제4조, 형법 제355조(업무상횡령)"
  },
  {
    slug: "budget-appropriation-mistake",
    legal_basis: "지방재정법 제9조(회계의 구분), 지방재정법 제7조(회계연도 독립의 원칙)"
  },
  {
    slug: "expenditure-over-budget",
    legal_basis: "지방회계법 제29조(지출원인행위), 회계관계직원 등의 책임에 관한 법률 제4조"
  },
  {
    slug: "travel-expense-double-claim",
    legal_basis: "공무원여비규정 제4조(여비 지급의 원칙), 지방공무원 여비규정 제4조(여비 지급의 원칙), 지방공무원법 제53조(겸직 금지), 회계관계직원 등의 책임에 관한 법률 제4조"
  }
]

corrections.each do |attrs|
  slug = attrs[:slug]
  ac = AuditCase.find_by(slug: slug)
  if ac.nil?
    puts "[skip] #{slug} — 운영 DB에 없음 (생성 안 함)"
    next
  end
  changed = attrs.except(:slug).reject { |k, v| ac.public_send(k) == v }
  if changed.empty?
    puts "[unchanged] #{slug}"
  else
    ac.assign_attributes(changed)
    ac.save!
    puts "[updated] #{slug} — #{changed.keys.join(', ')}"
  end
end
