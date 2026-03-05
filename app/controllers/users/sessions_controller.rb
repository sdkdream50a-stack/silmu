class Users::SessionsController < Devise::SessionsController
  # 로그아웃은 데이터 변경이 없으므로 CSRF 검증 스킵
  # (로그인 후 세션 교체로 CSRF 토큰 불일치 발생하는 문제 해결)
  skip_before_action :verify_authenticity_token, only: :destroy
end
