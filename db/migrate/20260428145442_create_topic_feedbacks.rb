class CreateTopicFeedbacks < ActiveRecord::Migration[8.1]
  def change
    # Sprint Task #5 — 사용자 만족도 1클릭 측정 (TopicComment와 분리)
    # 권위자 검증: Krug + NN/g 응답률 — 단순 👍/👎 + 선택 메모가 응답률 최고
    create_table :topic_feedbacks do |t|
      t.string  :topic_slug, null: false
      t.integer :rating,     null: false # 0=down, 1=up (확장 가능)
      t.text    :memo
      t.integer :user_id
      t.string  :ip_hash # IP+UA hash, 24h 중복 차단
      t.timestamps
    end

    add_index :topic_feedbacks, :topic_slug
    add_index :topic_feedbacks, :user_id
    add_index :topic_feedbacks, :created_at
    add_index :topic_feedbacks, [ :topic_slug, :ip_hash ], name: "idx_topic_feedback_dedupe"
  end
end
