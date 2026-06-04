# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치10 (제N조 의미오기 감사 #5: 계약원칙·계약해제해지·검사)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04):
#   본법(253973): §6=계약의 원칙·§12=입찰보증금·§23=회계연도 시작 전 또는 예산배정 전의 계약체결·
#     §30=지연배상금 등·§30의2=계약의 해제ㆍ해지 등·§31=부정당업자의 입찰 참가자격 제한.
#   시행령(286149): §60=주민참여감독자의 감독 대상 공사·§61=주민참여감독자의 감독범위·
#     §62=주민참여감독자의 감독조서·§64=검사·§71=하자보수보증금·§91=계약의 해제ㆍ해지 등 통지.
#
# 결함:
#   계약의 원칙을 §12(=입찰보증금)로, 계약 해제·해지를 §23(=회계연도전계약)으로,
#   계약 해제·해지 사유/효과를 시행령 §60/§61/§62(=주민참여감독자 조문!)로,
#   (공사 준공)검사를 지방계약법 시행령 §71(=하자보수보증금)로 오인용.
#
# 🛡️ 정정 매트릭스:
#   contract-termination.law: "제23조 (계약의 해제·해지)"→"제30조의2 (계약의 해제·해지)" /
#     "제12조 (계약의 원칙)"→"제6조 (계약의 원칙)"  (§15계약보증금·§30지체상금[=§30지연배상금]·§31=정확,무수정)
#   contract-termination.decree: §60/§61/§62(주민참여감독자) 오인용 → 해제·해지 근거 본법 §30의2로 재앵커
#     (구체 사유는 행안부 예규 「지방자치단체 공사계약 일반조건」; 시행령 §91은 통지).
#   contract-execution.law: "제12조 (계약의 원칙)"→"제6조 (계약의 원칙)"
#   construction-completion.law: "지방계약법 시행령 제71조 (검사)"→"지방계약법 시행령 제64조 (검사)"
# ⛔ 보류: design-change(시행령 §65/§66 설계변경 중복·본법 §19 계약변경 추가검증)·
#   construction-completion "국가계약법 시행령 §55(검사)"(국가 정본 미확보)·contract-execution decree §65(계약변경).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch10.rb})"'

fixes = [
  ["contract-termination", "law_content", [
    ["제23조 (계약의 해제·해지)", "제30조의2 (계약의 해제·해지)"],
    ["제12조 (계약의 원칙)", "제6조 (계약의 원칙)"]
  ]],
  ["contract-termination", "decree_content", [
    ["### 제60조 (발주기관의 계약 해제·해지 사유)", "### 발주기관의 계약 해제·해지 사유 (지방계약법 제30조의2)"],
    ["### 제61조 (계약상대자의 계약 해제·해지 사유)", "### 계약상대자의 계약 해제·해지 사유 (지방계약법 제30조의2)"],
    ["### 제62조 (해제·해지의 효과)", "### 해제·해지의 효과 (지방계약법 제30조의2)"]
  ]],
  ["contract-execution", "law_content", [
    ["제12조 (계약의 원칙)", "제6조 (계약의 원칙)"]
  ]],
  ["construction-completion", "law_content", [
    ["지방계약법 시행령 제71조 (검사)", "지방계약법 시행령 제64조 (검사)"]
  ]]
]

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"; next
  end
  content = topic.public_send(field).to_s
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s); matched << "OK"
    else
      matched << "MISS"
    end
  end
  topic.update!(field => content)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end
puts "[content_fix batch10] #{results.join(' | ')}"

puts "--- 잔존 검증 ---"
checks = {
  "contract-termination" => {
    law_content: ["제23조 (계약의 해제·해지)", "제12조 (계약의 원칙)"],
    decree_content: ["### 제60조 (발주기관의 계약 해제·해지 사유)", "### 제61조 (계약상대자의 계약 해제·해지 사유)", "### 제62조 (해제·해지의 효과)"]
  },
  "contract-execution" => { law_content: ["제12조 (계약의 원칙)"] },
  "construction-completion" => { law_content: ["지방계약법 시행령 제71조 (검사)"] }
}
checks.each do |slug, fmap|
  t = Topic.find_by(slug: slug); next unless t
  fmap.each do |f, pats|
    pats.each do |pat|
      n = t.public_send(f).to_s.scan(pat).size
      puts "  #{slug}.#{f} '#{pat}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
    end
  end
end
