class SeoReportJob < ApplicationJob
  queue_as :default

  def perform(report_type)
    case report_type
    when "weekly"
      generate_weekly_report
    when "monthly"
      generate_monthly_report
    when "links"
      check_broken_links
    else
      Rails.logger.error "Unknown SEO report type: #{report_type}"
    end
  end

  private

  def generate_weekly_report
    report = SeoMonitor.generate_weekly_report

    # 로그에 기록
    Rails.logger.info "=" * 60
    Rails.logger.info "SEO 주간 리포트 (#{Date.today})"
    Rails.logger.info "=" * 60
    Rails.logger.info "토픽: #{report[:content][:topics_count]}개"
    Rails.logger.info "감사사례: #{report[:content][:audit_cases_count]}개"
    Rails.logger.info "=" * 60

    # 이메일 발송
    if ENV['ADMIN_EMAIL'].present?
      SeoMailer.weekly_report(report).deliver_now
      Rails.logger.info "✅ 주간 리포트 이메일 발송 완료"
    end
  end

  def generate_monthly_report
    report = SeoMonitor.check_page_speed

    Rails.logger.info "=" * 60
    Rails.logger.info "PageSpeed 월간 리포트 (#{Date.today})"
    Rails.logger.info "Performance Score: #{report[:performance_score]}/100"
    Rails.logger.info "=" * 60

    # 이메일 발송
    if ENV['ADMIN_EMAIL'].present?
      SeoMailer.monthly_performance(report).deliver_now
      Rails.logger.info "✅ 월간 성능 리포트 이메일 발송 완료"
    end
  end

  def check_broken_links
    broken_links = SeoMonitor.check_broken_links

    if broken_links.empty?
      Rails.logger.info "✅ 모든 링크가 정상입니다!"
    else
      Rails.logger.warn "❌ 깨진 링크 발견: #{broken_links.count}개"

      # 이메일 알림
      if ENV['ADMIN_EMAIL'].present?
        SeoMailer.broken_links_alert(broken_links).deliver_now
        Rails.logger.info "✅ 깨진 링크 알림 이메일 발송 완료"
      end
    end
  end
end
