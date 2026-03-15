class ExamQuestionComment < ApplicationRecord
  belongs_to :user

  validates :body, presence: true, length: { maximum: 500 }
  validates :question_id, presence: true

  def author_display_name
    author_name.presence || "조달수험생#{user_id}"
  end
end
