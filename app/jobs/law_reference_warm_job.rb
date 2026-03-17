# frozen_string_literal: true

# 법제처 API 법령 원문 링크를 백그라운드에서 캐시 워밍
# 토픽 페이지 첫 방문(캐시 miss) 시 enqueue → LCP 블로킹 방지
class LawReferenceWarmJob < ApplicationJob
  queue_as :default

  def perform(topic_slug)
    result = LawContentFetcher.new.fetch_for_topic(topic_slug)
    return if result.blank?

    Rails.cache.write(
      "topic_law_refs/v1/#{topic_slug}",
      result,
      expires_in: 7.days
    )
    Rails.logger.info "[LawReferenceWarmJob] 캐시 워밍 완료: #{topic_slug}"
  rescue => e
    Rails.logger.warn "[LawReferenceWarmJob] 실패 (#{topic_slug}): #{e.message}"
  end
end
