class SeoMailer < ApplicationMailer
  default from: 'seo-report@silmu.kr'

  def weekly_report(report)
    @report = report
    @date = Date.today

    mail(
      to: ENV['ADMIN_EMAIL'] || 'hello@silmu.kr',
      subject: "[실무.kr] SEO 주간 리포트 - #{@date}"
    )
  end

  def monthly_performance(report)
    @report = report
    @date = Date.today

    mail(
      to: ENV['ADMIN_EMAIL'] || 'hello@silmu.kr',
      subject: "[실무.kr] PageSpeed 월간 리포트 - #{@date}"
    )
  end

  def broken_links_alert(broken_links)
    @broken_links = broken_links
    @date = Date.today

    mail(
      to: ENV['ADMIN_EMAIL'] || 'hello@silmu.kr',
      subject: "[실무.kr] ⚠️ 깨진 링크 발견 - #{broken_links.count}개"
    )
  end
end
