class NewsletterMailer < ApplicationMailer
  def send_newsletter(user, subject, body)
    @body = body
    @user = user
    mail(to: user.email, subject: subject)
  end
end
