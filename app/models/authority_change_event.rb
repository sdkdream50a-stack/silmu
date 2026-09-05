# frozen_string_literal: true

# P1.5 §8·§12 — 변경 이벤트.
#
# **핵심 규칙: "법령 변경 감지" ≠ "콘텐츠가 틀림".**
# 이 이벤트는 사실(원문이 바뀌었다)만 기록한다. 영향 판정은 사람이 한다.
class AuthorityChangeEvent < ApplicationRecord
  belongs_to :authority_document
  belongs_to :old_version, class_name: "AuthorityVersion", optional: true
  belongs_to :new_version, class_name: "AuthorityVersion"
  has_many :authority_review_tasks, dependent: :destroy

  CHANGE_TYPES = {
    "NEW_DOCUMENT"           => "신규 수집",
    "CONTENT_CHANGED"        => "본문 변경",
    "METADATA_CHANGED"       => "메타데이터 변경",
    "EFFECTIVE_DATE_CHANGED" => "시행일 변경",
    "REPEALED"               => "폐지"
  }.freeze

  IMPACT_STATUSES = %w[PENDING ANALYZED NO_CONTENT_LINKED].freeze
  REVIEW_STATUSES = %w[OPEN IN_REVIEW RESOLVED].freeze

  validates :change_type, inclusion: { in: CHANGE_TYPES.keys }
  validates :impact_status, inclusion: { in: IMPACT_STATUSES }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :detected_at, presence: true

  scope :open, -> { where(review_status: %w[OPEN IN_REVIEW]) }
  scope :unanalyzed, -> { where(impact_status: "PENDING") }

  def change_type_label = CHANGE_TYPES[change_type]

  # 신규 수집은 "변경"이 아니다 — 기준선일 뿐이다.
  def baseline? = change_type == "NEW_DOCUMENT"

  # §9 — 시행 전 변경은 아직 현행 기준을 바꾸지 않는다.
  def already_in_effect?(on = Date.current) = effective_at.present? && effective_at <= on

  def resolve!
    update!(review_status: "RESOLVED")
  end
end
