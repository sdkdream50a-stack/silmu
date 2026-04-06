# whenever 스케줄 설정 — cron 작업 관리
# 배포 후 서버에서 `whenever --update-crontab` 실행 필요

set :output, "/var/log/silmu/cron.log"
set :environment, :production

# ==========================================
# DB 백업 — 매일 새벽 2시 (KST)
# UTC 기준 17:00 (KST 02:00 = UTC 17:00 전날)
# ==========================================
every 1.day, at: "5:00 pm" do
  command "pg_dump $DATABASE_URL -Fc -f /var/backups/silmu/silmu_$(date +\\%Y\\%m\\%d).dump && find /var/backups/silmu -name 'silmu_*.dump' -mtime +30 -delete"
end

# ==========================================
# SEO 주간 리포트 — 매주 월요일 오전 9시 (KST)
# UTC 기준 일요일 00:00
# ==========================================
every :sunday, at: "12:00 am" do
  runner "SeoMailer.weekly_report(nil).deliver_now rescue nil"
end

# ==========================================
# 캐시 워밍 — 매일 오전 6시 (KST)
# UTC 기준 21:00 전날
# ==========================================
every 1.day, at: "9:00 pm" do
  runner "Topic.published.limit(20).each { |t| t.update_fragment_version rescue nil }"
end
