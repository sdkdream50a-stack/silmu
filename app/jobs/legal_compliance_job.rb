class LegalComplianceJob < ApplicationJob
  queue_as :default

  def perform(mode = "check")
    case mode
    when "check"
      # 기본 검증 (패턴 매칭)
      run_basic_check
    when "deep_check"
      # AI 심층 검증 (Anthropic API)
      run_deep_check
    else
      Rails.logger.error "Unknown legal compliance mode: #{mode}"
    end
  end

  private

  def run_basic_check
    Rails.logger.info "=" * 60
    Rails.logger.info "법령 자동 검증 시작 (기본 모드): #{Time.current}"
    Rails.logger.info "=" * 60

    # Open3를 사용하여 검증 실행 (exit code 무시)
    require 'open3'
    stdout, stderr, status = Open3.capture3("cd #{Rails.root} && bundle exec rake legal:ci_check 2>&1")

    begin
      # JSON만 추출 (첫 번째 { 부터 마지막 } 까지)
      json_match = stdout.match(/(\{[\s\S]*\})/)
      raise JSON::ParserError, "JSON not found in output" unless json_match

      result = JSON.parse(json_match[1], symbolize_names: true)

      report = {
        success: result[:success],
        scanned_files: result[:scanned_files] || 0,
        checked_files: result[:checked_files] || 0,
        errors: result[:errors] || [],
        warnings: result[:warnings] || [],
        timestamp: Time.current
      }

      if report[:success]
        Rails.logger.info "✅ 법령 검증 완료: 모든 항목 정상"
      else
        Rails.logger.warn "⚠️ 법령 검증: #{report[:errors].count}건 오류 발견"
      end

      # 이메일 발송 (성공/실패 모두)
      if ENV['ADMIN_EMAIL'].present?
        LegalComplianceMailer.weekly_summary(report).deliver_now
        Rails.logger.info "📧 주간 요약 이메일 발송 완료"
      end

    rescue JSON::ParserError => e
      Rails.logger.error "❌ 검증 결과 파싱 실패"
      Rails.logger.error "STDOUT: #{stdout}"
      Rails.logger.error "STDERR: #{stderr}"

      # 파싱 실패 시 알림 이메일 발송
      if ENV['ADMIN_EMAIL'].present?
        error_msg = "검증 결과 파싱 실패\n\nSTDOUT:\n#{stdout}\n\nSTDERR:\n#{stderr}"
        LegalComplianceMailer.error_alert(error_msg).deliver_now
        Rails.logger.info "📧 오류 알림 이메일 발송 완료"
      end
    end
  end

  def run_deep_check
    Rails.logger.info "=" * 60
    Rails.logger.info "법령 AI 심층 검증 시작: #{Time.current}"
    Rails.logger.info "=" * 60

    unless ENV['ANTHROPIC_API_KEY'].present?
      Rails.logger.warn "⚠️ ANTHROPIC_API_KEY 미설정, AI 검증 건너뜀"
      return
    end

    begin
      verifier = RegulationVerifier.new
      result = verifier.verify_all

      Rails.logger.info "=" * 60
      Rails.logger.info "AI 검증 완료"
      Rails.logger.info "수정: #{result[:changes].count}건"
      Rails.logger.info "오류: #{result[:errors].count}건"
      Rails.logger.info "=" * 60

      # 결과 이메일 발송
      if ENV['ADMIN_EMAIL'].present?
        LegalComplianceMailer.monthly_deep_check(result).deliver_now
        Rails.logger.info "📧 월간 AI 검증 리포트 이메일 발송 완료"
      end

    rescue StandardError => e
      Rails.logger.error "❌ AI 검증 중 오류 발생: #{e.message}"

      if ENV['ADMIN_EMAIL'].present?
        LegalComplianceMailer.error_alert(e.message).deliver_now
      end
    end
  end

end
