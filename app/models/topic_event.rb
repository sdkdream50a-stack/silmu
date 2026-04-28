# frozen_string_literal: true

# Sprint #2-C — 토픽 사용자 행동 추적 3종
# 권위자 검증: Krug + Editorial Ops — 콘텐츠 의사결정 데이터 기반화
class TopicEvent < ApplicationRecord
  EVENT_TYPES = %w[scroll_depth time_on_page faq_open].freeze

  validates :topic_slug, :event_type, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }

  scope :for_topic,    ->(slug) { where(topic_slug: slug) }
  scope :scroll_depth, -> { where(event_type: "scroll_depth") }
  scope :time_on_page, -> { where(event_type: "time_on_page") }
  scope :faq_open,     -> { where(event_type: "faq_open") }
end
