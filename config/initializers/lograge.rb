# 구조화 로깅 — 운영 환경에서 요청당 1라인 JSON으로 압축 출력
# - Sentry breadcrumb와 병행. lograge는 stdout/파일 기반 분석용.
# - 개발 환경은 기본 멀티라인 유지 (디버깅 용이).
Rails.application.configure do
  config.lograge.enabled = Rails.env.production?
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.base_controller_class = [ "ActionController::Base", "ActionController::API" ]

  # 헬스체크·assets 로그 억제 (디스크 절약)
  config.lograge.ignore_actions = [
    "Rails::HealthController#show",
    "ActiveStorage::Blobs::RedirectController#show",
  ]

  # Sentry가 처리하므로 에러 본문은 짧게
  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current.iso8601(3),
      remote_ip: event.payload[:remote_ip],
      user_id: event.payload[:user_id],
      params: event.payload[:params]&.except("controller", "action", "format", "utf8", "authenticity_token", "password", "password_confirmation"),
      exception: event.payload[:exception]&.first,
    }.compact
  end
end
