# RSS 피드 컨트롤러 — 백링크 및 구독자 확보용
class FeedController < ApplicationController
  # HTTP 캐싱: 피드는 1시간 캐시
  before_action -> { expires_in 1.hour, public: true }

  # GET /feed.rss
  def index
    # Sprint #5-C — needs_review 토픽 우선 (법령 개정 검토 중) + 최신 순
    review_topics = Topic.published.where(needs_review: true).order(review_flagged_at: :desc).limit(10)
    fresh_topics  = Topic.published.where(needs_review: false).order(updated_at: :desc).limit(20 - review_topics.size)
    @topics = review_topics.to_a + fresh_topics.to_a

    # 최신 감사사례 10개
    @audit_cases = AuditCase.published.order(created_at: :desc).limit(10)

    @updated_at = [ @topics.map(&:updated_at).max, @audit_cases.maximum(:created_at) ].compact.max

    respond_to do |format|
      format.rss { render layout: false }
    end
  end
end
