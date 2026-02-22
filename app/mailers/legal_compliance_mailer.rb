class LegalComplianceMailer < ApplicationMailer
  default from: 'noreply@silmu.kr'

  # 주간 요약 리포트 (매주 월요일)
  def weekly_summary(report)
    @report = report
    @timestamp = report[:timestamp] || Time.current

    mail(
      to: ENV['ADMIN_EMAIL'],
      subject: "[실무.kr] 법령 주간 검증 리포트 (#{@timestamp.strftime('%Y-%m-%d')})"
    )
  end

  # 월간 AI 심층 검증 리포트 (매월 1일)
  def monthly_deep_check(result)
    @result = result
    @changes = result[:changes] || []
    @errors = result[:errors] || []
    @timestamp = Time.current

    mail(
      to: ENV['ADMIN_EMAIL'],
      subject: "[실무.kr] 법령 AI 검증 월간 리포트 (#{@timestamp.strftime('%Y년 %m월')})"
    )
  end

  # 오류 알림 (즉시 발송)
  def error_alert(error_message)
    @error_message = error_message
    @timestamp = Time.current

    mail(
      to: ENV['ADMIN_EMAIL'],
      subject: "[긴급] 실무.kr 법령 검증 오류 발생"
    )
  end

  # AI 검증 트리거 리포트 (중대 오류 발견 시)
  def ai_triggered_check(result, triggering_errors)
    @result = result
    @triggering_errors = triggering_errors
    @changes = result[:changes] || []
    @errors = result[:errors] || []
    @timestamp = Time.current

    mail(
      to: ENV['ADMIN_EMAIL'],
      subject: "[실무.kr] AI 법령 검증 결과 (중대 오류 #{triggering_errors.count}건 발견)"
    )
  end
end
