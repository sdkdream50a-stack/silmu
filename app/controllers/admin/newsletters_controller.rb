class Admin::NewslettersController < Admin::BaseController
  def new
    @subscriber_count = User.where(newsletter_agreed: true).count
  end

  def create
    subject = params[:subject]
    body = params[:body]

    if subject.blank? || body.blank?
      @subscriber_count = User.where(newsletter_agreed: true).count
      flash.now[:alert] = "제목과 본문을 모두 입력해주세요."
      render :new, status: :unprocessable_entity
      return
    end

    subscribers = User.where(newsletter_agreed: true)
    subscribers.find_each do |user|
      NewsletterMailer.send_newsletter(user, subject, body).deliver_later
    end

    redirect_to new_admin_newsletter_path, notice: "#{subscribers.count}명에게 뉴스레터를 발송했습니다."
  end
end
