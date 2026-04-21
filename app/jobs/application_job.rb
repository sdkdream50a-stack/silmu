class ApplicationJob < ActiveJob::Base
  # DB 일시적 경합은 폴리노미얼 백오프로 재시도
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 3

  # 네트워크·외부 API 일시 오류도 재시도
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  # 레코드 삭제 등으로 역직렬화 실패한 잡은 조용히 폐기
  discard_on ActiveJob::DeserializationError

  # 최종 실패 시 Sentry 보고 (재시도 소진 포함)
  rescue_from StandardError do |error|
    Sentry.capture_exception(error, extra: { job: self.class.name, args: arguments.inspect }) if defined?(Sentry)
    raise
  end
end
