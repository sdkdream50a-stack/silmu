# 매일 silmu:seo_health rake를 실행해 SEO 지표를 log/seo_health.jsonl에 영구 기록.
# 운영 cron: recurring.yml의 daily_seo_health (매일 07시 KST)
class SeoHealthJob < ApplicationJob
  queue_as :default

  def perform
    require "rake"
    Rails.application.load_tasks unless Rake::Task.task_defined?("silmu:seo_health")
    Rake::Task["silmu:seo_health"].reenable
    Rake::Task["silmu:seo_health"].invoke
  end
end
