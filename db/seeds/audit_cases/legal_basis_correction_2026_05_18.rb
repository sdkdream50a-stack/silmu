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
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지와 예산 이체)",
    issue: "사업비 예산을 인건비 예산으로 3억원 이용(移用)하였으나, 이는 정책사업 간 예산 이용으로 " \
           "지방의회 의결이 필요한 사항임에도 의회 의결 없이 임의로 처리함. " \
           "지방재정법 제47조는 정책사업 간 예산 이용은 의회 의결을 받아야 한다고 규정하고 있으나, 이를 위반함."
  },
  {
    slug: "budget-transfer-without-council-approval",
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지와 예산 이체), 지방자치법 제142조(예산의 편성 및 의결)"
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
