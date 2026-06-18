# frozen_string_literal: true

# 2026-06-18 E-E-A-T content-fix 후 attest 배치17 (S4 색인 회복) — 공무원복무 조문 정정.
#
# ⚠️ 무결성 원칙(배치6/12~16과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX 법령 뷰어 2026-06-18):
#   지방공무원 복무규정 **구조개정**: 병가=제7조의5 / 공가=제7조의6 / 특별휴가=제7조의7
#     (현행 제11조=겸직 허가). silmu의 제10조(병가)·제11조(공가)·제14조(특별휴가)=구 조번호 오기.
#   지방공무원법 **제57조=정치운동의 금지**(≠"복무") → 휴가 사례의 "제57조(복무)" 인용은 무관 조문 → 삭제
#     (국가·지방 복무규정 조문이 실질 근거. 대체 조문 임의 부여 대신 외과적 제거).
#   국가공무원 복무규정 제18조=병가·제19조=공가·제20조=특별휴가(현행 유지) / 정보공개법 제9·11·18(정합).
#
# 정정맵(legal_basis only — 전 필드 스캔 결과 구 조번호·§57은 legal_basis에만 존재):
#   sick-leave-days-exceeded:        지방복무규정 제10조(병가) → 제7조의5(병가) + §57 제거
#   official-leave-false-reason:     지방복무규정 제11조(공가) → 제7조의6(공가) + §57 제거
#   special-leave-holiday-miscalc.:  지방복무규정 제14조(특별휴가) → 제7조의7(특별휴가) + §57 제거
# CLEAN attest(정정 없음): information-disclosure-delay (정보공개법 §9·§11·§18 정합).

FIXES = {
  "sick-leave-days-exceeded" => [
    ["지방공무원 복무규정 제10조(병가)", "지방공무원 복무규정 제7조의5(병가)"],
    [", 지방공무원법 제57조(복무)", ""]
  ],
  "official-leave-false-reason" => [
    ["지방공무원 복무규정 제11조(공가)", "지방공무원 복무규정 제7조의6(공가)"],
    [", 지방공무원법 제57조(복무)", ""]
  ],
  "special-leave-holiday-miscalculation" => [
    ["지방공무원 복무규정 제14조(특별휴가)", "지방공무원 복무규정 제7조의7(특별휴가)"],
    [", 지방공무원법 제57조(복무)", ""]
  ]
}.freeze
CLEAN = %w[information-disclosure-delay].freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 18)

def attest!(a, prefix, suffix, method, verified_at)
  lb = a.legal_basis.to_s.strip
  budget = 200 - prefix.length - suffix.length
  lb_fit = lb.length > budget ? lb[0, budget - 1] + "…" : lb
  src = "#{prefix}#{lb_fit}#{suffix}"
  return "src#{src.length}" if src.length > 200
  a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
  nil
end

fixed = 0
attested = 0
missing = []
residual = []

FIXES.each do |slug, subs|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  new_lb = a.legal_basis.to_s
  subs.each { |from, to| new_lb = new_lb.gsub(from, to) }
  if new_lb != a.legal_basis.to_s
    a.update!(legal_basis: new_lb)
    fixed += 1
  end
  a.reload
  residual << "#{slug}(제57조)" if a.legal_basis.to_s.include?("제57조")
  residual << "#{slug}(구조번호)" if subs.any? { |from, _| a.legal_basis.to_s.include?(from) }
  e = attest!(a, prefix, suffix, method, verified_at)
  e ? residual << "#{slug}(#{e})" : attested += 1
end

CLEAN.each do |slug|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  e = attest!(a, prefix, suffix, method, verified_at)
  e ? residual << "#{slug}(#{e})" : attested += 1
end

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (2026-06-18 배치17 — 지방복무규정 조번호 정정 3 + 정보공개 1)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(residual.any? ? "⛔ 잔존: #{residual.join(', ')}" : "✅ 잔존오기 CLEAN")
