# Admin step-up 재인증 — Admin::BaseController를 상속하지 않음 (순환 차단)
class Admin::ReauthenticationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def new
  end

  def create
    password = params[:password].to_s

    if current_user.valid_password?(password)
      session[:admin_confirmed_at] = Time.current.to_i
      redirect_to(session.delete(:admin_return_to) || admin_analytics_path,
                  notice: "재인증되었습니다. 30분간 관리자 작업이 허용됩니다.")
    else
      flash.now[:alert] = "비밀번호가 일치하지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_admin
    redirect_to root_path, alert: "접근 권한이 없습니다." unless current_user&.admin?
  end
end
