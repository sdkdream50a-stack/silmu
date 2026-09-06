require "json"
out = {}
out[:meta] = { rev: ENV["KAMAL_VERSION"], env: Rails.env, measured_at: Time.current.iso8601,
               schema: ActiveRecord::Base.connection.select_value("SELECT max(version) FROM schema_migrations").to_s }

# ---------- totals ----------
out[:totals] = {
  topic_total: Topic.count, topic_published: Topic.published.count,
  guide_total: Guide.count, guide_published: Guide.published.count,
  audit_total: AuditCase.count, audit_published: AuditCase.published.count,
  law: Law.count, standard_term: StandardTerm.count, task_guide: TaskGuide.count,
  search_log: SearchLog.count
}

# ---------- topic per category ----------
tcat = Hash.new { |h,k| h[k] = { topics: 0, faq: 0, howto: 0, quick_stats: 0,
                                 topics_with_faq: 0, topics_with_howto: 0,
                                 topics_with_flowchart: 0, topics_with_law: 0,
                                 topics_with_interp: 0, topics_with_tips: 0,
                                 verification: Hash.new(0), freshness: Hash.new(0) } }
Topic.published.find_each do |t|
  c = t.category.presence || "(nil)"
  h = tcat[c]
  h[:topics] += 1
  faqs = (t.faqs.is_a?(Array) ? t.faqs : []) rescue []
  hows = (t.howto_steps.is_a?(Array) ? t.howto_steps : []) rescue []
  qs   = (t.quick_stats.is_a?(Array) ? t.quick_stats : []) rescue []
  h[:faq] += faqs.size; h[:howto] += hows.size; h[:quick_stats] += qs.size
  h[:topics_with_faq] += 1 if faqs.any?
  h[:topics_with_howto] += 1 if hows.any?
  h[:topics_with_flowchart] += 1 if t.flowchart_mermaid.present? || t.flowchart_url.present?
  h[:topics_with_law] += 1 if t.law_content.present?
  h[:topics_with_interp] += 1 if t.interpretation_content.present?
  h[:topics_with_tips] += 1 if t.practical_tips.present?
  h[:verification][t.verification_status.presence || "(nil)"] += 1
  h[:freshness][t.freshness_state.presence || "(nil)"] += 1
end
out[:topic_by_category] = tcat

# ---------- guide per category / series ----------
out[:guide_by_category] = Guide.published.group(:category).count
out[:guide_by_series]   = Guide.published.where.not(series: nil).group(:series).count
out[:guide_no_series]   = Guide.published.where(series: nil).count

# ---------- audit per category + provenance ----------
out[:audit_by_category] = AuditCase.published.group(:category).count
out[:audit_source_type] = AuditCase.published.group(:source_type).count
out[:audit_is_reconstructed] = AuditCase.published.group(:is_reconstructed).count
out[:audit_provenance_conf] = AuditCase.published.group(:provenance_confidence).count
out[:audit_verification]   = AuditCase.published.group(:verification_status).count

# ---------- authority ----------
out[:authority] = {
  sources: AuthoritySource.count,
  documents: AuthorityDocument.count,
  versions: AuthorityVersion.count,
  change_events: AuthorityChangeEvent.count,
  review_tasks: AuthorityReviewTask.count,
  verification_events: AuthorityVerificationEvent.count,
  links_total: ContentAuthorityLink.count,
  links_by_content_type: ContentAuthorityLink.group(:content_type).count,
  links_by_confidence: ContentAuthorityLink.group(:confidence).count
}
linked_topic_ids = ContentAuthorityLink.where(content_type: "Topic").distinct.pluck(:content_id).compact
out[:authority][:topics_linked] = (Topic.published.pluck(:id) & linked_topic_ids).size

# ---------- search logs ----------
out[:search] = {
  total: SearchLog.count,
  zero_result_total: SearchLog.where(zero_result: true).count,
  first_at: SearchLog.minimum(:created_at)&.iso8601,
  last_at: SearchLog.maximum(:created_at)&.iso8601,
  by_source: SearchLog.group(:source).count,
  clicked: SearchLog.where.not(clicked_at: nil).count,
  unsatisfied: SearchLog.where(zero_result: false, clicked_at: nil).count
}
out[:search][:zero_result_queries_alltime] =
  SearchLog.where(zero_result: true).group(:query).order(Arel.sql("COUNT(*) DESC")).limit(120).count
out[:search][:unsatisfied_queries_alltime] =
  SearchLog.where(zero_result: false, clicked_at: nil).group(:query).order(Arel.sql("COUNT(*) DESC")).limit(120).count
out[:search][:top_queries_alltime] =
  SearchLog.group(:query).order(Arel.sql("COUNT(*) DESC")).limit(120).count

# ---------- topic inventory ----------
out[:topics] = Topic.published.order(:category, :slug).map { |t|
  faqs = (t.faqs.is_a?(Array) ? t.faqs : []) rescue []
  hows = (t.howto_steps.is_a?(Array) ? t.howto_steps : []) rescue []
  { slug: t.slug, name: t.name, category: t.category, faq: faqs.size, howto: hows.size,
    vs: t.verification_status, fs: t.freshness_state, views: t.view_count,
    faq_q: faqs.map { |f| f.is_a?(Hash) ? f["question"] : nil }.compact }
}
out[:guides] = Guide.published.order(:category, :slug).map { |g|
  { slug: g.slug, title: g.title, category: g.category, series: g.series, topic_slug: g.topic_slug, views: g.view_count }
}
out[:audit_cases_min] = AuditCase.published.order(:category).map { |a|
  { slug: a.slug, category: a.category, source_type: a.source_type, recon: a.is_reconstructed, topic_slug: a.topic_slug }
}
puts JSON.generate(out)
