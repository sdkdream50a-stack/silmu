class FeedbackMailer < ApplicationMailer
  def notify(category:, content:, page_url:, email:)
    @category = category
    @content = content
    @page_url = page_url
    @email = email

    mail(
      to: "50adreamfire@gmail.com",
      subject: "[실무.kr 의견] #{category}"
    )
  end
end
