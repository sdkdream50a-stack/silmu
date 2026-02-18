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
end
