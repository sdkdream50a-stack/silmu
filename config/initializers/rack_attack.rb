# Rack::Attack — Rate Limiting 설정
class Rack::Attack
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
