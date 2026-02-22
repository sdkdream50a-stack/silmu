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
    Rails.logger.info "법령 하이브리드 검증 시작 (규칙 기반 + AI): #{Time.current}"
    Rails.logger.info "=" * 60

    # 1단계: 규칙 기반 검증 실행 (무료)
    require 'open3'
    stdout, stderr, status = Open3.capture3("cd #{Rails.root} && bundle exec rake legal:ci_check 2>&1")

    begin
      # JSON만 추출
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

      Rails.logger.info "📋 규칙 기반 검증 완료: #{report[:errors].count}건 오류, #{report[:warnings].count}건 경고"

      # 2단계: 중대 오류 분석
      critical_errors = report[:errors].select { |e| is_critical_error?(e) }

      if critical_errors.any?
        Rails.logger.warn "⚠️ 중대 오류 발견 (#{critical_errors.count}건) → AI 심층 검증 트리거"

        # AI 검증 실행 (비용 발생)
        ai_result = run_ai_verification(critical_errors)
        report[:ai_verification] = ai_result
      else
        Rails.logger.info "✅ 중대 오류 없음 → AI 검증 스킵 (비용 절감)"
        report[:ai_verification] = { skipped: true, reason: "중대 오류 없음" }
      end

      # 이메일 발송
      if ENV['ADMIN_EMAIL'].present?
        LegalComplianceMailer.weekly_summary(report).deliver_now
        Rails.logger.info "📧 검증 결과 이메일 발송 완료"
      end

    rescue JSON::ParserError => e
      Rails.logger.error "❌ 검증 결과 파싱 실패"
      Rails.logger.warn "⚠️ 안전을 위해 AI 검증 실행"

      # 파싱 실패 시 안전하게 AI 검증 실행
      run_ai_verification([])

      if ENV['ADMIN_EMAIL'].present?
        error_msg = "검증 결과 파싱 실패\n\nSTDOUT:\n#{stdout}\n\nSTDERR:\n#{stderr}"
        LegalComplianceMailer.error_alert(error_msg).deliver_now
      end
    end
  end

  def run_deep_check
    Rails.logger.info "=" * 60
    Rails.logger.info "법령 AI 심층 검증 시작 (전체): #{Time.current}"
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

  # 중대 오류 판단 (AI 검증 트리거 기준)
  def is_critical_error?(error)
    error_text = (error[:message] || error[:description] || "").to_s

    # 중대 오류 패턴
    critical_patterns = [
      /금액.*불일치/i,
      /금액.*잘못/i,
      /법령.*오류/i,
      /조문.*잘못/i,
      /조문.*오류/i,
      /\d+억\s*원/,
      /\d+천만\s*원/,
      /\d+,\d+만\s*원/,
      /시행령.*제\d+조/,
      /지방계약법/i,
      /공무원여비규정/i
    ]

    critical_patterns.any? { |pattern| error_text.match?(pattern) }
  end

  # AI 검증 실행 (오류 발견 시에만)
  def run_ai_verification(triggering_errors)
    Rails.logger.info "🤖 AI 심층 검증 시작 (트리거: #{triggering_errors.count}건 중대 오류)"

    unless ENV['ANTHROPIC_API_KEY'].present?
      Rails.logger.warn "⚠️ ANTHROPIC_API_KEY 미설정, AI 검증 건너뜀"
      return { skipped: true, reason: "API 키 없음" }
    end

    begin
      verifier = RegulationVerifier.new
      result = verifier.verify_all

      Rails.logger.info "🤖 AI 검증 완료"
      Rails.logger.info "   토픽 변경: #{result[:changes].count}건"
      Rails.logger.info "   도구 오류: #{result[:errors].select { |e| e[:tool] }.count}건"

      # AI 검증 결과 이메일 발송
      if ENV['ADMIN_EMAIL'].present?
        LegalComplianceMailer.ai_triggered_check(result, triggering_errors).deliver_now
        Rails.logger.info "📧 AI 검증 결과 이메일 발송 완료"
      end

      result
    rescue StandardError => e
      Rails.logger.error "❌ AI 검증 중 오류: #{e.message}"

      if ENV['ADMIN_EMAIL'].present?
        LegalComplianceMailer.error_alert("AI 검증 오류: #{e.message}").deliver_now
      end

      { error: e.message }
    end
  end

end
