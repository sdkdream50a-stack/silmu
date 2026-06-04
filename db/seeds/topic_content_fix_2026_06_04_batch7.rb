# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치7 (제N조 의미오기 감사 #2: budget-carryover 지방재정법 예산이월 조문)
# 2026-06-04. cf. [[project_topic_content_defects_2026_06_03]].
#
# 정본(법제처 OPEN API 2026-06-04, MST=281909 지방재정법):
#   제42조 = 계속비 등 / 제48조 = 예산 절약에 따른 성과금의 지급 등 / 제49조 = 예산의 전용 /
#   제50조 = 세출예산의 이월(제1항 명시이월·제2항 사고이월).
#
# 결함: budget-carryover가 (a)계속비 근거를 §48(=성과금)로, (b)예산이월(명시·사고) 구분을
#   "§48 및 §49"로 인용 → 둘 다 오기. 계속비=§42, 이월(명시·사고)=§50.
#   ⚠️ §48이 4곳 출현하나 문맥별 정답 상이 → 문맥 특정 gsub로 외과적 정정.
#
# 🛡️ 정정 매트릭스(문맥 특정):
#   rule_content   "제48조에 따른 계속비"              → "제42조에 따른 계속비"
#   interpretation "계속비는 지방재정법 제48조에 따라"  → "계속비는 지방재정법 제42조에 따라"
#   regulation     "| 지방재정법 제48조 |"(계속비 열)  → "| 지방재정법 제42조 |"
#   commentary     "제48조 및 제49조에 따라 명시이월과 사고이월" → "제50조에 따라 명시이월과 사고이월"
# ⛔ 별도배치: budget-transfer "§47(이용·전용)"(이용=§47의2·전용=§49 재프레이밍).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch7.rb})"'

fixes = [
  ["budget-carryover", "rule_content", [
    ["제48조에 따른 계속비", "제42조에 따른 계속비"]
  ]],
  ["budget-carryover", "interpretation_content", [
    ["계속비는 지방재정법 제48조에 따라", "계속비는 지방재정법 제42조에 따라"]
  ]],
  ["budget-carryover", "regulation_content", [
    ["| 지방재정법 제48조 |", "| 지방재정법 제42조 |"]
  ]],
  ["budget-carryover", "commentary", [
    ["제48조 및 제49조에 따라 명시이월과 사고이월", "제50조에 따라 명시이월과 사고이월"]
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
puts "[content_fix batch7] #{results.join(' | ')}"

# 잔존 검증: 계속비/이월 문맥의 §48 잔존 0
puts "--- 잔존 검증 ---"
t = Topic.find_by(slug: "budget-carryover")
{
  rule_content: "제48조에 따른 계속비",
  interpretation_content: "지방재정법 제48조에 따라",
  regulation_content: "| 지방재정법 제48조 |",
  commentary: "제48조 및 제49조에 따라 명시이월"
}.each do |f, pat|
  n = t.public_send(f).to_s.scan(pat).size
  puts "  budget-carryover.#{f} '#{pat}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
end
