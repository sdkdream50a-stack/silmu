# 운영 DB 발산 실측 — READ-ONLY. update/save/delete 를 호출하지 않는다.
require "json"
PATTERNS = {
  "C_absolute_headline"   => /분할계약\s*절대\s*금지/,
  "C_any_split_flagged"   => /1건의 계약을 2개 이상으로 분할하면/,
  "B_amount_irrelevant"   => /분할계약은\s*금액과\s*무관하게\s*금지/,
  "D_special_cap_5000"    => /특례기업\s*5(?:,?000|천)만원/,   # "5,000만원"과 "5천만원" 둘 다
  "D_sunset_2026_on_25"   => /한시적 특례[^)]{0,90}(?:5천만원\s*~\s*1억원|3천만원으로 회귀)/,
  "E_missing_micro"       => /소기업·여성·장애인/,
  "E_unqualified_1eok"    => /\(특례\s*1억\)/
}
out = { probed_at: Time.now.utc.iso8601, revision: ENV["KAMAL_VERSION"] || "unknown", hits: Hash.new { |h, k| h[k] = [] } }

def each_text(rec, fields)
  fields.each do |f|
    next unless rec.respond_to?(f)
    v = rec.public_send(f)
    yield f, (v.is_a?(String) ? v : v.to_json) if v.present?
  end
end

TOPIC_FIELDS = %i[name summary fold_summary law_content decree_content rule_content regulation_content
                  practical_tips interpretation_content qa_content quick_stats howto_steps faqs verification_source]
SUB_FIELDS   = %i[title summary law_content decree_content rule_content practical_tips interpretation_content qa_content]

Topic.find_each do |t|
  each_text(t, TOPIC_FIELDS) do |f, txt|
    PATTERNS.each { |k, re| out[:hits][k] << { model: "Topic", id: t.id, slug: t.slug, field: f } if txt.match?(re) }
  end
end
if defined?(Subtopic)
  Subtopic.find_each do |s|
    each_text(s, SUB_FIELDS) do |f, txt|
      PATTERNS.each { |k, re| out[:hits][k] << { model: "Subtopic", id: s.id, slug: s.try(:slug), field: f } if txt.match?(re) }
    end
  end
end
if defined?(AuditCase)
  AuditCase.find_each do |a|
    each_text(a, %i[title issue content legal_basis checklist]) do |f, txt|
      PATTERNS.each { |k, re| out[:hits][k] << { model: "AuditCase", id: a.id, field: f } if txt.match?(re) }
    end
  end
end
summary = out[:hits].transform_values(&:size)
puts JSON.pretty_generate({ probed_at: out[:probed_at], summary: summary, hits: out[:hits] })
