class ExamReminderJob < ApplicationJob
  queue_as :default

  def perform
    # 3일 이상 미업데이트된 진도 기록이 있는 유저 (최대 100명/회)
    threshold = 3.days.ago
    ExamProgress.where("updated_at < ?", threshold)
                .includes(:user)
                .limit(100)
                .each do |progress|
      user = progress.user
      next unless user&.email.present?

      # 이미 오늘 발송했으면 스킵 (simple rate limiting)
      cache_key = "exam_reminder_sent_#{user.id}_#{Time.zone.today}"
      next if Rails.cache.exist?(cache_key)

      ExamReminderMailer.reminder(user, progress).deliver_later
      Rails.cache.write(cache_key, true, expires_in: 25.hours)

      Rails.logger.info "[ExamReminderJob] 리마인더 발송: user=#{user.id}"
    rescue => e
      Rails.logger.error "[ExamReminderJob] 오류: user=#{user&.id} #{e.message}"
    end
  end
end
