class ExamProgress < ApplicationRecord
  belongs_to :user

  def self.for_user(user)
    find_or_create_by(user: user)
  end
end
