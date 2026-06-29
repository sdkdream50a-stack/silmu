# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix 후 attest 배치24 — 선금 클러스터 2건 법령근거 정정.
#
# ⚠️ 무결성 원칙(배치6/12~23과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX/law.go.kr, 2026-06-29):
#   지방계약법(법률) §15=계약보증금(≠대가의 지급) / §17=검사 / §6=계약의 원칙
#   시행령 §59=주민참여감독자 관련(≠선금) / §53=계약보증금 면제(≠선금)
#   시행규칙 §72=물가변동으로 인한 계약금액의 조정(≠선금 지급 한도)
#   ⇒ 지방계약법령에 '선금' 전용 조문 없음. 선금 근거=행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」(선금 지급/한도 70%·30% 등).
#
# 정정 사유: 두 케이스의 선금 법령 인용(§15·§59·§72·§17·§53)이 전부 선금과 무관한 조문 = 허위. 예규 근거+§6(계약의 원칙)으로 정정.
#   - improper-advance-payment: legal_basis 전면 정정 + lesson §2 "선금 지급 한도(시행규칙 제72조)"→예규. (70%/30% 한도 수치는 예규 정합, 유지)
#   - payment-advance-misuse: legal_basis 전면 정정. (본문에 조문 인용 없음)

verified_at = Date.new(2026, 6, 29)
method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"

FIXES = {
  "improper-advance-payment" => {
    set: {
      legal_basis: "지방자치단체 입찰 및 계약 집행기준(행정안전부 예규)의 선금 지급 관련 규정, 지방계약법 제6조(계약의 원칙)"
    },
    gsub: {
      lesson: [["선금 지급 한도 (지방계약법 시행규칙 제72조):", "선금 지급 한도 (지방자치단체 입찰 및 계약 집행기준, 행정안전부 예규):"]]
    },
    forbid: ["시행규칙 제72조", "시행령 제59조", "제15조 (대가의 지급)"] # 정정 후 잔존 금지
  },
  "payment-advance-misuse" => {
    set: {
      legal_basis: "지방자치단체 입찰 및 계약 집행기준(행정안전부 예규)의 선금 사용 관련 규정, 지방계약법 제6조(계약의 원칙)"
    },
    gsub: {},
    forbid: ["제17조", "시행령 제53조"]
  }
}.freeze

fixed = 0
attested = 0
missing = []
problems = []

FIXES.each do |slug, spec|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  attrs = spec[:set].dup
  spec[:gsub].each do |field, subs|
    val = a.public_send(field).to_s
    subs.each { |from, to| val = val.gsub(from, to) }
    attrs[field] = val if val != a.public_send(field).to_s
  end
  a.update!(attrs)
  fixed += 1
  a.reload
  # 잔존 금지어 검산(legal_basis + lesson)
  scope = "#{a.legal_basis} #{a.lesson}"
  spec[:forbid].each { |t| problems << "#{slug}:잔존[#{t}]" if scope.include?(t) }
  problems << "#{slug}:예규 미반영" unless a.legal_basis.include?("지방자치단체 입찰 및 계약 집행기준")
  # attest
  lb = a.legal_basis.to_s.strip
  b = 200 - prefix.length - suffix.length
  lbf = lb.length > b ? lb[0, b - 1] + "…" : lb
  src = "#{prefix}#{lbf}#{suffix}"
  if src.length <= 200
    a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
    attested += 1
  else
    problems << "#{slug}:src#{src.length}>200"
  end
end

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (배치24 — 선금 클러스터 법령근거 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(problems.any? ? "⛔ 검산 문제: #{problems.join(', ')}" : "✅ 검산 CLEAN(허위 선금조문 제거·예규 반영)")
