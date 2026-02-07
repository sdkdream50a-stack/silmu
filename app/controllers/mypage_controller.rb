class MypageController < ApplicationController
  before_action :authenticate_user!

  def index
    set_meta_tags(
      title: "마이페이지",
      robots: "noindex"
    )
  end
end
