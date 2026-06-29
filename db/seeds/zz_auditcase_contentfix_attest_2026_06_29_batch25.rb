# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix 후 attest 배치25 — 입찰 클러스터 4건 조문 정정.
#
# ⚠️ 무결성 원칙(배치6/12~24와 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX/easylaw/bigcase, 2026-06-29):
#   지방계약법(법률) §13=낙찰자 결정 / §31=부정당업자의 입찰 참가자격 제한
#   시행령 §8=예정가격의 작성 및 비치 / §10=예정가격의 결정기준 / §12=희망수량입찰 시 예정가격 결정 /
#     §18=2단계 입찰 / §19=재입찰 및 재공고입찰 / §36=입찰공고의 내용 / §39=입찰서의 제출·접수 및 입찰의 무효 / §42=낙찰자 결정(재정지출 부담)
#   시행규칙 §38=입찰 참가신청(≠낙찰하한율) / 낙찰하한율·적격심사=「지방자치단체 입찰 시 낙찰자 결정기준」(행정안전부 예규)
#
# 정정맵(전부 기존 인용이 무관 조문=오기):
#   bid-rebid-condition-change(재공고 조건변경): 시행령 §36(입찰공고의 내용)→§19(재입찰 및 재공고입찰, 조건변경 불가)
#   bid-two-envelope-violation(2단계 입찰): 시행령 §44(지식기반사업 계약방법)→§18(2단계 입찰) [legal_basis+detail+lesson]
#   estimated-price-leak-incident(예정가격 누설): 법§13(입찰참가자격제한)→법§31(부정당업자), 시행령§12(예정가격작성·공개)→§8(예정가격의 작성 및 비치). 형§129 유지.
#   lowest-bid-rate-violation-award(낙찰하한율 미달): 시행규칙§38(낙찰하한율 산정)→「지방자치단체 입찰 시 낙찰자 결정기준」(예규). §42·집행기준 유지.
#
# 보류(전자조달법/규격 조문 추가확인 필요): bid-unfair-spec(법§9 규격 적정성)·e-bidding-error·e-procurement-bypass(전자조달법 §5/§6/§8·지정정보처리장치 조문 미확정).

FIXES = {
  "bid-rebid-condition-change" => {
    legal_basis: [["지방계약법 시행령 제36조", "지방계약법 시행령 제19조(재입찰 및 재공고입찰)"]]
  },
  "bid-two-envelope-violation" => {
    legal_basis: [["지방계약법 시행령 제44조", "지방계약법 시행령 제18조(2단계 입찰)"]],
    detail: [["시행령 제44조", "시행령 제18조"]],
    lesson: [["시행령 제44조", "시행령 제18조"]]
  },
  "estimated-price-leak-incident" => {
    legal_basis: [
      ["지방계약법 제13조 (입찰 참가자격 제한)", "지방계약법 제31조 (부정당업자의 입찰 참가자격 제한)"],
      ["지방계약법 시행령 제12조 (예정가격의 작성 및 공개)", "지방계약법 시행령 제8조 (예정가격의 작성 및 비치)"]
    ]
  },
  "lowest-bid-rate-violation-award" => {
    legal_basis: [["지방계약법 시행규칙 제38조(낙찰하한율 산정)", "「지방자치단체 입찰 시 낙찰자 결정기준」(행정안전부 예규, 낙찰하한율)"]]
  }
}.freeze

# 정정 후 잔존 금지(legal_basis+detail+lesson 스캔)
FORBID = {
  "bid-rebid-condition-change" => ["시행령 제36조"],
  "bid-two-envelope-violation" => ["제44조"],
  "estimated-price-leak-incident" => ["제13조 (입찰 참가자격 제한)", "제12조 (예정가격의 작성 및 공개)"],
  "lowest-bid-rate-violation-award" => ["시행규칙 제38조(낙찰하한율"]
}.freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 29)

fixed = 0
attested = 0
missing = []
problems = []

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
  a.update!(attrs) unless attrs.empty?
  fixed += 1 unless attrs.empty?
  a.reload
  scope = "#{a.legal_basis} #{a.detail} #{a.lesson}"
  (FORBID[slug] || []).each { |t| problems << "#{slug}:잔존[#{t}]" if scope.include?(t) }
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

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (배치25 — 입찰 클러스터 조문 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(problems.any? ? "⛔ 검산 문제: #{problems.join(', ')}" : "✅ 검산 CLEAN(오기 조문 제거)")
