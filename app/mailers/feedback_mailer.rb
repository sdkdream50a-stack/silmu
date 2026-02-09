class FeedbackMailer < ApplicationMailer
  def notify(category:, content:, page_url:, email:)
    @category = category
    @content = content
    @page_url = page_url
    @email = email

    mail(
      to: "hello@silmu.kr",
      subject: "[실무.kr 의견] #{category}"
    )
  end
end
