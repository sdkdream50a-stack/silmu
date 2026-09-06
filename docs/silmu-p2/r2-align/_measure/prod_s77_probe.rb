# 운영 DB 의 §77 적용범위 실측 — READ-ONLY. update/save/delete 를 호출하지 않는다.
# 판정 규칙은 test/models/contract_s77_scope_test.rb 와 같다: §77 을 든 **진술** 안에
# 공사 한정 · 범위 부정 · 두 트랙 병기 중 하나가 있어야 한다.
require "json"

S77          = /(?:제77조(?:제\d항)?(?:제\d호)?(?:[가-힣]목)?|§\s*77(?:제\d항)?)/
CONSTRUCTION = /공사|구조물|공종|공구|시공|설계서|펜스|현장설명/
SCOPE_LIMIT  = /적용되지\s*않|적용을\s*받지\s*않|인용\s*금지|근거로\s*대지\s*않|공사\s*조항|공사\s*한정|범위를\s*넘|잘못\s*인용/
TWO_TRACK    = /제7조제2호|§\s*7제2호|집행기준\s*제?1?장|행안부\s*예규|행정안전부\s*예규/
TAG          = /<[^>\n]+>/

def statements(text) = text.gsub(TAG) { |m| " " * m.length }.split(/(?<=[.。!?])\s+|\n/)
def scoped?(s) = s.match?(CONSTRUCTION) || s.match?(SCOPE_LIMIT) || s.match?(TWO_TRACK)

TOPIC_FIELDS = %i[name summary law_content decree_content rule_content regulation_content
                  practical_tips interpretation_content qa_content quick_stats howto_steps faqs
                  verification_source audit_cases]
CASE_FIELDS  = %i[title issue detail legal_basis lesson checkpoints action_taken]

out = { probed_at: Time.now.utc.iso8601, unscoped: [], total_mentions: 0 }

scan = lambda do |model, id, slug, field, raw|
  txt = raw.is_a?(String) ? raw : raw.to_json
  return if txt.blank? || !txt.match?(S77)
  statements(txt).each do |st|
    s = st.strip
    next if s.empty? || !s.match?(S77)
    out[:total_mentions] += 1
    next if scoped?(s)
    out[:unscoped] << { model: model, id: id, slug: slug, field: field, text: s[0, 220] }
  end
end

# ⚠️ Topic#audit_cases 는 **같은 이름의 컬럼을 has_many 연관이 가린다.**
# public_send 로 읽으면 AuditCase 레코드 목록이 오고(다른 곳에서 이미 세는 것),
# 정작 컬럼 본문은 한 번도 안 읽힌다. 컬럼은 read_attribute 로만 읽는다.
Topic.find_each do |t|
  TOPIC_FIELDS.each do |f|
    next unless t.has_attribute?(f.to_s)
    scan.call("Topic", t.id, t.slug, f, t.read_attribute(f))
  end
end
if defined?(AuditCase)
  AuditCase.find_each do |a|
    CASE_FIELDS.each { |f| scan.call("AuditCase", a.id, a.try(:slug), f, a.public_send(f)) if a.respond_to?(f) }
  end
end

puts JSON.pretty_generate({ probed_at: out[:probed_at], total_mentions: out[:total_mentions],
                            unscoped_count: out[:unscoped].size, unscoped: out[:unscoped] })
