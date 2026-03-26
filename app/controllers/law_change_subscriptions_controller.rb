class LawChangeSubscriptionsController < ApplicationController
  def create
    email = current_user&.email || params[:email]
    sub = LawChangeSubscription.find_or_initialize_by(
      email: email,
      topic_slug: params[:topic_slug]
    )
    sub.topic_name = params[:topic_name]
    sub.user = current_user
    sub.active = true

    if sub.save
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "알림 구독이 완료되었습니다." }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "law-subscription-#{params[:topic_slug]}",
            partial: "law_change_subscriptions/subscribed",
            locals: { topic_name: params[:topic_name] }
          )
        }
      end
    else
      redirect_back fallback_location: root_path, alert: sub.errors.full_messages.join(", ")
    end
  end
end
