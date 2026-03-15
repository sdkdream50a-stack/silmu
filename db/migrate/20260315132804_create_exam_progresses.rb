class CreateExamProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :chapters, default: "{}"        # { "1-1": { visitedAt: "..." } }
      t.text :quizzes, default: "{}"         # { "1": { score: 28, ... } }
      t.text :chapter_quizzes, default: "{}" # { "1-1": { pct: 90, ... } }
      t.text :wrong_answers, default: "[]"   # [1, 5, 12, ...]
      t.text :bookmarks, default: "[]"       # [3, 7, 25, ...]
      t.integer :streak_count, default: 0
      t.string :streak_last_date
      t.text :streak_history, default: "[]"
      t.integer :weekly_quiz_count, default: 0
      t.string :weekly_reset_date
      t.string :display_name
      t.timestamps
    end
  end
end
