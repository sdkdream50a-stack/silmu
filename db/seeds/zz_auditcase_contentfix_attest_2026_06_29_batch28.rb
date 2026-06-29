# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix 후 attest 배치28 — 복무 클러스터 4건 조문 정정.
#
# ⚠️ 무결성 원칙(배치6/12~27과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(bigcase 조문별, 2026-06-29) — 복무규정 인용이 광범위하게 오기:
#   국가공무원 복무규정 §15=연가 일수 / §17=연가 일수에서의 공제(≠연가보상비) / §25=영리 업무의 금지 / §26=겸직 허가(≠휴직자 신고) / §28=사실상 노무에 종사하는 공무원(≠파견)
#   지방공무원 복무규정 §7의2=연가 일수의 공제(≠연가보상비)
#   공무원수당 등에 관한 규정 §18의5=연가보상비(정본) / 고용보험법 §70=육아휴직 급여·§73=육아휴직 급여의 지급 제한 등
#   국가공무원법 §32의4=파견근무·§64=영리 업무 및 겸직 금지·§71=휴직(②4 육아휴직 사유)·§73=휴직의 효력
#   지방공무원법 §30의2=인사교류(≠파견)·§30의4=파견근무·§63=휴직·§65=휴직의 효력 / 공무원임용령 §41=파견근무(기간·연장)
#
# 정정맵:
#   annual-leave-compensation: 연가보상비=복무규정§17·지방§7의2(둘 다 연가일수 공제, 오기)→공무원수당 규정 §18의5. legal_basis+lesson.
#   leave-of-absence: 복무규정§26(겸직 허가, 오기)→§25(영리 업무의 금지)+국가공무원법§64. legal_basis.
#   secondment: 지방§30의2(인사교류, 오기)→§30의4(파견근무), 복무규정§28(노무종사, 오기)→공무원임용령§41(파견근무). legal_basis+detail.
#   parental-leave: 육아휴직 급여=남녀고용평등법§19의4(사용형태, 오기)→고용보험법§70. legal_basis. (나머지 §73부정수급·공무원법 휴직조문=정합)
#
# 보류: disciplinary-action-request-delay — 지방(△△군) 사례인데 title "국가공무원법 위반"+국가§83의2 시효 인용(지방=§73의2), §72 괄호 "징계의결 요구"≠§72(징계 등 절차). 국가/지방 프레이밍 재서술 필요(별도).

FIXES = {
  "annual-leave-compensation-double-payment" => {
    set: { legal_basis: "국가공무원 복무규정 제15조(연가 일수), 공무원수당 등에 관한 규정 제18조의5(연가보상비)" },
    gsub: { lesson: [["국가공무원 복무규정 제17조 및 지방공무원 복무규정 제7조의2에", "공무원수당 등에 관한 규정 제18조의5에"]] },
    forbid: ["복무규정 제17조", "제7조의2"]
  },
  "leave-of-absence-employment-unreported" => {
    set: { legal_basis: "국가공무원법 제64조(영리 업무 및 겸직 금지)·제73조(휴직의 효력), 지방공무원법 제63조(휴직), 국가공무원 복무규정 제25조(영리 업무의 금지)" },
    gsub: {},
    forbid: ["복무규정 제26조", "휴직자 신고 의무"]
  },
  "secondment-return-delay" => {
    set: { legal_basis: "국가공무원법 제32조의4(파견근무), 지방공무원법 제30조의4(파견근무), 공무원임용령 제41조(파견근무)" },
    gsub: { detail: [["복무규정 제28조", "공무원임용령 제41조"]] },
    forbid: ["제30조의2", "복무규정 제28조"]
  },
  "parental-leave-benefit-double-receipt" => {
    set: {},
    gsub: { legal_basis: [["남녀고용평등과 일·가정 양립 지원에 관한 법률 제19조의4(육아휴직 급여)", "고용보험법 제70조(육아휴직 급여)"]] },
    forbid: ["제19조의4"]
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
problems = []

FIXES.each do |slug, spec|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  attrs = (spec[:set] || {}).dup
  (spec[:gsub] || {}).each do |field, subs|
    base = attrs[field] || a.public_send(field).to_s
    val = base.dup
    subs.each { |from, to| val = val.gsub(from, to) }
    attrs[field] = val if val != a.public_send(field).to_s
  end
  a.update!(attrs) unless attrs.empty?
  fixed += 1 unless attrs.empty?
  a.reload
  scope = "#{a.legal_basis} #{a.detail} #{a.lesson}"
  (spec[:forbid] || []).each { |t| problems << "#{slug}:잔존[#{t}]" if scope.include?(t) }
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

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (배치28 — 복무 클러스터 조문 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(problems.any? ? "⛔ 검산 문제: #{problems.join(', ')}" : "✅ 검산 CLEAN(복무규정 오기 제거)")
