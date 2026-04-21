require "test_helper"

class RackAttackCfLockdownTest < ActiveSupport::TestCase
  # cloudflare_peer? 판정 로직 단위 검증
  # (enforce/observe 모드 실제 토글은 ENV 의존이라 별도 통합 테스트에서 다룸)

  def request_for(xff: nil, remote_addr: nil)
    env = {}
    env["HTTP_X_FORWARDED_FOR"] = xff if xff
    env["REMOTE_ADDR"] = remote_addr if remote_addr
    Rack::Request.new(env)
  end

  test "XFF 마지막 엔트리가 CF IPv4 대역이면 통과" do
    req = request_for(xff: "1.2.3.4, 162.158.138.226")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 마지막 엔트리가 CF IPv6 대역이면 통과" do
    req = request_for(xff: "1.2.3.4, 2606:4700::1")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 마지막 엔트리가 비-CF 공인 IP면 차단" do
    req = request_for(xff: "1.2.3.4, 45.205.1.8")
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "스푸핑 방지: 첫 엔트리가 CF여도 마지막이 공격자 IP면 차단" do
    # 공격자가 XFF를 CF IP로 스푸핑해도 kamal-proxy가 실제 peer를 append하므로 끝자리로 판정
    req = request_for(xff: "162.158.138.226, 45.205.1.8")
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 없고 REMOTE_ADDR이 Docker 내부 대역이면 통과 (헬스체크)" do
    req = request_for(remote_addr: "172.18.0.1")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 없고 REMOTE_ADDR이 localhost면 통과" do
    req = request_for(remote_addr: "127.0.0.1")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 없고 REMOTE_ADDR이 외부 공인 IP면 차단" do
    req = request_for(remote_addr: "45.205.1.8")
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "잘못된 IP 포맷은 차단 (fail-closed)" do
    req = request_for(xff: "not-an-ip")
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF/REMOTE_ADDR 둘 다 없으면 차단" do
    req = request_for
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "CF 대역 전체 샘플 IPv4 검증" do
    # 각 CIDR의 첫 번째 host IP 샘플
    [
      "173.245.48.1",   # 173.245.48.0/20
      "103.21.244.1",   # 103.21.244.0/22
      "141.101.64.1",   # 141.101.64.0/18
      "108.162.192.1",  # 108.162.192.0/18
      "198.41.128.1",   # 198.41.128.0/17
      "162.158.0.1",    # 162.158.0.0/15
      "104.16.0.1",     # 104.16.0.0/13
      "172.64.0.1",     # 172.64.0.0/13
      "131.0.72.1"      # 131.0.72.0/22
    ].each do |ip|
      req = request_for(xff: ip)
      assert Rack::Attack.cloudflare_peer?(req), "Expected #{ip} to be recognized as CF IP"
    end
  end
end
