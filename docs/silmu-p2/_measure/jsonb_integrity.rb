require "json"
res = { malformed: [], summary: Hash.new(0) }
def bad?(v)
  return false if v.is_a?(Array) || v.is_a?(Hash)
  return false if v.nil?
  begin; JSON.parse(v.to_s); false; rescue; true; end
end
Topic.find_each do |t|
  %w[faqs howto_steps quick_stats].each do |col|
    v = t.public_send(col)
    if bad?(v)
      # ruby-inspect 문자열이면 몇 건이 갇혀 있는지 센다
      trapped = t.public_send(col).to_s.scan(/"question"=>/).size
      trapped = t.public_send(col).to_s.scan(/=>/).size if trapped.zero?
      res[:malformed] << { id: t.id, slug: t.slug, col: col, class: v.class.to_s, trapped_questions: t.public_send(col).to_s.scan(/"question"=>/).size, arrow_pairs: trapped }
      res[:summary]["#{col}_malformed"] += 1
    end
  end
end
%w[faqs howto_steps quick_stats].each do |col|
  res[:summary]["#{col}_array_ok"] = Topic.all.count { |t| t.public_send(col).is_a?(Array) }
end
# Guide.sections / rich_media
res[:guide_sections_non_array] = Guide.all.count { |g| !g.sections.is_a?(Array) && !g.sections.nil? }
res[:audit_checkpoints_non_array] = AuditCase.all.count { |a| !a.checkpoints.is_a?(Array) && !a.checkpoints.nil? }
puts JSON.pretty_generate(res)
