# whenever를 사용한 SEO 모니터링 자동화
# 배포: whenever --update-crontab

# 환경 설정
set :output, "log/cron.log"
set :environment, "production"

# 매주 월요일 오전 9시 - SEO 주간 리포트
every :monday, at: '9:00 am' do
  rake "seo:weekly_report"
end

# 매월 1일 오전 10시 - PageSpeed 월간 리포트
every '0 10 1 * *' do
  rake "seo:monthly_performance"
end

# 매주 수요일 오후 3시 - 깨진 링크 체크
every :wednesday, at: '3:00 pm' do
  rake "seo:check_links"
end

# 사용 예시:
# 로컬에서 테스트: bundle exec rake seo:weekly_report
# Cron 업데이트: whenever --update-crontab
# Cron 확인: crontab -l
# Cron 삭제: whenever --clear-crontab
