# frozen_string_literal: true

# Sprint Task #5 — 토픽 만족도 1클릭 (Krug + NN/g 권위자 검증)
# TopicComment와 분리해 댓글 운영과 만족도 수집을 독립적으로 관리.
class TopicFeedback < ApplicationRecord
  enum :rating, { down: 0, up: 1 }

  validates :topic_slug, :rating, presence: true
  validates :memo, length: { maximum: 1000 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_topic, ->(slug) { where(topic_slug: slug) }

  # Sprint #3-B — 부정 피드백 + memo가 있으면 ContentRequest backlog에 자동 입력
  after_commit :enqueue_content_request, on: :create

  def enqueue_content_request
    return unless down? && memo.present?
    ContentRequest.from_feedback_memo(self)
  rescue => e
    Rails.logger.warn "[TopicFeedback#enqueue_content_request] #{e.class}: #{e.message}"
  end

  # 24h 중복 차단 — 같은 IP+UA hash로 같은 토픽에 1회만 허용
  def self.duplicate_within_24h?(topic_slug, ip_hash)
    where(topic_slug: topic_slug, ip_hash: ip_hash)
      .where("created_at > ?", 24.hours.ago)
      .exists?
  end
end
