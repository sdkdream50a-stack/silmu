class CreateContentRequests < ActiveRecord::Migration[8.1]
  def change
    # Sprint #3-B — 콘텐츠 backlog 자동 입력 (Editorial Ops 권위자 검증)
    # 출처: TopicFeedback 부정 메모, GSC 빈손 쿼리, 내부 검색 0결과 등
    create_table :content_requests do |t|
      t.string  :source,      null: false # feedback_memo | gsc_empty | internal_search | manual
      t.integer :source_id              # 출처 레코드 id (TopicFeedback.id 등)
      t.string  :topic_slug             # 관련 토픽 (있으면)
      t.string  :title,       null: false
      t.text    :memo
      t.string  :status,      default: "open" # open | in_progress | done | rejected
      t.integer :priority,    default: 3       # 1(낮음) ~ 5(높음)
      t.timestamps
    end

    add_index :content_requests, :source
    add_index :content_requests, :topic_slug
    add_index :content_requests, :status
    add_index :content_requests, :created_at
    add_index :content_requests, [ :source, :source_id ], name: "idx_content_request_source"
  end
end
