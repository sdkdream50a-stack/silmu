# Created: 2026-02-18 00:19
class AddPerformanceIndexesToAuditCases < ActiveRecord::Migration[8.1]
  def change
    # published + created_at: published.recent 스코프 최적화
    add_index :audit_cases, [ :published, :created_at ],
              name: "index_audit_cases_on_published_and_created_at"

    # published + category: published.by_category 필터 최적화
    add_index :audit_cases, [ :published, :category ],
              name: "index_audit_cases_on_published_and_category"

    # topic_slug: related_audit_cases (topic_slug: slug) 조회 최적화
    add_index :audit_cases, :topic_slug,
              name: "index_audit_cases_on_topic_slug"
  end
end
