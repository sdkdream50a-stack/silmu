class LawSubscriptionMailer < ApplicationMailer
  # 구독 확인 이메일
  def confirmation(subscription)
    @subscription = subscription
    @topic_name = subscription.topic_name
    @unsubscribe_url = law_change_subscription_url(subscription, _method: :delete)

    mail(
      to: subscription.email,
      subject: "#{@topic_name} 법령 개정 알림 구독 완료 — 실무.kr"
    )
  end

  # 법령 개정 알림 이메일
  def law_changed(subscription, changed_law_name)
    @subscription = subscription
    @topic_name = subscription.topic_name
    @changed_law_name = changed_law_name
    @topic_url = topic_url(subscription.topic_slug)
    @unsubscribe_url = law_change_subscription_url(subscription, _method: :delete)

    mail(
      to: subscription.email,
      subject: "📋 [법령 개정 알림] #{@changed_law_name} 이 개정되었습니다 — 실무.kr"
    )
  end
end
