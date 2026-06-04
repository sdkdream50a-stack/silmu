# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치14 (제N조 의미오기 감사 #9: 설계변경·장기계속 구조 reframe)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04, 지방계약법 본법253973·시행령286149):
#   본법 §22 = 물가 변동 등에 따른 계약금액의 조정(① "물가 변동 및 설계 변경, 그 밖에 계약내용의 변경"
#     명시 → 본법§22는 설계변경 조정의 본법 근거로 정확) · §24 = 장기계속계약 및 계속비계약(정확).
#   시행령 §65=검사조서의 작성 생략·§66=감독과 검사 직무의 겸직·§67=대가의 지급·
#     §74=설계 변경으로 인한 계약금액의 조정·§78=장기계속계약과 계속비계약.
#
# 결함(하나의 실제 조문을 틀린 번호 여러 개로 분할):
#   design-change.decree: 설계변경을 §65(=검사조서생략)·§66(=감독검사겸직)로(실제 설계변경 조정=§74, §74는 정확 존재).
#   long-term-contract.decree: 장기계속/계속비를 §65·§66·§67로(실제=§78 단일조, 본법§24).
#
# 🛡️ 정정(틀린 번호 제거·§74/§78로 재앵커, 내용 보존):
#   design-change.decree: "### 제65조 (설계변경)"→"### 설계변경의 요건·사유 (시행령 제74조·「지방자치단체 공사계약 일반조건」)" /
#     "### 제66조 (설계변경으로 인한 계약금액의 조정)"→"### 설계변경 계약금액 조정방법 (시행령 제74조)"  (### 제74조=정확 유지)
#   long-term-contract.decree: 시행령 §65·§66·범위헤더 → §78(장기계속계약과 계속비계약)
# ⛔ 보류: design-change.law §19(계약의 변경)=대가선납 →본법§22 소관이나 관련조항 중복으로 모호. (법§22 설계변경=본법§22 ①명시로 정확, 무수정)
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch14.rb})"'

fixes = [
  ["design-change", "decree_content", [
    ["### 제65조 (설계변경)", "### 설계변경의 요건·사유 (지방계약법 시행령 제74조·「지방자치단체 공사계약 일반조건」)"],
    ["### 제66조 (설계변경으로 인한 계약금액의 조정)", "### 설계변경 계약금액 조정방법 (지방계약법 시행령 제74조)"]
  ]],
  ["long-term-contract", "decree_content", [
    ["## 지방계약법 시행령 제65조~제67조 (장기계속계약)", "## 지방계약법 시행령 제78조 (장기계속계약과 계속비계약)"],
    ["**지방계약법 시행령 제65조 (장기계속계약)**", "**지방계약법 시행령 제78조 (장기계속계약)**"],
    ["**지방계약법 시행령 제66조 (계속비계약)**", "**지방계약법 시행령 제78조 (계속비계약)**"]
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
puts "[content_fix batch14] #{results.join(' | ')}"

puts "--- 잔존 검증 ---"
checks = {
  "design-change" => { decree_content: ["### 제65조 (설계변경)", "### 제66조 (설계변경으로 인한 계약금액의 조정)"] },
  "long-term-contract" => { decree_content: ["시행령 제65조~제67조", "시행령 제65조 (장기계속계약)", "시행령 제66조 (계속비계약)"] }
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
# §74·§78 출현 확인
%w[design-change long-term-contract].each do |slug|
  t=Topic.find_by(slug:slug); next unless t; d=t.decree_content.to_s
  puts "  #{slug}: 시행령제74조=#{d.scan('시행령 제74조').size} 시행령제78조=#{d.scan('시행령 제78조').size}"
end
