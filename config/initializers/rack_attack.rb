# Rack::Attack — Rate Limiting + Cloudflare-Only Origin Lockdown
require "ipaddr"

File.open("/tmp/cf_lockdown.log", "a") { |f| f.write("[boot] rack_attack.rb loaded at #{Time.now.iso8601}\n") }

class Rack::Attack
  # Cloudflare 공식 IP 대역 (https://www.cloudflare.com/ips/)
  # kamal-proxy가 TCP peer를 XFF 끝자리에 append하므로, 정상 CF 요청은 XFF 끝자리가 CF 대역
  CLOUDFLARE_RANGES = %w[
    173.245.48.0/20
    103.21.244.0/22
    103.22.200.0/22
    103.31.4.0/22
    141.101.64.0/18
    108.162.192.0/18
    190.93.240.0/20
    188.114.96.0/20
    197.234.240.0/22
    198.41.128.0/17
    162.158.0.0/15
    104.16.0.0/13
    104.24.0.0/14
    172.64.0.0/13
    131.0.72.0/22
    2400:cb00::/32
    2606:4700::/32
    2803:f800::/32
    2405:b500::/32
    2405:8100::/32
    2a06:98c0::/29
    2c0f:f248::/32
  ].map { |cidr| IPAddr.new(cidr) }.freeze

  # Docker/내부 네트워크 (kamal-proxy → silmu-web 헬스체크, 내부 라우팅)
  INTERNAL_RANGES = %w[
    127.0.0.0/8
    10.0.0.0/8
    172.16.0.0/12
    192.168.0.0/16
    ::1/128
    fc00::/7
  ].map { |cidr| IPAddr.new(cidr) }.freeze

  ALLOWED_PEER_RANGES = (CLOUDFLARE_RANGES + INTERNAL_RANGES).freeze

  # kamal-proxy가 append하는 TCP peer = XFF 마지막 엔트리 (스푸핑 불가)
  def self.origin_peer_ip(req)
    xff = req.env["HTTP_X_FORWARDED_FOR"]
    candidate = xff.present? ? xff.split(",").last.strip : req.env["REMOTE_ADDR"]
    IPAddr.new(candidate)
  rescue IPAddr::InvalidAddressError, ArgumentError
    nil
  end

  def self.cloudflare_peer?(req)
    ip = origin_peer_ip(req)
    return false if ip.nil?
    ALLOWED_PEER_RANGES.any? { |net| net.include?(ip) }
  end

  # 3단계 락다운 모드 (ENV: CF_ORIGIN_LOCKDOWN)
  #   off      = 검사 안 함 (기본값)
  #   observe  = 차단하지 않고 로그만 (롤아웃 검증용)
  #   enforce  = 403 차단 + 로그
  CF_LOCKDOWN_MODE = ENV.fetch("CF_ORIGIN_LOCKDOWN", "off").downcase.freeze

  CF_LOCKDOWN_LOG_PATH = "/tmp/cf_lockdown.log".freeze

  def self.log_non_cf_origin(tag, req)
    peer = origin_peer_ip(req)&.to_s || req.env["REMOTE_ADDR"]
    xff = req.env["HTTP_X_FORWARDED_FOR"]
    line = "[cf-lockdown:#{tag}] #{Time.now.iso8601} peer=#{peer} xff=#{xff&.slice(0, 120)} host=#{req.host} path=#{req.path}\n"
    # 파일 직접 기록 — lograge/Rails.logger 경로에 의존하지 않음
    File.open(CF_LOCKDOWN_LOG_PATH, "a") { |f| f.write(line) }
  rescue => e
    $stderr.puts("[cf-lockdown] log write failed: #{e.message}")
  end

  if CF_LOCKDOWN_MODE == "observe"
    track("cf-lockdown/observe") do |req|
      unless cloudflare_peer?(req)
        log_non_cf_origin("observe", req)
        true
      end
    end
  elsif CF_LOCKDOWN_MODE == "enforce"
    blocklist("cf-lockdown/enforce") do |req|
      blocked = !cloudflare_peer?(req)
      log_non_cf_origin("block", req) if blocked
      blocked
    end
  end

  # 로그인 시도: IP당 분당 5회, 시간당 20회
  throttle("login/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("login/ip/hour", limit: 20, period: 1.hour) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # 전체 요청: IP당 시간당 500회
  throttle("req/ip", limit: 500, period: 1.hour) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Blog autopilot API: IP당 분당 30회 (write 엔드포인트 보호)
  throttle("api/v1/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/")
  end

  # llms-full.txt: IP당 분당 10회 (대용량 덤프 보호)
  throttle("llms-full/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/llms-full.txt"
  end

  # 차단 시 응답
  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "text/plain" }, [ "요청이 너무 많습니다. 잠시 후 다시 시도하세요." ] ]
  end
end
