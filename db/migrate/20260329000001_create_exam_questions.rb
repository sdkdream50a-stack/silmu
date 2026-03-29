class CreateExamQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_questions do |t|
      t.integer  :subject_id,  null: false
      t.integer  :chapter_num, null: false
      t.text     :question,    null: false
      t.text     :options,     null: false, default: "[]"
      t.integer  :correct,     null: false
      t.text     :explanation
      t.string   :difficulty,  null: false, default: "basic"
      t.boolean  :published,   null: false, default: true
      t.timestamps
    end

    add_index :exam_questions, :subject_id
    add_index :exam_questions, [ :subject_id, :chapter_num ]
    add_index :exam_questions, :published
  end
end
