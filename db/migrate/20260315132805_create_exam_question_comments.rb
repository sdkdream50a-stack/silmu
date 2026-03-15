class CreateExamQuestionComments < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_question_comments do |t|
      t.integer :question_id, null: false
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.string :author_name
      t.integer :likes_count, default: 0
      t.timestamps
    end
    add_index :exam_question_comments, :question_id
  end
end
