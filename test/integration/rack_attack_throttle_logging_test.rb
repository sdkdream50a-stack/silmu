# frozen_string_literal: true

require "test_helper"

# P0-6 (2026-09-18) — 스로틀 관측.
#
# 막는 것: 스로틀이 걸렸는데 **기록이 없어** 사후에 판별할 수 없는 상태.
#   연수에서 «안 된다» 가 스로틀 때문인지 모르면 원인 추측으로 한도를 올리게 된다.
#
# 이 테스트는 한도를 검증하지 않는다(그건 운영 실측이 정본이다). 기록이 남는지만 본다.
class RackAttackThrottleLoggingTest < ActiveSupport::TestCase
  # ⚠️ 여기에 «listeners_for("throttle.rack_attack") 가 비어 있지 않다» 검사를 두었다가 지웠다.
  #    수리 전 코드에서도 **통과**했다 — Rack::Attack 자신이 그 이름에 리스너를 등록한다.
  #    「구독자가 있다」로는 **우리** 구독자를 구별하지 못한다. 그래서 아래처럼 행동으로 본다.

  test "스로틀 알림이 오면 warn 으로 기록한다" do
    logged = []
    fake_logger = Class.new do
      def initialize(sink) = @sink = sink
      def warn(msg) = @sink << msg
      def method_missing(*) = nil
      def respond_to_missing?(*) = true
    end.new(logged)

    original = Rails.logger
    Rails.logger = fake_logger
    begin
      env = Rack::MockRequest.env_for("/topics/private-contract")
      env["REMOTE_ADDR"] = "203.0.113.7"
      env["rack.attack.matched"] = "req/ip"
      env["rack.attack.match_data"] = { count: 501, limit: 500, period: 3600 }
      request = ActionDispatch::Request.new(env)

      ActiveSupport::Notifications.instrument(
        "throttle.rack_attack", request: request
      )
    ensure
      Rails.logger = original
    end

    assert_equal 1, logged.size, "스로틀 알림이 기록되지 않았다"
    line = logged.first
    assert_match(/\[rack-attack\] throttled/, line)
    assert_match(/name=req\/ip/, line, "어느 규칙에 걸렸는지 없다")
    assert_match(/count=501\/500/, line, "얼마나 넘겼는지 없다")
    assert_match(/period=3600/, line)
    assert_match(%r{path=/topics/private-contract}, line, "어느 경로였는지 없다")
  end

  test "request 가 없는 알림에도 죽지 않는다" do
    assert_nothing_raised do
      ActiveSupport::Notifications.instrument("throttle.rack_attack", request: nil)
    end
  end

  # 음성 대조 — 이 변경은 한도를 건드리지 않는다.
  test "req/ip 한도가 500/1시간 그대로다" do
    src = Rails.root.join("config/initializers/rack_attack.rb").read
    assert_match(/throttle\("req\/ip", limit: 500, period: 1\.hour\)/, src,
                 "관측을 붙이면서 한도를 바꿨다 — 측정 전 한도 변경은 하지 않기로 했다")
  end

  test "실측 근거가 코드에 기록돼 있다" do
    # 「req.ip 가 CF 엣지 IP 로 해석된다」는 추론이 아니라 운영 실측이다.
    # 다음 세션이 이 전제를 다시 연구하지 않도록 근거를 코드에 남긴다.
    src = Rails.root.join("config/initializers/rack_attack.rb").read
    assert_includes src, "469/469", "실측 수치가 없다 — 다음 세션이 다시 추측한다"
    assert_includes src, "Cloudflare 엣지 IP"
  end
end
