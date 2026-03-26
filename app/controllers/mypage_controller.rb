class MypageController < ApplicationController
  before_action :authenticate_user!

  def index
    recent_slugs  = JSON.parse(cookies[:recent_guides] || "[]") rescue []
    @recent_guides = recent_slugs.filter_map { |slug| Guide.published.find_by(slug: slug) }

    set_meta_tags(
      title: "마이페이지",
      robots: "noindex"
    )
  end

  def update_newsletter
    agreed = params[:newsletter_agreed] == "1"
    current_user.update!(newsletter_agreed: agreed)

    message = agreed ? "뉴스레터 수신이 등록되었습니다." : "뉴스레터 수신이 해제되었습니다."
    redirect_to mypage_path, notice: message
  end
end
