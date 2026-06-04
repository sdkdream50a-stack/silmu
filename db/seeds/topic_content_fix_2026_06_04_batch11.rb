# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치11 (제N조 의미오기 감사 #6: 예정가격 작성·조서)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04):
#   지방계약법 본법(253973): §11=예정가격의 작성·§13=낙찰자 결정.
#   지방계약법 시행령(286149): §8=예정가격의 작성 및 비치·§9=예정가격의 결정방법·§10=예정가격의 결정기준·
#     §12=입찰의 성립·§33=입찰공고.
#   지방계약법 시행규칙(285747): §4=예정가격조서의 작성·§5=거래실례가격 및 표준시장단가에 따른 예정가격의 결정·
#     §6=원가계산에 의한 예정가격의 결정.
#   국가계약법 본법(277151): §8의2=예정가격의 작성·§9=입찰보증금.
#
# 결함: 예정가격 작성을 국가§9(=입찰보증금)·본법§13(=낙찰자결정)·시행령§33(=입찰공고)으로,
#   예정가격조서를 시행규칙§5(=거래실례가격)로, 경쟁입찰 성립을 본법§10(=입찰공고)으로 오인용.
#
# 🛡️ 정정 매트릭스:
#   cost-calculation-guide.law:  "국가계약법 제9조 (예정가격의 결정)"→"국가계약법 제8조의2 (예정가격의 작성)" /
#     "지방계약법 시행령 제33조 (예정가격 작성)"→"지방계약법 시행령 제8조 (예정가격의 작성 및 비치)"
#   cost-calculation-guide.rule: "시행규칙 제5조 (예정가격 조서)"·"(예정가격조서 작성)"→"시행규칙 제4조 (예정가격조서의 작성)"
#   estimated-price.law: "지방계약법 제13조 (예정가격)"→"지방계약법 제11조 (예정가격의 작성)" /
#     "제10조 (경쟁입찰의 성립)"→"시행령 제12조 (입찰의 성립)"
# ⛔ 보류: estimated-price.decree(§7~§11 예정가격결정/거래실례/원가계산/복수예비가격/조서 다중·복수예비가격=예규)·
#   design-change(설계변경 §65/§66/§74 중복·계약변경 §19).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch11.rb})"'

fixes = [
  ["cost-calculation-guide", "law_content", [
    ["국가계약법 제9조 (예정가격의 결정)", "국가계약법 제8조의2 (예정가격의 작성)"],
    ["지방계약법 시행령 제33조 (예정가격 작성)", "지방계약법 시행령 제8조 (예정가격의 작성 및 비치)"]
  ]],
  ["cost-calculation-guide", "rule_content", [
    ["시행규칙 제5조 (예정가격 조서)", "시행규칙 제4조 (예정가격조서의 작성)"],
    ["시행규칙 제5조 (예정가격조서 작성)", "시행규칙 제4조 (예정가격조서의 작성)"]
  ]],
  ["estimated-price", "law_content", [
    ["지방계약법 제13조 (예정가격)", "지방계약법 제11조 (예정가격의 작성)"],
    ["제10조 (경쟁입찰의 성립)", "시행령 제12조 (입찰의 성립)"]
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
puts "[content_fix batch11] #{results.join(' | ')}"

puts "--- 잔존 검증 ---"
checks = {
  "cost-calculation-guide" => {
    law_content: ["국가계약법 제9조 (예정가격의 결정)", "시행령 제33조 (예정가격 작성)"],
    rule_content: ["제5조 (예정가격 조서)", "제5조 (예정가격조서 작성)"]
  },
  "estimated-price" => { law_content: ["제13조 (예정가격)", "제10조 (경쟁입찰의 성립)"] }
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
