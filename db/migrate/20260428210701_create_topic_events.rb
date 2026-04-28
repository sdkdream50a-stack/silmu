class CreateTopicEvents < ActiveRecord::Migration[8.1]
  def change
    # Sprint #2-C — 사용자 행동 추적 3종 (scroll_depth, time_on_page, faq_open)
    # 권위자 검증: Krug + Editorial Ops — 측정 없이 개선 불가능
    create_table :topic_events do |t|
      t.string  :topic_slug,  null: false
      t.string  :event_type,  null: false # scroll_depth | time_on_page | faq_open
      t.integer :event_value             # scroll: 25/50/75/100, time: seconds, faq: index
      t.string  :ip_hash
      t.timestamps
    end

    add_index :topic_events, :topic_slug
    add_index :topic_events, [ :topic_slug, :event_type ], name: "idx_topic_events_slug_type"
    add_index :topic_events, :created_at
  end
end
