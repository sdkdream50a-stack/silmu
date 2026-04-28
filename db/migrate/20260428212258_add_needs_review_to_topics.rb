class AddNeedsReviewToTopics < ActiveRecord::Migration[8.1]
  # Sprint #4-B — 법령 개정 자동 알림 (Westlaw + Editorial Ops 권위자 검증)
  # strong_migrations 가드 — 인덱스는 concurrently로 추가
  disable_ddl_transaction!

  def change
    add_column :topics, :needs_review,       :boolean, default: false, null: false unless column_exists?(:topics, :needs_review)
    add_column :topics, :review_reason,      :string                                  unless column_exists?(:topics, :review_reason)
    add_column :topics, :review_flagged_at,  :datetime                                unless column_exists?(:topics, :review_flagged_at)

    add_index :topics, :needs_review, algorithm: :concurrently unless index_exists?(:topics, :needs_review)
  end
end
