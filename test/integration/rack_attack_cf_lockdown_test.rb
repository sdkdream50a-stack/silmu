require "test_helper"

class RackAttackCfLockdownTest < ActiveSupport::TestCase
  # 실측: kamal-proxy는 XFF 체인에 [inbound_peer, self_docker_ip]를 append.
  # 따라서 origin_peer_ip는 XFF를 오른쪽→왼쪽으로 훑어 internal을 skip한
  # 뒤 나오는 첫 외부 IP를 반환해야 한다.

  def request_for(xff: nil, remote_addr: nil)
    env = {}
    env["HTTP_X_FORWARDED_FOR"] = xff if xff
    env["REMOTE_ADDR"] = remote_addr if remote_addr
    Rack::Request.new(env)
  end

  # --- 정상 CF 트래픽 ---

  test "CF 경유: XFF=[원클라이언트, cf-edge, kamal-docker] → CF IP로 인식" do
    # 실측 패턴 가까움: [real-client, cf-edge, 172.18.x]
    req = request_for(xff: "59.25.100.50, 162.158.138.226, 172.18.0.8")
    assert_equal "162.158.138.226", Rack::Attack.origin_peer_ip(req).to_s
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "CF IPv6 peer 인식" do
    req = request_for(xff: "2001:db8::1, 2606:4700::1, 172.18.0.8")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  # --- 우회 공격 ---

  test "우회 1: 외부 curl(XFF 없음) → kamal이 [peer, docker] 추가" do
    # 실측: curl --resolve 후 XFF = "124.54.81.27, 172.18.0.8"
    req = request_for(xff: "124.54.81.27, 172.18.0.8")
    assert_equal "124.54.81.27", Rack::Attack.origin_peer_ip(req).to_s
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "우회 2: 공격자가 CF IP 스푸핑해도 실제 peer로 판정" do
    # 공격자가 XFF=162.158.x.x로 위조 → kamal이 실제 peer 추가
    req = request_for(xff: "162.158.138.226, 45.205.1.8, 172.18.0.8")
    assert_equal "45.205.1.8", Rack::Attack.origin_peer_ip(req).to_s
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  test "우회 3: 공격자가 internal IP 삽입해도 실제 peer 드러남" do
    req = request_for(xff: "10.0.0.1, 192.168.1.1, 45.205.1.8, 172.18.0.8")
    assert_equal "45.205.1.8", Rack::Attack.origin_peer_ip(req).to_s
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  # --- 내부 트래픽 (헬스체크 등) ---

  test "순수 내부: XFF 전부 Docker 대역 → 통과" do
    req = request_for(xff: "172.18.0.1, 172.18.0.8")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 없고 REMOTE_ADDR이 Docker 내부 → 통과" do
    req = request_for(remote_addr: "172.18.0.1")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 없고 REMOTE_ADDR이 localhost → 통과" do
    req = request_for(remote_addr: "127.0.0.1")
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF 없고 REMOTE_ADDR이 외부 공인 IP (kamal-proxy 앞단 생략) → 차단" do
    # edge case: 어떤 이유로든 XFF가 없고 REMOTE_ADDR만 있는데 외부면 차단
    req = request_for(remote_addr: "45.205.1.8")
    assert_not Rack::Attack.cloudflare_peer?(req)
  end

  # --- fallback / 이상 입력 ---

  test "잘못된 IP 포맷 포함되면 해당 항목 skip" do
    req = request_for(xff: "not-an-ip, 162.158.138.226, 172.18.0.8")
    assert_equal "162.158.138.226", Rack::Attack.origin_peer_ip(req).to_s
    assert Rack::Attack.cloudflare_peer?(req)
  end

  test "XFF와 REMOTE_ADDR 둘 다 없으면 통과 (내부 트래픽으로 간주)" do
    req = request_for
    assert Rack::Attack.cloudflare_peer?(req)
  end

  # --- CF 대역 커버리지 ---

  test "CF IPv4 주요 대역 전부 검증" do
    [
      "173.245.48.1", "103.21.244.1", "141.101.64.1", "108.162.192.1",
      "198.41.128.1", "162.158.0.1", "104.16.0.1", "172.64.0.1", "131.0.72.1"
    ].each do |ip|
      req = request_for(xff: "#{ip}, 172.18.0.8")
      assert Rack::Attack.cloudflare_peer?(req), "Expected #{ip} to be recognized as CF peer"
    end
  end
end
