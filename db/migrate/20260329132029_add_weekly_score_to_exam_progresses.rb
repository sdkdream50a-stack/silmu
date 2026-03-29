class AddWeeklyScoreToExamProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :exam_progresses, :weekly_score, :integer, default: 0, null: false
    add_column :exam_progresses, :weekly_total, :integer, default: 0, null: false
  end
end
