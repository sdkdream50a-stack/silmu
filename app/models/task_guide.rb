class TaskGuide < ApplicationRecord
  enum :status, { pending: 0, generating: 1, completed: 2, failed: 3 }

  validates :task_title, presence: true, uniqueness: true
end
