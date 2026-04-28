# frozen_string_literal: true

# 법제처 API 법령 메타데이터 주간 동기화 Job
# - 주요 법령의 MST·시행일·소관부처를 DB(Law 테이블)에 저장
# - Solid Cache의 7일 TTL과 맞춰 매주 갱신
class LawSyncJob < ApplicationJob
  queue_as :default

  TARGET_LAWS = [
    "지방자치단체를 당사자로 하는 계약에 관한 법률",
    "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
    "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙",
    "국가를 당사자로 하는 계약에 관한 법률",
    "국가를 당사자로 하는 계약에 관한 법률 시행령",
    "공무원 여비 규정",
    "지방재정법",
    "지방재정법 시행령",
    "소득세법"
  ].freeze

  def perform
    Rails.logger.info "[LawSyncJob] 법령 메타데이터 동기화 시작 (#{TARGET_LAWS.size}건)"
    fetcher = LawContentFetcher.new
    success_count = 0
    changed_law_names = []

    TARGET_LAWS.each do |law_name|
      # 동기화 전 기존 시행일 저장 (변경 감지용)
      existing = Law.find_by(name: law_name)
      prev_effective_date = existing&.effective_date

      # 캐시 무효화 후 새로 조회
      cache_key = "law_api/v2/meta/#{Digest::MD5.hexdigest(law_name)}"
      Rails.cache.delete(cache_key)

      meta = fetcher.fetch_law_meta(law_name)

      if meta.present?
        Law.upsert_from_api!(meta)
        success_count += 1
        Rails.logger.info "[LawSyncJob] ✓ #{meta[:name]} (#{meta[:effective_display]})"

        # 시행일 변경 감지 → 개정 알림 대상에 추가
        new_effective_date = meta[:effective_date]
        if prev_effective_date.present? && new_effective_date.present? &&
           new_effective_date.to_s != prev_effective_date.to_s
          changed_law_names << law_name
          Rails.logger.info "[LawSyncJob] 개정 감지: #{law_name} (#{prev_effective_date} → #{new_effective_date})"
        end
      else
        Rails.logger.warn "[LawSyncJob] ✗ 조회 실패: #{law_name}"
      end
    rescue => e
      Rails.logger.error "[LawSyncJob] 오류 (#{law_name}): #{e.class} #{e.message}"
    end

    # 토픽 법령 참조 캐시 명시적 삭제 (law_refs_version 증가와 함께 실제 키도 제거)
    # Solid Cache는 delete_matched 미지원 — 토픽 slug별로 직접 삭제
    LawContentFetcher::TOPIC_LAW_MAP.each_key do |slug|
      Rails.cache.delete("topic_law_refs/v1/#{slug}")
      Rails.cache.delete("law_ref_warming/#{slug}")
    end
    Rails.cache.increment("law_refs_version")

    # 개정된 법령이 있으면 구독자 알림 Job 실행
    LawChangeNotificationJob.perform_later(changed_law_names) if changed_law_names.any?

    # Sprint #4-B — 영향 토픽 자동 flag (Westlaw 권위자: 콘텐츠 신선도 자동화)
    flag_affected_topics(changed_law_names) if changed_law_names.any?

    Rails.logger.info "[LawSyncJob] 완료 (#{success_count}/#{TARGET_LAWS.size}, 개정 #{changed_law_names.size}건)"
  end

  private

  # 변경된 법령 → TOPIC_LAW_MAP reverse-lookup → 영향 토픽 needs_review=true
  def flag_affected_topics(changed_laws)
    affected_slugs = []
    LawContentFetcher::TOPIC_LAW_MAP.each do |slug, mapping|
      next if mapping.blank?
      law_names = [ mapping[:law], mapping[:decree], mapping[:rule] ].compact
      affected_slugs << slug if law_names.any? { |ln| changed_laws.include?(ln) }
    end

    return if affected_slugs.empty?

    flagged = Topic.where(slug: affected_slugs).update_all(
      needs_review: true,
      review_reason: "법령 개정 감지: #{changed_laws.first(3).join(', ')}#{changed_laws.size > 3 ? ' 외' : ''}",
      review_flagged_at: Time.current
    )

    Rails.logger.info "[LawSyncJob] needs_review flag #{flagged}건 (#{affected_slugs.first(5).join(', ')}#{'...' if affected_slugs.size > 5})"
  end
end
