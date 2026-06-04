# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치19b (budget 클러스터 보강: faqs·quick_stats JSONB)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# batch19 적용 후 전 필드 스캔: faqs·quick_stats(JSONB)에 동일 오기 잔존.
#   budget-compilation faqs/quick_stats: 지방자치법§127(=사업소) → §142(예산의 편성 및 의결)
#   budget-settlement faqs/quick_stats: 지방재정법§53(부존재) → 지방회계법§14(결산의 수행)
#   supplementary-budget quick_stats: 지방자치법§144(=예비비) → §142
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "eval(Base64.decode64(...))"'

jfixes = [
  ["budget-compilation", "faqs", [["지방자치법 제127조", "지방자치법 제142조"]]],
  ["budget-compilation", "quick_stats", [["지방자치법 제127조", "지방자치법 제142조"]]],
  ["budget-settlement", "faqs", [["지방재정법 제53조", "지방회계법 제14조"]]],
  ["budget-settlement", "quick_stats", [["지방재정법 제53조", "지방회계법 제14조"]]],
  ["supplementary-budget", "quick_stats", [["지방자치법 제144조", "지방자치법 제142조"]]]
]

results = []
jfixes.each do |slug, field, pairs|
  t = Topic.find_by(slug: slug)
  if t.nil?; results << "#{slug} NOT_FOUND"; next; end
  raw = t.public_send(field)
  is_str = raw.is_a?(String)
  json = is_str ? raw.to_s : raw.to_json
  matched = []
  pairs.each { |o, n| json.include?(o) ? (json = json.gsub(o, n); matched << "OK") : (matched << "MISS") }
  t.update!(field => (is_str ? json : JSON.parse(json)))
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end
puts "[content_fix batch19b] #{results.join(' | ')}"

puts "--- budget 클러스터 전 필드 잔존 전수 재스캔 ---"
slugs = %w[accounting-officers budget-compilation budget-settlement budget-transfer supplementary-budget budget-compilation-guideline budget-item-standard budget-execution extra-budgetary-fund]
pats = ['지방재정법 제53조', '지방재정법 제66조', '지방자치법 제127조', '지방자치법 제144조', '제56조(임시회)', '시행령 제37조 (예산편성', '제47조 (예산의 이용·전용)', '"회계관계공무원"의 법령상 정의']
total = 0
slugs.each do |slug|
  t = Topic.find_by(slug: slug); next unless t
  t.attributes.each do |c, v|
    next if v.nil?; s = v.is_a?(String) ? v : v.to_json
    pats.each { |p| n = s.scan(p).size; (puts "  RESIDUAL #{slug}.#{c} '#{p}'=#{n}"; total += n) if n > 0 }
  end
end
puts(total.zero? ? "  ✅ budget 클러스터 전 필드 CLEAN" : "  ⚠️ 잔존 #{total}")
