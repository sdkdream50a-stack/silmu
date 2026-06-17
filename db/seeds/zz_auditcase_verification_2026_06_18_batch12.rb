# frozen_string_literal: true

# 2026-06-18 E-E-A-T 검증 배치12 (S4 색인 회복) — AuditCase(지방계약법 조문맵 정합분만).
#
# ⚠️ 무결성 원칙(배치6과 동일): 이 사례들은 LLM이 공개 감사패턴을 일반화한 합성 콘텐츠(특정 실사례 아님).
# 실제 감사 출처처럼 attest 금지. verification_source에 합성/일반화임을 정직 공시.
# attest 대상 = legal_basis 조문 라벨이 law.go.kr 정본(LBOX·법제처 easylaw 2026-06-18 대조)과 정합하고
#   검증 토픽에 정렬된 사례만.
#
# 1차출처 대조로 확정한 조문 제목(이번 배치 attest 근거):
#   지방계약법 시행령 §25=수의계약에 의할 수 있는 경우 / §30=수의계약대상자 선정절차 등 /
#     §53=계약보증금 면제 / §73=물가 변동으로 인한 계약금액의 조정 / §74=설계변경으로 인한 계약금액의 조정 / §90=지연배상금
#   지방계약법(법률) §15=계약보증금 / §30=지연배상금 등
#
# ⛔ 제외(legal_basis 라벨 부정확 → content-fix 선행 필요, 별도 트랙):
#   §7을 "경쟁의 원칙/계약의 원칙"으로 인용(실제 §7=계약사무의 위임·위탁): split-contract-to-avoid-bidding·
#     split-order-monthly-to-avoid-bidding·unit-price-contract-quantity-exceeded·small-amount-intentional-split
#   §13을 "경쟁입찰에 의한 계약"으로 인용(실제 §13=입찰의 참가자격): public-procurement-mandatory-bid-bypassed
#   §51을 "계약보증금"으로 인용(실제 §51=계약의 이행보증): contract-guarantee-not-collected
#   §60·§77 조문 제목 미확정(보수적 보류): contract-termination-no-notice·private-contract-split-over-limit 등

SLUGS = %w[
  price-escalation-below-threshold
  design-change-unapproved
  penalty-reduction-unauthorized
  performance-guarantee-waiver-loss
  emergency-contract-unjustified
  private-contract-price-no-negotiation
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
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{SLUGS.size}건 (2026-06-18 배치12 — AuditCase 지방계약법 정합분)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts "⚠️  길이초과 skip: #{skipped.join(', ')}" if skipped.any?
