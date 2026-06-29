# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix 후 attest 배치27 — 전자조달 2건 조문 정정(입찰 클러스터 defer 해소).
#
# ⚠️ 무결성 원칙(배치6/12~26과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(bigcase 조문별, 2026-06-29):
#   전자조달의 이용 및 촉진에 관한 법률: §5=조달업무의 전자적 처리 / §6=경쟁입찰의 전자적 공고 / §7=전자입찰(전자적 입찰서 제출 의무) / §8=계약상대자의 전자적 공고
#     동법 시행령: §6=전자공개수의계약 / §8=보증금의 전자적 납부 방법
#   지방계약법 시행령: §6의2=정보처리장치의 지정·고시(지정정보처리장치=나라장터) / §25=수의계약 / §38=입찰보증금의 세입조치 / §39=입찰서 제출·무효
#
# 정정 사유(전자입찰 의무=전자조달법 §7인데 기존이 §8로 오기, 지정정보처리장치=시행령§6의2인데 §39로 오기 등):
#   e-bidding-error-switched-to-paper: legal_basis 전면 — §8(전자입찰)→§7, 시행령§8(전자입찰 의무화→보증금)·시행령§38(입찰방법변경→입찰보증금세입) 제거, §6의2·이용약관§24·집행기준으로.
#   e-procurement-bypass-narajangteo: legal_basis §39(지정정보처리장치)→§6의2 +§7 추가. detail 표 §조 정정(전자조달법 시행령§6→법§6, §8→§7, §8제2항→지방계약 시행령§6의2).

FIXES = {
  "e-bidding-error-switched-to-paper" => {
    set: {
      legal_basis: "전자조달의 이용 및 촉진에 관한 법률 제7조(전자입찰), 지방계약법 시행령 제6조의2(정보처리장치의 지정·고시), 국가종합전자조달시스템 이용약관 제24조(시스템 장애 처리), 「지방자치단체 입찰 및 계약 집행기준」(전자입찰 운영·임의 변경 제한)"
    },
    gsub: {},
    forbid: ["제8조 (전자입찰)", "시행령 제8조 (전자입찰", "시행령 제38조 (입찰 방법 변경"]
  },
  "e-procurement-bypass-narajangteo" => {
    set: {
      legal_basis: "전자조달의 이용 및 촉진에 관한 법률 제5조(조달업무의 전자적 처리)·제6조(경쟁입찰의 전자적 공고)·제7조(전자입찰), 지방계약법 시행령 제6조의2(정보처리장치의 지정·고시), 「지방자치단체 입찰 및 계약 집행기준」(전자입찰 의무 대상), 감사원 감사 기준 — 전자조달 우회 계약 시 수의계약 위반"
    },
    gsub: {
      detail: [
        ["전자조달법 시행령 제6조", "전자조달법 제6조"],
        ["전자조달법 제8조 제2항", "지방계약법 시행령 제6조의2"],
        ["전자조달법 제8조", "전자조달법 제7조"]
      ]
    },
    forbid: ["시행령 제39조(지정정보처리장치", "전자조달법 제8조"]
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
  attrs = spec[:set].dup
  spec[:gsub].each do |field, subs|
    val = a.public_send(field).to_s
    subs.each { |from, to| val = val.gsub(from, to) }
    attrs[field] = val if val != a.public_send(field).to_s
  end
  a.update!(attrs)
  fixed += 1
  a.reload
  scope = "#{a.legal_basis} #{a.detail} #{a.lesson}"
  spec[:forbid].each { |t| problems << "#{slug}:잔존[#{t}]" if scope.include?(t) }
  problems << "#{slug}:§7 미반영" unless a.legal_basis.include?("제7조")
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

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (배치27 — 전자조달 조문 정정)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(problems.any? ? "⛔ 검산 문제: #{problems.join(', ')}" : "✅ 검산 CLEAN(전자입찰=§7·지정정보처리장치=§6의2 반영)")
