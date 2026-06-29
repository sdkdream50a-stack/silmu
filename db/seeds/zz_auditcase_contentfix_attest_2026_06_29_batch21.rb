# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix 후 attest 배치21 (S4 색인 회복) — 단건 property 조문 정정.
#
# ⚠️ 무결성 원칙(배치6/12~20과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX/easylaw/law.go.kr 교차, 2026-06-29):
#   공유재산법 §36=일반재산의 매각(법률, 매각 근거) /
#   공유재산법 시행령 §27=일반재산가격의 평정 등(처분 예정가격=시가, 2인 이상 감정평가법인 산술평균액 이상) ← 감정평가 의무 정본
#   ※ 본문 "2개 이상 감정평가법인 평가 의무"=현행 정합(시행령 §27, stale 아님). 시행령 §38은 본 사례(감정평가)와 무관 → §27로 정정.
#
# 정정맵:
#   property-disposal-no-appraisal: legal_basis "동법 시행령 제38조"→"동법 시행령 제27조(일반재산가격의 평정)",
#     "공유재산법 제36조,"→"공유재산법 제36조(일반재산의 매각)," (조문 제목 명시)
#
# 보류(citation 정정 불가, 본문 authoring 필요 — 진단=task.md "단건 5건" 섹션):
#   budget-unauthorized-transfer: 전용(§49)/이용(§47의2) 개념 혼동이 title·issue·detail·lesson·action_taken·checkpoints 6필드에 분산.
#     사례=정책사업 간 융통(=이용 §47의2, 의회 의결 필요)인데 "전용 §49"로 표기. 단 lesson §2 "동일 정책사업 내 전용=기관장 승인"은 정확
#     → 기계적 치환 불가, 개념 재작성 필요(별도 패스).
#   revenue-collection-delay: 인용법 「지방세외수입금의 징수 등에 관한 법률」=2021 「지방행정제재·부과금의 징수 등에 관한 법률」로 개칭 +
#     본문 "납기 후 10일 이내 독촉장 발송"=사실오류(§8 독촉=납기경과 50일 이내 발급, 10일은 독촉장상 납부기한) +
#     사용료·수수료가 개칭법 적용범위인지 scope 확인 필요 → 법령 현행성+본문 authoring 동반(별도 패스).

FIXES = {
  "property-disposal-no-appraisal" => {
    legal_basis: [
      ["공유재산법 제36조,", "공유재산법 제36조(일반재산의 매각),"],
      ["동법 시행령 제38조", "동법 시행령 제27조(일반재산가격의 평정)"]
    ]
  }
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

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (2026-06-29 배치21 — 단건 property 시행령 §38→§27 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(residual.any? ? "⛔ 잔존: #{residual.join(', ')}" : "✅ 잔존오기 CLEAN")
