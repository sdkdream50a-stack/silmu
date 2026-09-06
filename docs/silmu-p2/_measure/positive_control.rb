require "json"
out = {}
# PC1: 확실히 있는 콘텐츠 — 검출기가 COVERED 를 잡는가
pc1 = {}
["수의계약", "출장 여비", "병가"].each do |q|
  ts = Topic.search_multiple(q, limit: 6).to_a
  a  = Topic.answer_for(q, ts)
  pc1[q] = { topics: ts.size, top: ts.first&.slug, answer: a && a[:question] }
end
out[:PC1_known_present] = pc1

# PC2: 확실히 없는 것 — 검출기가 NO_CONTENT 를 잡는가
pc2 = {}
["짜장면 곱빼기 결재", "우주정거장 청소용역 하도급", "zzqqxx 없는업무"].each do |q|
  ts = Topic.search_multiple(q, limit: 6).to_a
  g  = Guide.published.search_by_keyword(q).limit(5).to_a
  ac = AuditCase.search_by_query(q, limit: 5).to_a
  pc2[q] = { topics: ts.size, guides: g.size, audits: ac.size, top: ts.first&.slug }
end
out[:PC2_known_absent] = pc2

# PC3: 정보공개는 dev 0 · prod 존재 — dev/prod 격차 검출
t = Topic.find_by(slug: "information-disclosure")
out[:PC3_information_disclosure] = t ? { present: true, faq: t.faq_list.size, category: t.category, published: t.published } : { present: false }

# PC4: reconstructed 를 actual audit 로 오분류하지 않는가
out[:PC4_provenance] = {
  by_source_type: AuditCase.published.group(:source_type).count,
  recon_true_but_source_actual: AuditCase.published.where(is_reconstructed: true, source_type: "ACTUAL_AUDIT").count,
  source_actual_but_recon_true: AuditCase.published.where(source_type: "ACTUAL_AUDIT").where(is_reconstructed: true).count,
  recon_nil_count: AuditCase.published.where(is_reconstructed: nil).count,
  prov_conf_high_but_unverified: AuditCase.published.where(provenance_confidence: "HIGH", source_type: "UNVERIFIED").count
}

# PC5: freshness — stale/review 를 current 로 오분류하지 않는가
out[:PC5_freshness] = {
  topic_freshness: Topic.published.group(:freshness_state).count,
  topic_needs_review: Topic.published.where(needs_review: true).count,
  topic_review_due_past: Topic.published.where("review_due_at < ?", Date.current).count,
  guide_freshness: Guide.published.group(:freshness_state).count,
  audit_freshness: AuditCase.published.group(:freshness_state).count,
  law_effective_date_present: Law.where.not(effective_date: nil).count,
  law_total: Law.count
}

# PC6: MUTATION GUARD — 이 세션이 아무것도 안 썼는지
out[:PC6_mutation_guard] = {
  search_log_count: SearchLog.count,
  search_log_max_created: SearchLog.maximum(:created_at)&.iso8601,
  topic_max_updated: Topic.maximum(:updated_at)&.iso8601,
  guide_max_updated: Guide.maximum(:updated_at)&.iso8601,
  audit_max_updated: AuditCase.maximum(:updated_at)&.iso8601
}
puts JSON.pretty_generate(out)
