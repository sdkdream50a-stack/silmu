# Created: 2026-02-17
class WelcomeMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(
      to: @user.email,
      subject: "실무.kr에 오신 것을 환영합니다 🎉"
    )
  end
end
