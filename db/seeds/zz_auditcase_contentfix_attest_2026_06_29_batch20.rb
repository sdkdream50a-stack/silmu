# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix 후 attest 배치20 (S4 색인 회복) — 단건(topic 무소속) 처리.
#
# ⚠️ 무결성 원칙(배치6/12~19과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX/easylaw/law.go.kr 교차, 2026-06-29):
#   건설기술진흥법 §62=건설공사의 안전관리 / 산업안전보건법 §38=안전조치
#   지방계약법 §17=검사 / 시행령 §64=검사 / 형법 §129=수뢰죄
#   건설산업기본법 §82=영업정지 등 (※ "부정행위 금지" 아님; 부실시공 중대손괴는 §83제10호 등록말소·영업정지)
#
# 정정맵:
#   defective-construction-cover-up: legal_basis "제82조 (부정행위 금지)"→"제82조 (영업정지 등)"(§82 정본 제목)
#   safety-violation-construction: CLEAN(조문 2개 제목·맥락 정합) → 정정 없이 attest만
#
# 보류(별도 라운드): budget-unauthorized-transfer(전용§49↔이용§47의2 혼동, 재프레이밍 필요) ·
#   property-disposal-no-appraisal(시행령§38 제목 미확정 + "2개 이상 감정평가법인" stale 의심, §27③ 단수 허용 개정) ·
#   revenue-collection-delay(§82=소멸시효 off-point → 지방세외수입금법 §8 독촉·§9 압류 재선정 권장)

FIXES = {
  "defective-construction-cover-up" => {
    legal_basis: [["(부정행위 금지)", "(영업정지 등)"]]
  },
  "safety-violation-construction" => {} # CLEAN: content-fix 없음, attest만
}.freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 29)

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

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (2026-06-29 배치20 — 단건 safety attest + defective §82 제목 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(residual.any? ? "⛔ 잔존: #{residual.join(', ')}" : "✅ 잔존오기 CLEAN")
