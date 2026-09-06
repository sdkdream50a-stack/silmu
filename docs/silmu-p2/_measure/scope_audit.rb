require "json"
out = {}
ctx = Class.new { include TaskEntryHelper; include Rails.application.routes.url_helpers }.new
out[:task_entry_counts] = ctx.task_entry_counts
out[:task_entries_visible] = ctx.task_entry_counts.select { |_,v| v >= TaskEntryHelper::MIN_COVERAGE }.keys
out[:min_coverage] = TaskEntryHelper::MIN_COVERAGE

out[:agency] = {
  topic_jurisdiction: Topic.published.group(:jurisdiction).count,
  topic_org_type: Topic.published.group(:org_type).count,
  topic_sector: Topic.published.group(:sector).count,
  topic_target_agency_blank: Topic.published.where("target_agency = '{}'").count,
  guide_jurisdiction: Guide.published.group(:jurisdiction).count,
  guide_sector: Guide.published.group(:sector).count,
  audit_jurisdiction: AuditCase.published.group(:jurisdiction).count,
  audit_sector: AuditCase.published.group(:sector).count
}
ta = Hash.new(0)
Topic.published.find_each { |t| Array(t.target_agency).each { |a| ta[a] += 1 } }
out[:agency][:topic_target_agency] = ta

out[:task_guides] = TaskGuide.all.map { |g| g.attributes.slice("id","slug","title","category","published").compact } rescue TaskGuide.count
out[:task_guide_columns] = TaskGuide.column_names

out[:onboarding] = begin
  Rails.application.routes.routes.map { |r| r.path.spec.to_s }.grep(/onboard|start|newcomer/).uniq
rescue => e
  e.message
end
out[:law] = Law.all.map { |l| { name: l.try(:name) || l.try(:title), effective_date: l.effective_date&.to_s } }
out[:authority_documents] = AuthorityDocument.all.map { |d| d.attributes.slice("id","title","document_type","source_id","external_id").compact } rescue []
puts JSON.pretty_generate(out)
