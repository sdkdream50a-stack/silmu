namespace :seo do
  desc "Weekly SEO health check and report"
  task weekly_report: :environment do
    puts "=" * 60
    puts "SEO 주간 리포트 (#{Date.today})"
    puts "=" * 60

    report = SeoMonitor.generate_weekly_report

    # 콘솔 출력
    puts "\n📊 콘텐츠 현황"
    puts "-" * 60
    puts "토픽: #{report[:content][:topics_count]}개"
    puts "감사사례: #{report[:content][:audit_cases_count]}개"
    puts "도구: #{report[:content][:tools_count]}개"

    puts "\n📈 트래픽 (최근 7일)"
    puts "-" * 60
    puts "토픽 조회수 Top 5:"
    report[:traffic][:top_topics].each_with_index do |topic, i|
      puts "  #{i+1}. #{topic[:name]} (#{topic[:views]}회)"
    end

    puts "\n🔍 SEO 상태"
    puts "-" * 60
    puts "Sitemap 페이지 수: #{report[:seo][:sitemap_urls]}개"
    puts "평균 메타 설명 길이: #{report[:seo][:avg_meta_length]}자"

    puts "\n⚠️  주의사항"
    puts "-" * 60
    report[:warnings].each do |warning|
      puts "- #{warning}"
    end

    # 이메일 발송
    if ENV['ADMIN_EMAIL'].present?
      SeoMailer.weekly_report(report).deliver_later
      puts "\n✅ 리포트 이메일 발송: #{ENV['ADMIN_EMAIL']}"
    end

    puts "\n" + "=" * 60
  end

  desc "Monthly PageSpeed and Core Web Vitals check"
  task monthly_performance: :environment do
    puts "=" * 60
    puts "PageSpeed 월간 리포트 (#{Date.today})"
    puts "=" * 60

    report = SeoMonitor.check_page_speed

    puts "\n⚡ 성능 지표"
    puts "-" * 60
    puts "Performance Score: #{report[:performance_score]}/100"
    puts "First Contentful Paint: #{report[:fcp]}s"
    puts "Largest Contentful Paint: #{report[:lcp]}s"
    puts "Total Blocking Time: #{report[:tbt]}ms"
    puts "Cumulative Layout Shift: #{report[:cls]}"

    puts "\n💡 개선 제안"
    puts "-" * 60
    report[:opportunities].each do |opp|
      puts "- #{opp}"
    end

    # 이메일 발송
    if ENV['ADMIN_EMAIL'].present?
      SeoMailer.monthly_performance(report).deliver_later
      puts "\n✅ 리포트 이메일 발송: #{ENV['ADMIN_EMAIL']}"
    end

    puts "\n" + "=" * 60
  end

  desc "Check for broken links"
  task check_links: :environment do
    puts "=" * 60
    puts "링크 체크 (#{Date.today})"
    puts "=" * 60

    broken_links = SeoMonitor.check_broken_links

    if broken_links.empty?
      puts "\n✅ 모든 링크가 정상입니다!"
    else
      puts "\n❌ 깨진 링크 발견: #{broken_links.count}개"
      puts "-" * 60
      broken_links.each do |link|
        puts "#{link[:url]} (#{link[:status]}) - #{link[:page]}"
      end

      # 이메일 알림
      if ENV['ADMIN_EMAIL'].present?
        SeoMailer.broken_links_alert(broken_links).deliver_later
      end
    end

    puts "\n" + "=" * 60
  end
end
