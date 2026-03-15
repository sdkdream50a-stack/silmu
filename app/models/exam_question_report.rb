class ExamQuestionReport < ApplicationRecord
  belongs_to :user, optional: true
  validates :question_id, :body, presence: true
  validates :body, length: { minimum: 5, maximum: 500 }
end
