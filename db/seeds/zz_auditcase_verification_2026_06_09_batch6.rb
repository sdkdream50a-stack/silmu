# frozen_string_literal: true
# 2026-06-09 E-E-A-T 검증 배치6 (S4 색인 회복) — AuditCase(검증 토픽 정렬·legal_basis 정합분만).
#
# ⚠️ 무결성 원칙: 이 사례들은 LLM이 공개 감사패턴을 일반화한 합성 콘텐츠(특정 실사례 아님).
# 실제 감사 출처처럼 attest 금지. verification_source에 합성/일반화임을 정직 공시(기적용 32건과 동일 컨벤션).
# attest 대상 = legal_basis가 검증된 지방계약법 조문맵과 정합하고 검증 토픽에 정렬된 사례만.
# 제외(legal_basis 주제 불일치): payment-advance-misuse(§17/§53)·bid-two-envelope-violation(§44)·
#   bid-rebid-condition-change(§36)·private-contract-retroactive(§13/§49).
# verification_source ≤200, verification_method ≤32 가드.

SLUGS = %w[
  private-contract-no-quote inspection-by-requester private-contract-same-vendor
  contract-no-guarantee-forfeiture private-contract-split contract-late-execution
  contract-guarantee-exemption-wrong late-penalty-wrong-rate defect-warranty-no-deposit
  payment-delay-no-interest contract-missing-special-terms payment-no-deduction-penalty
  bid-qualification-review-omitted defect-warranty-short-period contract-verbal-agreement
  bid-period-insufficient estimated-price-no-research bid-bond-not-submitted
  bid-qualification-excessive private-contract-over-limit late-penalty-not-imposed
  estimated-price-leak private-contract-purpose-mismatch private-contract-no-reason
  bid-evaluation-criteria-missing single-quote-exceeds-limit supervision-absent
  substitution-material-unapproved inspection-delayed payment-before-inspection
  payment-without-completion overpayment-not-recovered contract-wrong-party
  progress-payment-over-claimed
].freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 9)

updated = 0
missing = []
skipped = []
SLUGS.each do |slug|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  lb = a.legal_basis.to_s.strip
  # 총 길이 200 이내로 legal_basis 잘라넣기(조문 정보 보존 우선)
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
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{SLUGS.size}건 (2026-06-09 배치6 — AuditCase 정합분)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts "⚠️  길이초과 skip: #{skipped.join(', ')}" if skipped.any?
