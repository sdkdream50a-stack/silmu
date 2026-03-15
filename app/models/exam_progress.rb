class ExamProgress < ApplicationRecord
  belongs_to :user

  # SQLite는 text로 저장되므로 JSON 직렬화 필요
  serialize :chapters, coder: JSON
  serialize :quizzes, coder: JSON
  serialize :chapter_quizzes, coder: JSON
  serialize :wrong_answers, coder: JSON
  serialize :bookmarks, coder: JSON
  serialize :streak_history, coder: JSON

  def self.for_user(user)
    find_or_create_by(user: user)
  end
end
