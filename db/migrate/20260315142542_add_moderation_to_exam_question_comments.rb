class AddModerationToExamQuestionComments < ActiveRecord::Migration[8.1]
  def change
    add_column :exam_question_comments, :reported_count, :integer, default: 0, null: false
    add_column :exam_question_comments, :hidden, :boolean, default: false, null: false
  end
end
