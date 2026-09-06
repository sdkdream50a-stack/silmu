require "json"
bad = []
Topic.find_each do |t|
  raw = t.read_attribute_before_type_cast(:faqs)
  parsed = begin
    v = t.faqs
    v.is_a?(Array) ? v : JSON.parse(v)
  rescue => e
    :ERROR
  end
  if parsed == :ERROR || !parsed.is_a?(Array)
    bad << { id: t.id, slug: t.slug, name: t.name, category: t.category, published: t.published,
             class: t.faqs.class.to_s, raw_head: raw.to_s[0,160] }
  end
end
puts JSON.pretty_generate({ topics_total: Topic.count, malformed_faq: bad.size, rows: bad })
