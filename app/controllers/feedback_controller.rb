class FeedbackController < ApplicationController
  def index
    set_meta_tags(
      title: "의견보내기",
      description: "실무.kr 콘텐츠 수정 요청, 자료 추가 요청, 기타 의견을 보내주세요.",
      og: { title: "의견보내기 — 실무.kr", url: canonical_url }
    )
  end

  def create
    category = params[:category].to_s.strip
    content = params[:content].to_s.strip
    page_url = params[:page_url].to_s.strip
    email = params[:email].to_s.strip

    if content.blank?
      render turbo_stream: turbo_stream.replace("feedback-result",
        partial: "feedback/result", locals: { success: false, message: "내용을 입력해주세요." })
      return
    end

    FeedbackMailer.notify(
      category: category,
      content: content,
      page_url: page_url,
      email: email
    ).deliver_later

    render turbo_stream: turbo_stream.replace("feedback-result",
      partial: "feedback/result", locals: { success: true, message: "의견이 전송되었습니다. 감사합니다!" })
  end
end
