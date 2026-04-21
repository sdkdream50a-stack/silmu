# 관리자 사용자가 새로 로그인(비밀번호·OAuth 공통)할 때마다
# 세션에 admin_confirmed_at 타임스탬프를 찍어 step-up 인증 상태를 갱신한다.
# :fetch(기존 세션 복원)는 제외 — 새 인증 이벤트에서만 적용.
Rails.application.reloader.to_prepare do
  Warden::Manager.after_set_user except: :fetch do |user, auth, _opts|
    if user.respond_to?(:admin?) && user.admin?
      auth.request.session[:admin_confirmed_at] = Time.current.to_i
    end
  rescue StandardError => e
    Rails.logger.warn "[WardenAdminHook] #{e.class}: #{e.message}"
  end
end
