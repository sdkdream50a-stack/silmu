# Created: 2026-02-20 22:51
# 성능 최적화: 자주 조회되는 컬럼 조합에 복합 인덱스 추가
class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # topics: published + view_count (인기 토픽 정렬)
    add_index :topics, [:published, :view_count],
              name: "index_topics_on_published_and_view_count",
              algorithm: :concurrently,
              if_not_exists: true

    # topics: published + category (카테고리별 필터링)
    add_index :topics, [:published, :category],
              name: "index_topics_on_published_and_category",
              algorithm: :concurrently,
              if_not_exists: true

    # guides: published + sort_order (가이드 목록 정렬)
    add_index :guides, [:published, :sort_order],
              name: "index_guides_on_published_and_sort_order",
              algorithm: :concurrently,
              if_not_exists: true

    # guides: published + view_count (인기 가이드)
    add_index :guides, [:published, :view_count],
              name: "index_guides_on_published_and_view_count",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
