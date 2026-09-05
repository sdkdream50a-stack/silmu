# frozen_string_literal: true

# P1.5 §27·§28 — 검토 큐.
# 엔진은 여기까지만 만든다. 실제 판정과 콘텐츠 수정은 사람이 한다.
class AuthorityReviewTask < ApplicationRecord
  belongs_to :authority_change_event
  has_one :authority_document, through: :authority_change_event

  # §14 — 영향 분류
  IMPACT_CLASSES = {
    "DIRECT"    => "직접 영향 (해당 조문을 근거로 함)",
    "INDIRECT"  => "간접 영향 (같은 법령의 다른 조문)",
    "POSSIBLE"  => "영향 가능",
    "NO_IMPACT" => "영향 없음",
    "UNKNOWN"   => "판정 불가 — 사람 검토 필요"
  }.freeze

  # §28 — Reviewer 가 고를 수 있는 결정
  DECISIONS = %w[IMPACT_CONFIRMED NO_IMPACT UPDATE_REQUIRED NEEDS_LEGAL_REVIEW DEFERRED].freeze
  OPEN_STATUSES = %w[OPEN IN_REVIEW].freeze
  STATUSES = (OPEN_STATUSES + DECISIONS).freeze

  validates :affected_type, presence: true
  validates :impact_class, inclusion: { in: IMPACT_CLASSES.keys }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: 1..5 }

  scope :open, -> { where(status: OPEN_STATUSES) }
  scope :by_priority, -> { order(:priority, created_at: :asc) }

  def impact_label = IMPACT_CLASSES[impact_class]
  def open? = OPEN_STATUSES.include?(status)

  # §29 — 검토 결과는 별도 이벤트로 남긴다. 콘텐츠 updated_at 으로 표현하지 않는다.
  def decide!(decision:, reviewer:, note: nil, at: Time.current)
    raise ArgumentError, "알 수 없는 결정: #{decision}" unless DECISIONS.include?(decision)

    transaction do
      update!({ status: decision }.merge(reviewer_fields(reviewer, note, at)))
      AuthorityVerificationEvent.create!(
        content_type: affected_type, content_id: affected_id, content_key: affected_key,
        authority_version_id: authority_change_event.new_version_id,
        authority_review_task_id: id,
        reviewer: reviewer, reviewed_at: at, result: decision, note: note
      )
      ContentFreshnessUpdater.apply_decision(self)
      authority_change_event.resolve! if authority_change_event.authority_review_tasks.open.none?
    end
    self
  end

  private

  def reviewer_fields(reviewer, note, at)
    { assigned_to: assigned_to.presence || reviewer, reviewed_at: at, review_note: note }
  end
end
