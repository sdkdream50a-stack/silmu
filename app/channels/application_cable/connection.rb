module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Devise 세션에서 현재 사용자 확인 (nil 허용 — 비로그인 사용자도 연결 가능)
      env["warden"]&.user
    rescue
      nil
    end
  end
end
