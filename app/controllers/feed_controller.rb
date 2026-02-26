# RSS 피드 컨트롤러 — 백링크 및 구독자 확보용
class FeedController < ApplicationController
  # HTTP 캐싱: 피드는 1시간 캐시
  before_action -> { expires_in 1.hour, public: true }

  # GET /feed.rss
  def index
    # 최신 토픽 20개
    @topics = Topic.order(updated_at: :desc).limit(20)

    # 최신 감사사례 10개
    @audit_cases = AuditCase.order(created_at: :desc).limit(10)

    @updated_at = [@topics.maximum(:updated_at), @audit_cases.maximum(:created_at)].compact.max

    respond_to do |format|
      format.rss { render layout: false }
    end
  end
end
