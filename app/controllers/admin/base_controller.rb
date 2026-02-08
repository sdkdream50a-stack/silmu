class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  private

  def authenticate_admin!
    authenticate_user!
    redirect_to root_path, alert: "접근 권한이 없습니다." unless current_user.admin?
  end
end
