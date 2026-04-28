# frozen_string_literal: true

# Sprint #4-B — 법령 개정 영향 토픽 검토 (Westlaw + Editorial Ops 권위자)
class Admin::TopicReviewsController < Admin::BaseController
  def index
    @topics = Topic.where(needs_review: true).order(review_flagged_at: :desc)
    @stats = {
      pending: @topics.size,
      total_law_synced: Law.count,
      last_sync: Law.maximum(:updated_at)
    }
  end

  # 검토 완료 → flag 해제
  def resolve
    topic = Topic.find(params[:id])
    topic.update_columns(
      needs_review: false,
      review_reason: nil,
      review_flagged_at: nil,
      law_verified_at: Time.current,
      law_base_date: Time.zone.today.strftime("%Y.%m.%d")
    )
    redirect_to admin_topic_reviews_path, notice: "검토 완료 처리: #{topic.slug}"
  end
end
