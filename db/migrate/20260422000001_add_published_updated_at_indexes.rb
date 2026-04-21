class AddPublishedUpdatedAtIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # feed_controller / llms_controller의 `published=true ORDER BY updated_at DESC LIMIT N` 쿼리에서
  # 기존 단일 published 인덱스는 풀 테이블 정렬을 유발. 복합 인덱스로 정렬 단계 제거.
  def change
    add_index :topics, [:published, :updated_at], algorithm: :concurrently,
              name: "index_topics_on_published_and_updated_at"
    add_index :audit_cases, [:published, :updated_at], algorithm: :concurrently,
              name: "index_audit_cases_on_published_and_updated_at"
  end
end
