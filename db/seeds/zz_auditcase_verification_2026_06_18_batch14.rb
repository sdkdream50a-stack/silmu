# frozen_string_literal: true

# 2026-06-18 E-E-A-T 검증 배치14 (S4 색인 회복) — AuditCase(지방계약법 조문맵 정합분만).
#
# ⚠️ 무결성 원칙(배치6/12와 동일): 이 사례들은 LLM이 공개 감사패턴을 일반화한 합성 콘텐츠(특정 실사례 아님).
# 실제 감사 출처처럼 attest 금지. verification_source에 합성/일반화임을 정직 공시.
# attest 대상 = legal_basis 조문 라벨이 law.go.kr 정본(LBOX·법제처 easylaw 2026-06-18 대조)과 정합하고
#   검증 토픽에 정렬된 사례만.
#
# 1차출처 대조로 확정한 조문 제목(이번 배치 attest 근거, LBOX 법령 뷰어 2026-06-18):
#   지방계약법 시행령 §25=수의계약에 의할 수 있는 경우 / §25①1호=소액 수의계약 /
#     §30=수의계약대상자의 선정절차 등 / §73=물가 변동으로 인한 계약금액의 조정 /
#     §74=설계변경으로 인한 계약금액의 조정 / §77=공사의 분할계약 금지 / §78=장기계속계약과 계속비계약
#   지방계약법(법률) §9=계약의 방법 / 형법 §227=허위공문서작성등
#
# ✅ 신규 attest 자격(batch12에서 §77 미확정으로 보류했던 건 → batch13에서 §77=공사의 분할계약 금지 확정):
#   private-contract-split-over-limit
#
# ⛔ 제외(legal_basis 라벨 부정확/미확정 → content-fix 선행 필요, 별도 트랙 batch15):
#   §53을 "검사"로 인용(실제 시행령 §53≠검사, §64=검사): completion-inspection-violation·defective-inspection·
#     goods-inspection-failure·inspection-procedure-omission·inspector-qualification-violation·payment-advance-misuse
#   "소프트웨어산업 진흥법"(폐지·전부개정 → 「소프트웨어 진흥법」 2020): software-dev-misclassified-as-goods
#   §58을 "검사"로 인용(실제 §64=검사): completion-payment-checklist-001
#   법§6을 "계약의 원칙"으로 인용(시행령 §6=계약사무 위임·위탁, 법§6 제목 미확정): goods-selection-committee-bypassed
#   §13/§49 매핑 재검토 필요: private-contract-retroactive

SLUGS = %w[
  contract-amount-adjustment-001
  additional-contract-limit-001
  long-term-contract-annual-omission
  false-private-contract-reason
  private-contract-split-over-limit
  bid-failure-negotiation-001
].freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 18)

updated = 0
missing = []
skipped = []
SLUGS.each do |slug|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  lb = a.legal_basis.to_s.strip
  budget = 200 - prefix.length - suffix.length
  lb_fit = lb.length > budget ? lb[0, budget - 1] + "…" : lb
  src = "#{prefix}#{lb_fit}#{suffix}"
  if src.length > 200
    skipped << "#{slug}(len#{src.length})"; next
  end
  a.update_columns(
    verification_source: src,
    verification_method: method,
    last_verified_at: verified_at
  )
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{SLUGS.size}건 (2026-06-18 배치14 — AuditCase 지방계약법 정합분)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts "⚠️  길이초과 skip: #{skipped.join(', ')}" if skipped.any?
