# frozen_string_literal: true

# Sprint #3-B — 콘텐츠 backlog (Editorial Ops 권위자 검증)
# TopicFeedback 부정 memo·GSC 빈손 쿼리·내부 검색 0결과를
# 자동으로 콘텐츠 backlog에 입력. silmu의 콘텐츠 우선순위를 데이터 기반화.
class ContentRequest < ApplicationRecord
  SOURCES = %w[feedback_memo gsc_empty internal_search manual].freeze
  STATUSES = %w[open in_progress done rejected].freeze

  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }
  validates :title, presence: true, length: { maximum: 255 }
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  scope :open,       -> { where(status: "open") }
  scope :priority_h, -> { order(priority: :desc, created_at: :desc) }
  scope :recent,     -> { order(created_at: :desc) }
  scope :by_source,  ->(s) { where(source: s) }

  # TopicFeedback 부정 memo로 자동 생성 (after_commit 훅에서 호출 권장)
  def self.from_feedback_memo(feedback)
    return if feedback.up?
    return if feedback.memo.blank?
    return if exists?(source: "feedback_memo", source_id: feedback.id)

    title = "[부정 피드백] #{feedback.topic_slug}: #{feedback.memo.to_s.truncate(80)}"
    create(
      source: "feedback_memo",
      source_id: feedback.id,
      topic_slug: feedback.topic_slug,
      title: title,
      memo: feedback.memo,
      priority: 4 # 부정 피드백은 우선순위 높음
    )
  end
end
