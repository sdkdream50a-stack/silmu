# frozen_string_literal: true

# 2026-06-18 E-E-A-T 검증 배치18 (S4 색인 회복) — AuditCase 입찰 클러스터(라벨 정합분만).
#
# ⚠️ 무결성 원칙(배치6/12/14/16과 동일): 합성 콘텐츠. 정직 공시. update_columns 메타 전용·멱등.
# attest 대상 = legal_basis 조문 라벨이 1차출처(LBOX 2026-06-18)와 정합하고 검증 토픽 정렬.
#
# 1차출처 대조 확정(LBOX 법령 뷰어 2026-06-18):
#   지방계약법 시행령 §9=예정가격의 결정방법 / §18=규격가격 분리입찰 / §39=입찰서의 제출·접수 및 입찰의 무효 /
#     §42=재정지출의 부담이 되는 입찰에서의 낙찰자 결정(적격심사=그 심사방법) / §88=공동계약
#   지방계약법(법률) §31=부정당업자의 입찰 참가자격 제한 / 형법 §123=직권남용
#
# ⛔ 제외(legal_basis 라벨 오기 → content-fix 선행, batch19 트랙):
#   §44(=지식기반사업 등의 계약방법)를 2단계입찰로 인용: bid-two-envelope-violation (→시행령§18)
#   §12(=희망수량입찰 시 예정가격 결정)를 "예정가격 작성·공개"로 인용: estimated-price-leak-incident
#   §39(=입찰서 무효)를 "지정정보처리장치 이용"으로 인용: e-procurement-bypass-narajangteo
#   법§9(=계약의 방법)를 "입찰참가자격"으로 인용: bid-deposit-001
#   §38·§36 라벨 미확정: e-bidding-error-switched-to-paper·bid-rebid-condition-change·bid-unfair-spec·lowest-bid-rate(시행규칙§38 미확정)

SLUGS = %w[
  joint-contract-nominal
  multiple-price-manipulation
  qualification-failure-wrong-award
  bid-qualification-001
  spec-price-integration-violation
  e-bidding-offline-processed
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
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{SLUGS.size}건 (2026-06-18 배치18 — AuditCase 입찰 정합분)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts "⚠️  길이초과 skip: #{skipped.join(', ')}" if skipped.any?
