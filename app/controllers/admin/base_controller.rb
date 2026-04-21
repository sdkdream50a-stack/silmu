class Admin::BaseController < ApplicationController
  ADMIN_REAUTH_WINDOW = 30.minutes

  before_action :authenticate_admin!
  before_action :require_recent_admin_auth

  private

  def authenticate_admin!
    authenticate_user!
    redirect_to root_path, alert: "접근 권한이 없습니다." unless current_user.admin?
  end

  def require_recent_admin_auth
    return if admin_recently_authenticated?

    session[:admin_return_to] = request.fullpath if request.get?
    redirect_to admin_new_reauthentication_path,
                alert: "관리자 영역 접근을 위해 비밀번호를 다시 입력해주세요. (마지막 인증 #{ADMIN_REAUTH_WINDOW.inspect} 초과)"
  end

  def admin_recently_authenticated?
    confirmed_at = session[:admin_confirmed_at]
    confirmed_at.present? && Time.zone.at(confirmed_at.to_i) > ADMIN_REAUTH_WINDOW.ago
  end
end
