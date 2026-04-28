# frozen_string_literal: true

class Admin::TopicFeedbacksController < Admin::BaseController
  include Pagy::Method

  def index
    scope = TopicFeedback.recent
    scope = scope.where(rating: params[:rating]) if params[:rating].present?
    scope = scope.where(topic_slug: params[:topic_slug]) if params[:topic_slug].present?

    @pagy, @feedbacks = pagy(:offset, scope, limit: 50)

    @stats = {
      total:    TopicFeedback.count,
      up:       TopicFeedback.up.count,
      down:     TopicFeedback.down.count,
      with_memo: TopicFeedback.where.not(memo: [ nil, "" ]).count,
      satisfaction_rate: TopicFeedback.count.zero? ? 0 : (TopicFeedback.up.count.to_f / TopicFeedback.count * 100).round(1)
    }
  end

  def destroy
    TopicFeedback.find(params[:id]).destroy
    redirect_to admin_topic_feedbacks_path, notice: "삭제했습니다."
  end
end
