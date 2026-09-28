require "test_helper"
require "socket"
require "net/http"
require "yaml"

# 2026-09-28 — 운영 Thruster(./bin/thrust)의 HTTP 캐시 키는 method·path·query·host(+Vary)뿐이라 쿠키를 보지 않는다.
# 익명 public 응답이 저장되면 로그인 요청(Cloudflare 는 silmu_auth 로 우회)도 같은 URL 에서 그 익명 사본을 받아
# 로그인 사용자가 비로그인 nav 를 봤다(x-cache: hit · data-user-signed-in=false 실측). Thruster 에는 쿠키 우회 옵션이 없어
# 원본 캐시를 끈다(CACHE_SIZE=0). 공개 화면 캐시는 Cloudflare 가 계속 맡는다.
#
# 실제 thrust 바이너리를 작은 업스트림 앞에 띄워 확인한다. 업스트림은 앱과 같은 규칙을 흉내 낸다:
# silmu_auth=1 이면 로그인 화면 + no-store, 아니면 익명 화면 + public.
class ThrusterSignedInCacheTest < ActiveSupport::TestCase
  UPSTREAM = <<~'RUBY'.freeze
    require "socket"
    server = TCPServer.new("127.0.0.1", Integer(ENV.fetch("PORT")))
    loop do
      client = server.accept
      head = +""
      while (line = client.gets) && line != "\r\n"
        head << line
      end
      signed = head.match?(/^cookie:.*silmu_auth=1/i)
      body = signed ? %(<body data-user-signed-in="true">) : %(<body data-user-signed-in="false">)
      cache = signed ? "no-store" : "public, max-age=3600"
      client.write "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nCache-Control: #{cache}\r\n" \
                   "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
      client.close
    end
  RUBY

  test "production Thruster env disables the origin cache" do
    assert_equal "0", production_env["CACHE_SIZE"].to_s,
      "config/deploy.yml env.clear 에 CACHE_SIZE: 0 이 있어야 Thruster 가 익명 사본을 로그인 요청에 주지 않는다"
  end

  test "control: default Thruster cache serves the anonymous copy to a signed-in request" do
    with_thruster({}) do |get|
      assert_equal "false", get.call(nil)
      assert_equal "false", get.call("silmu_auth=1"), "대조군이 결함을 재현하지 못하면 아래 검사도 의미가 없다"
    end
  end

  test "production env: signed-in request reaches origin, anonymous stays anonymous" do
    env = { "CACHE_SIZE" => production_env["CACHE_SIZE"].to_s }
    with_thruster(env) do |get|
      assert_equal "false", get.call(nil)
      assert_equal "true", get.call("silmu_auth=1")
      assert_equal "true", get.call("silmu_auth=1; remember_user_token=x")
      # 로그아웃 뒤(표시 쿠키 없음)는 다시 익명 화면 — 로그인 렌더가 익명 요청에 새지 않는다.
      assert_equal "false", get.call(nil)
      assert_equal "false", get.call("_silmu_session=abc")
    end
  end

  private

  def production_env
    YAML.load_file(Rails.root.join("config/deploy.yml")).dig("env", "clear") || {}
  end

  def free_port
    server = TCPServer.new("127.0.0.1", 0)
    server.addr[1]
  ensure
    server&.close
  end

  def with_thruster(extra_env)
    Dir.mktmpdir do |dir|
      upstream = File.join(dir, "upstream.rb")
      File.write(upstream, UPSTREAM)
      http_port = free_port
      env = { "HTTP_PORT" => http_port.to_s, "TARGET_PORT" => free_port.to_s, "STORAGE_PATH" => dir }.merge(extra_env)
      env["PORT"] = env["TARGET_PORT"]
      pid = Process.spawn(env, Rails.root.join("bin/thrust").to_s, RbConfig.ruby, upstream,
        out: File::NULL, err: File::NULL, pgroup: true)
      begin
        get = lambda do |cookie|
          request = Net::HTTP::Get.new("/tools")
          request["Cookie"] = cookie if cookie
          Net::HTTP.start("127.0.0.1", http_port) { |http| http.request(request) }.body[/data-user-signed-in="(\w+)"/, 1]
        end
        wait_until_up(get)
        yield get
      ensure
        Process.kill("TERM", -pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  end

  # 준비 확인은 쿠키 요청으로만 한다 — 익명 요청으로 기다리면 그 응답이 캐시에 먼저 들어가 대조군 순서가 흐려진다.
  def wait_until_up(get)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 15
    loop do
      return if (get.call("silmu_auth=1") rescue nil) # 업스트림 기동 전에는 연결 실패 또는 502(본문 불일치)
      raise "thrust did not start" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.1
    end
  end
end
