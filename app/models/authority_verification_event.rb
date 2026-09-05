# frozen_string_literal: true

# P1.5 §29 — 검증 이벤트.
# "언제 누가 어떤 버전을 보고 무엇으로 판정했는가"를 콘텐츠와 분리해 남긴다.
class AuthorityVerificationEvent < ApplicationRecord
  belongs_to :authority_version, optional: true
  belongs_to :authority_review_task, optional: true

  validates :content_type, :reviewer, :reviewed_at, :result, presence: true
  validates :result, inclusion: { in: AuthorityReviewTask::DECISIONS }

  scope :for_content, ->(type, id) { where(content_type: type, content_id: id) }
  scope :recent_first, -> { order(reviewed_at: :desc) }
end
