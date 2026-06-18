# frozen_string_literal: true

# 2026-06-18 E-E-A-T content-fix 후 attest 배치19 (S4 색인 회복) — 대금지급·입찰 조문 정정.
#
# ⚠️ 무결성 원칙(배치6/12~18과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX 법령 뷰어 2026-06-18):
#   지방계약법 시행령 §64=검사 / §67=대가의 지급(법§18②에 따라 §64 검사 완료 후 지급) /
#     §63=주민참여감독자의 교육(대가지급 아님) / §58=납품·예정가격 무관(≠검사)
#   지방계약법(법률) §18=대가의 지급 / §19=대가의 선납(수입계약) / §9=계약의 방법
#
# 정정맵:
#   completion-payment-checklist-001(준공금 지급):
#     title "시행령 제58조"→"제64조"(검사) / legal_basis 제58조(검사)→제64조·제63조(대가의 지급)→제67조·법률 제19조→제18조
#   bid-deposit-001(입찰보증금): legal_basis 법 제9조 괄호 "(입찰참가자격)"→"(계약의 방법)"(§9 정본 제목)
#
# 보류(조문 미확정): bid-two-envelope(2단계 경쟁입찰 조문 ≠ §18 규격가격분리, 별도 확인) ·
#   improper-advance·payment-advance(지방 시행령 전용 선금 조문 부재 추정, 예규 기반 — §59=주민참여감독자 실비로 확인됨)

FIXES = {
  "completion-payment-checklist-001" => {
    title: [["시행령 제58조", "시행령 제64조"]],
    legal_basis: [
      ["제58조(검사)", "제64조(검사)"],
      ["제63조(대가의 지급)", "제67조(대가의 지급)"],
      ["법률 제19조", "법률 제18조"]
    ]
  },
  "bid-deposit-001" => {
    legal_basis: [["제9조(입찰참가자격)", "제9조(계약의 방법)"]]
  }
}.freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 18)

fixed = 0
attested = 0
missing = []
residual = []

FIXES.each do |slug, fieldmap|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  attrs = {}
  fieldmap.each do |field, subs|
    val = a.public_send(field).to_s
    subs.each { |from, to| val = val.gsub(from, to) }
    attrs[field] = val if val != a.public_send(field).to_s
  end
  unless attrs.empty?
    a.update!(attrs)
    fixed += 1
  end
  a.reload
  # 잔존 검산: 정정 전 문자열이 남아있으면 경고
  fieldmap.each do |field, subs|
    subs.each { |from, _| residual << "#{slug}.#{field}(#{from})" if a.public_send(field).to_s.include?(from) }
  end
  lb = a.legal_basis.to_s.strip
  budget = 200 - prefix.length - suffix.length
  lb_fit = lb.length > budget ? lb[0, budget - 1] + "…" : lb
  src = "#{prefix}#{lb_fit}#{suffix}"
  if src.length <= 200
    a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
    attested += 1
  else
    residual << "#{slug}(src#{src.length})"
  end
end

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (2026-06-18 배치19 — 대금지급·입찰 조문 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(residual.any? ? "⛔ 잔존: #{residual.join(', ')}" : "✅ 잔존오기 CLEAN")
