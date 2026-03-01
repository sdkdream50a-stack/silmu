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
    "소득세법",
  ].freeze

  def perform
    Rails.logger.info "[LawSyncJob] 법령 메타데이터 동기화 시작 (#{TARGET_LAWS.size}건)"
    fetcher = LawContentFetcher.new
    success_count = 0

    TARGET_LAWS.each do |law_name|
      # 캐시 무효화 후 새로 조회
      cache_key = "law_api/v2/meta/#{Digest::MD5.hexdigest(law_name)}"
      Rails.cache.delete(cache_key)

      meta = fetcher.fetch_law_meta(law_name)

      if meta.present?
        Law.upsert_from_api!(meta)
        success_count += 1
        Rails.logger.info "[LawSyncJob] ✓ #{meta[:name]} (#{meta[:effective_display]})"
      else
        Rails.logger.warn "[LawSyncJob] ✗ 조회 실패: #{law_name}"
      end
    rescue => e
      Rails.logger.error "[LawSyncJob] 오류 (#{law_name}): #{e.class} #{e.message}"
    end

    # 토픽 법령 참조 캐시도 초기화 (다음 요청에서 새 MST로 재조회)
    # Solid Cache는 delete_matched 미지원 — 패턴 대신 버전 기반 무효화
    Rails.cache.increment("law_refs_version")

    Rails.logger.info "[LawSyncJob] 완료 (#{success_count}/#{TARGET_LAWS.size})"
  end
end
