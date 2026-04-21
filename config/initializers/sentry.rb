Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.traces_sample_rate = 0.1
  config.profiles_sample_rate = 0.1
  config.enabled_environments = %w[production]

  # PII 스크러빙 — 이메일/IP 등 사용자 식별정보를 이벤트에 포함하지 않음
  config.send_default_pii = false

  # 노이즈 제거 — 라우팅 오류는 봇 스캔으로 대량 유입되어 Sentry 쿼터 낭비
  config.excluded_exceptions += %w[
    ActionController::RoutingError
    ActionController::UnknownFormat
    ActionController::BadRequest
    ActiveRecord::RecordNotFound
  ]

  # 요청 파라미터 내 민감 필드 추가 스크러빙
  config.before_send = lambda do |event, _hint|
    if event.request&.data.is_a?(Hash)
      %w[password password_confirmation current_password token api_key authorization].each do |k|
        event.request.data[k] = "[FILTERED]" if event.request.data.key?(k)
      end
    end
    event
  end
end
