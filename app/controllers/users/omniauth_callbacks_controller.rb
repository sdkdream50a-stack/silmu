class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def kakao
    handle_auth("카카오")
  end

  def naver
    handle_auth("네이버")
  end

  def failure
    redirect_to root_path, alert: "소셜 로그인에 실패했습니다. 다시 시도해주세요."
  end

  private

  def handle_auth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      session["devise.omniauth_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: "#{kind} 계정 연동에 문제가 발생했습니다."
    end
  end
end
