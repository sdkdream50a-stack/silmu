# frozen_string_literal: true

require "test_helper"

# G-62 · G-63 (2026-09-18) — 스로틀의 «신원»과 미들웨어 스택.
#
# 두 결함 모두 «지금 당장 피해가 나고 있지는 않다» 였다. 그래서 더더욱 검사가 필요하다 —
# 앞단(Cloudflare)이 한 겹 무너지면 바로 뚫리는 축이고, 그때는 아무도 못 알아챈다.
class RackAttackIdentityTest < ActionDispatch::IntegrationTest
  # ── G-63 : 클라이언트가 보낸 Forwarded 헤더가 신원이 되면 안 된다
  test "클라이언트 Forwarded 헤더가 throttle 키가 되지 않는다" do
    env = Rack::MockRequest.env_for(
      "/",
      "HTTP_FORWARDED" => "for=1.2.3.4",
      "HTTP_X_FORWARDED_FOR" => "203.0.113.9",
      "REMOTE_ADDR" => "10.0.0.5"
    )
    ip = Rack::Request.new(env).ip

    assert_not_equal "1.2.3.4", ip,
                     "클라이언트가 보낸 Forwarded 헤더가 신원이 됐다 — 한도 회피와 타인 카운터 오염이 가능하다"
    assert_equal "203.0.113.9", ip, "프록시가 세운 X-Forwarded-For 를 써야 한다"
  end

  test "Forwarded 헤더만 있고 XFF 가 없으면 그 값을 쓰지 않는다" do
    env = Rack::MockRequest.env_for(
      "/", "HTTP_FORWARDED" => "for=1.2.3.4", "REMOTE_ADDR" => "10.0.0.5"
    )
    assert_not_equal "1.2.3.4", Rack::Request.new(env).ip,
                     "XFF 가 없으면 Forwarded 로 되돌아간다 — 우선순위 설정이 적용되지 않았다"
  end

  test "설정이 실제로 좁혀져 있다" do
    assert_equal [ :x_forwarded ], Rack::Request.forwarded_priority,
                 "Rack 기본값(:forwarded 포함)으로 되돌아갔다"
  end

  # ── G-62 : 미들웨어가 한 번만 등록된다
  test "Rack::Attack 이 미들웨어 스택에 한 번만 있다" do
    entries = Rails.application.middleware.map(&:name).grep(/\ARack::Attack\z/)
    assert_equal 1, entries.size,
                 "Rack::Attack 이 #{entries.size}회 등록됐다 — gem railtie 가 이미 넣으므로 application.rb 에서 또 use 하면 안 된다"
  end

  test "등록을 지워도 스로틀 규칙은 살아 있다" do  # 비퇴화 — 중복 제거가 기능을 끄지 않았는가
    assert Rack::Attack.configuration.throttles.key?("login/ip"),
           "throttle 규칙이 사라졌다"
    assert Rack::Attack.configuration.throttles.key?("req/ip")
    # cf-lockdown 은 `CF_ORIGIN_LOCKDOWN` env 로 켜지는 **조건부** 등록이라 test 환경에는 없다
    # (운영은 enforce). 그래서 «등록됐는가» 가 아니라 «그 분기가 살아 있는가» 를 본다.
    src = Rails.root.join("config/initializers/rack_attack.rb").read
    assert src.include?('blocklist("cf-lockdown/enforce")'),
           "origin lockdown 분기가 사라졌다"
    assert src.include?('track("cf-lockdown/observe")'),
           "origin lockdown observe 분기가 사라졌다"
  end
end
