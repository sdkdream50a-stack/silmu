class LawChangeSubscriptionsController < ApplicationController
  def create
    email = current_user&.email || params[:email]
    sub = LawChangeSubscription.find_or_initialize_by(
      email: email,
      topic_slug: params[:topic_slug]
    )
    is_new = sub.new_record?
    sub.topic_name = params[:topic_name]
    sub.user = current_user
    sub.active = true

    if sub.save
      # 신규 구독자에게만 확인 이메일 발송
      LawSubscriptionMailer.confirmation(sub).deliver_later if is_new

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

  def destroy
    sub = LawChangeSubscription.find(params[:id])
    # 본인 구독만 해지 가능 (이메일 또는 로그인 사용자 확인)
    if sub.user == current_user || sub.email == current_user&.email
      sub.update!(active: false)
      respond_to do |format|
        format.html { redirect_back fallback_location: mypage_path, notice: "알림 구독이 해지되었습니다." }
        format.turbo_stream {
          render turbo_stream: turbo_stream.remove("subscription-#{sub.id}")
        }
      end
    else
      redirect_back fallback_location: root_path, alert: "권한이 없습니다."
    end
  end
end
