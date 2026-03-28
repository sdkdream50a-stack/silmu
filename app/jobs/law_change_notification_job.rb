# 법령 개정 알림 Job
# - LawSyncJob 완료 후 변경 감지된 법령에 대해 구독자에게 이메일 발송
class LawChangeNotificationJob < ApplicationJob
  queue_as :default

  def perform(changed_law_names)
    return if changed_law_names.blank?

    changed_law_names.each do |law_name|
      # 해당 법령과 연관된 토픽 슬러그 찾기 (LawContentFetcher::TOPIC_LAW_MAP 역매핑)
      related_slugs = topic_slugs_for_law(law_name)
      next if related_slugs.empty?

      related_slugs.each do |slug|
        subs = LawChangeSubscription.where(topic_slug: slug, active: true)
        subs.find_each do |sub|
          LawSubscriptionMailer.law_changed(sub, law_name).deliver_later
        end
        Rails.logger.info "[LawChangeNotificationJob] #{slug} 구독자 #{subs.count}명에게 알림 (#{law_name})"
      end
    end
  end

  private

  # TOPIC_LAW_MAP은 slug => [법령명 배열] 구조 — 역으로 법령명 => [slug배열] 매핑
  def topic_slugs_for_law(law_name)
    LawContentFetcher::TOPIC_LAW_MAP.filter_map do |slug, laws|
      slug if Array(laws).any? { |l| l.include?(law_name) || law_name.include?(l) }
    end
  rescue
    []
  end
end
