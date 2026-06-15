# frozen_string_literal: true

#
# 토픽 본문 법령결함 정정 — 배치15 (제N조 의미오기 감사 #10: estimated-price.decree REFRAME)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04, 지방계약법 시행령286149·시행규칙285747):
#   시행령 §7=추정가격의 산정 · §8=예정가격의 작성 및 비치 · §9=예정가격의 결정방법(총액주의) ·
#     §10=예정가격의 결정기준(①"다음 각 호의 가격을 기준으로 예정가격 결정"=거래실례·원가·표준시장·감정·유사거래) · §11=입찰방법.
#   시행규칙 §4=예정가격조서의 작성 · §5=거래실례가격 및 표준시장단가에 따른 예정가격의 결정 ·
#     §6=원가계산에 의한 예정가격의 결정(재료비·노무비·경비·일반관리비·이윤 비목).
#   복수예비가격=시행령/시행규칙 조문 부재 → 근거=행정안전부 예규「지방자치단체 입찰 및 계약집행기준」.
#
# 결함(estimated-price.decree: 예정가격 산정 메커니즘을 시행령 조문번호에 잘못 귀속, 실제는 시행령§10+시행규칙§4~6+예규):
#   "### 제7조 (예정가격의 결정)"  실제 §7=추정가격의 산정 (본문=결정기준 §10 내용)
#   "### 제8조 (거래실례가격)"      실제 §8=예정가격의 작성 및 비치 (본문 거래실례=시행규칙§5)
#   "### 제9조 (원가계산에 의한 예정가격)" 실제 §9=예정가격의 결정방법 (본문 원가계산 비목=시행규칙§6)
#   "### 제10조 (복수예비가격)"     실제 §10=예정가격의 결정기준 (복수예비가격=조문부재·예규)
#   "### 제11조 (예정가격조서)"     실제 §11=입찰방법 (예정가격조서=시행규칙§4)
#
# 🛡️ 정정(올바른 조문으로 재앵커·수치/본문 보존):
#   섹션 헤더 → 예정가격의 결정 (시행령·시행규칙)
#   제7조→시행령 제10조(결정기준) / 제8조→시행규칙 제5조 / 제9조→시행규칙 제6조 /
#   제10조→복수예비가격 예규 / 제11조→시행규칙 제4조
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch15.rb})"'

fixes = [
  [ "estimated-price", "decree_content", [
    [ "## 지방계약법 시행령 — 예정가격 관련 조항", "## 예정가격의 결정 (지방계약법 시행령·시행규칙)" ],
    [ "### 제7조 (예정가격의 결정)", "### 지방계약법 시행령 제10조 (예정가격의 결정기준)" ],
    [ "### 제8조 (거래실례가격)", "### 지방계약법 시행규칙 제5조 (거래실례가격에 따른 예정가격의 결정)" ],
    [ "### 제9조 (원가계산에 의한 예정가격)", "### 지방계약법 시행규칙 제6조 (원가계산에 의한 예정가격의 결정)" ],
    [ "### 제10조 (복수예비가격)", "### 복수예비가격 (행정안전부 예규「지방자치단체 입찰 및 계약집행기준」)" ],
    [ "### 제11조 (예정가격조서)", "### 지방계약법 시행규칙 제4조 (예정가격조서의 작성)" ]
  ] ]
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
puts "[content_fix batch15] #{results.join(' | ')}"

puts "--- 잔존 검증 (틀린 헤더 0이어야 함) ---"
checks = {
  "estimated-price" => { decree_content: [
    "## 지방계약법 시행령 — 예정가격 관련 조항",
    "### 제7조 (예정가격의 결정)",
    "### 제8조 (거래실례가격)",
    "### 제9조 (원가계산에 의한 예정가격)",
    "### 제10조 (복수예비가격)",
    "### 제11조 (예정가격조서)"
  ] }
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
# 정정 앵커 출현 확인
t = Topic.find_by(slug: "estimated-price")
if t
  d = t.decree_content.to_s
  puts "  estimated-price 앵커: 시행령제10조=#{d.scan('시행령 제10조').size} 시행규칙제5조=#{d.scan('시행규칙 제5조').size} 시행규칙제6조=#{d.scan('시행규칙 제6조').size} 시행규칙제4조=#{d.scan('시행규칙 제4조').size} 복수예비가격예규=#{d.scan('복수예비가격 (행정안전부 예규').size}"
end
