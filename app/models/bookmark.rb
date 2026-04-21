class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  validates :bookmarkable_id, uniqueness: {
    scope: [ :user_id, :bookmarkable_type ],
    message: "이미 북마크된 항목입니다"
  }

  # bookmarkable_type에 허용된 모델만 사용
  ALLOWED_TYPES = %w[Topic Guide AuditCase].freeze

  validates :bookmarkable_type, inclusion: {
    in: ALLOWED_TYPES,
    message: "지원하지 않는 북마크 유형입니다"
  }

  scope :topics,      -> { where(bookmarkable_type: "Topic") }
  scope :guides,      -> { where(bookmarkable_type: "Guide") }
  scope :audit_cases, -> { where(bookmarkable_type: "AuditCase") }
  scope :recent,      -> { order(created_at: :desc) }
end
