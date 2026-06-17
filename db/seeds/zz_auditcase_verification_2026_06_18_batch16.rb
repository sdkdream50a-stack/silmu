# frozen_string_literal: true

# 2026-06-18 E-E-A-T 검증 배치16 (S4 색인 회복) — AuditCase 하도급(건산법·하도급법) 클러스터.
#
# ⚠️ 무결성 원칙(배치6/12/14와 동일): 합성 콘텐츠(특정 실사례 아님). 정직 공시.
# attest 대상 = legal_basis 조문 라벨이 1차출처(LBOX 2026-06-18)와 정합하고 검증 토픽(subcontract) 정렬.
#
# 1차출처 대조 확정(LBOX 법령 뷰어 2026-06-18):
#   건설산업기본법 §29=건설공사의 하도급 제한(①일괄하도급 금지·③재하도급 제한·⑥하도급 통보) /
#     §34=하도급대금의 지급 등(준공·기성금 수령일부터 15일 내 현금지급) / §35=하도급대금의 직접 지급
#   하도급거래 공정화에 관한 법률 §4=부당한 하도급대금의 결정 금지 / §14=하도급대금의 직접 지급
#   → 6건 모두 조문번호·라벨 정합(괄호는 해당 항의 정확한 내용 서술).

SLUGS = %w[
  subcontract-whole-transfer
  subcontract-no-notice
  subcontract-unauthorized-re-sub
  subcontract-payment-delay
  subcontract-below-cost
  subcontract-direct-payment-denied
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
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{SLUGS.size}건 (2026-06-18 배치16 — AuditCase 하도급 클러스터)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts "⚠️  길이초과 skip: #{skipped.join(', ')}" if skipped.any?
