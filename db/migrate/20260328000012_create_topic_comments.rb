class CreateTopicComments < ActiveRecord::Migration[8.1]
  def change
    create_table :topic_comments do |t|
      t.references :user, null: true, foreign_key: true
      t.string  :topic_slug, null: false
      t.text    :body, null: false
      t.integer :comment_type, default: 0, null: false  # 0: question, 1: answer, 2: comment
      t.integer :parent_id
      t.integer :likes_count, default: 0, null: false
      t.boolean :hidden, default: false, null: false
      t.boolean :is_official, default: false, null: false
      t.timestamps
    end

    add_index :topic_comments, :topic_slug
    add_index :topic_comments, :parent_id
    add_index :topic_comments, [:topic_slug, :hidden, :created_at]
  end
end
