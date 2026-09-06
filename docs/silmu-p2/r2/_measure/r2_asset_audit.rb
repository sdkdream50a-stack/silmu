# R2 Phase A — 기존 자산 실측 (READ-ONLY. 쓰기 0)
# 사용: ssh root@HOST "docker exec -i $REV bin/rails runner -" < 이 파일
require "json"

out = { measured_at: Time.now.utc.iso8601, mutations: 0 }

SLUGS = %w[
  private-contract-limit split-contract split-contract-prohibition
  small-amount-contract emergency-contract quote-collection-guide
  contract-method goods-vs-service-contract joint-contract subcontract
]

out[:topics] = SLUGS.map { |s|
  t = Topic.find_by(slug: s)
  next { slug: s, exists: false } unless t
  { slug: s, exists: true, name: t.name, published: t.published,
    category: t.category, target_agency: Array(t.target_agency),
    effective_at: t.effective_at&.to_s, law_base_date: t.law_base_date,
    last_verified_at: t.last_verified_at&.to_s,
    verification_status: t.verification_status,
    faqs: (t.faqs.is_a?(Array) ? t.faqs.length : -1),
    faq_questions: (t.faqs.is_a?(Array) ? t.faqs.map { |f| f.is_a?(Hash) ? (f["question"] || f[:question]) : f.to_s } : []),
    howto: (t.howto_steps.is_a?(Array) ? t.howto_steps.length : -1),
    howto_names: (t.howto_steps.is_a?(Array) ? t.howto_steps.map { |h| h.is_a?(Hash) ? h["name"] : h.to_s } : []),
    law_len: t.law_content.to_s.length, decree_len: t.decree_content.to_s.length,
    rule_len: t.rule_content.to_s.length, qa_len: t.qa_content.to_s.length,
    quick_stats: (t.quick_stats.is_a?(Array) ? t.quick_stats.length : -1) }
}

# 검색 도달성 — Answer-First 포함
QUERIES = [
  "수의계약 한도", "수의계약한도", "소액수의", "분할발주", "분리 발주",
  "수입인지", "보조금정산", "국외출장",
  "3000만원 물품 수의계약", "5000만원 용역 수의계약",
  "공사를 나눠 계약해도 되나", "같은 물품을 여러 번 나눠 사도 되나",
  "분리발주와 분할발주의 차이", "처음 계약을 맡았어요",
  "병가", "숙박비 지급 기준", "차비"
]
out[:search] = QUERIES.map { |q|
  topics = (Topic.respond_to?(:search_multiple) ? Topic.search_multiple(q) : []) rescue []
  ans    = (Topic.respond_to?(:answer_for) ? Topic.answer_for(q) : nil) rescue nil
  tools  = (ToolsHelper.instance_method(:tools_registry) rescue nil) ? [] : []
  { q: q,
    topic_slugs: Array(topics).first(5).map { |t| t.respond_to?(:slug) ? t.slug : t.to_s },
    topic_count: Array(topics).size,
    answer: ans.nil? ? nil : (ans.is_a?(Hash) ? (ans[:question] || ans["question"]) : ans.to_s[0, 80]) }
}

# 도구 registry 실측
begin
  helper = Object.new.extend(ToolsHelper)
  reg = helper.tools_registry
  picked = reg.select { |t| %w[contract-method split-contract-checker estimated-price].include?(t[:key] || t["key"]) }
  out[:tools] = picked.map { |t| t.transform_keys(&:to_s) }
  out[:tools_total] = reg.size
rescue => e
  out[:tools_error] = "#{e.class}: #{e.message}"
end

# 감사사례
out[:audit_cases] = AuditCase.where("title ILIKE ? OR title ILIKE ? OR slug ILIKE ?", "%분할%", "%수의계약%", "%split%")
  .limit(40).map { |c| { slug: c.slug, title: c.title,
     verification_status: (c.respond_to?(:verification_status) ? c.verification_status : nil),
     provenance: (c.respond_to?(:provenance_confidence) ? c.provenance_confidence : nil) } }
out[:audit_case_total] = AuditCase.count

# Authority 현행성
out[:authority] = AuthorityDocument.order(:id).map { |d|
  v = d.current_version
  { id: d.id, title: d.title, type: d.document_type, jurisdiction: d.jurisdiction,
    effective_at: v&.effective_at&.to_s, fetched_at: v&.fetched_at&.to_s,
    last_checked_at: d.last_checked_at&.to_s,
    content_len: v&.normalized_content.to_s.length, source_url: v&.source_url }
}
out[:content_authority_links_by_type] = ContentAuthorityLink.group(:content_type).count

# 콘텐츠 총량 (비회귀 baseline)
out[:totals] = { topic: Topic.count, published_topic: Topic.where(published: true).count,
  guide: Guide.count, audit_case: AuditCase.count,
  faq_authored: Topic.all.sum { |t| t.faqs.is_a?(Array) ? t.faqs.length : 0 },
  faq_nonarray: Topic.where.not(faqs: nil).count { |t| !t.faqs.is_a?(Array) },
  search_log: (defined?(SearchLog) ? SearchLog.count : nil) }

puts JSON.pretty_generate(out)
