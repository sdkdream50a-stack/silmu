class CreateExamQuestionReports < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_question_reports do |t|
      t.integer :question_id, null: false
      t.bigint :user_id
      t.text :body, null: false

      t.timestamps
    end
  end
end
