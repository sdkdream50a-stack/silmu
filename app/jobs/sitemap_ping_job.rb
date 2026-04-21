# Created: 2026-02-16 00:20
class SitemapPingJob < ApplicationJob
  queue_as :default

  HOST = "silmu.kr"
  EXAM_HOST = "exam.silmu.kr"
  INDEXNOW_KEY = Rails.application.credentials.dig(:indexnow, :key) || "5ae9664d75415a43ef8341b00b97a941"
  INDEXNOW_KEY_LOCATION = "https://#{HOST}/#{INDEXNOW_KEY}.txt"

  # IndexNow 공식 프록시 — api.indexnow.org 하나가 Bing/Naver/Yandex/Seznam에 자동 전파.
  # 개별 엔진에 중복 제출하면 일일 quota(host당 10,000 URL)를 빠르게 소진하므로 단일 엔진 사용.
  INDEXNOW_ENGINES = %w[api.indexnow.org].freeze

  SITEMAP_URLS = [
    "https://#{HOST}/sitemap.xml",
    "https://#{EXAM_HOST}/sitemap.xml"
  ].freeze

  # urls: nil이면 최근 변경분 전체 수집, Array이면 해당 URL만 즉시 제출
  def perform(urls = nil)
    urls = urls ? Array(urls) : collect_urls
    if urls.empty?
      Rails.logger.info "[SitemapPing] 최근 변경 URL 없음 — IndexNow 제출 건너뜀"
    else
      Rails.logger.info "[SitemapPing] #{urls.size}개 URL 제출 시작 (#{INDEXNOW_ENGINES.size}개 엔진)"
      INDEXNOW_ENGINES.each do |engine|
        SitemapPingEngineJob.perform_later(engine, urls)
      end
    end

    # Google은 IndexNow 미지원 → Sitemap Ping API 사용 (변경 없어도 sitemap ping은 저비용)
    GoogleSitemapPingJob.perform_later
  end

  private

  # daily cron 빈도에 맞춰 창은 `1.day + 2h buffer = 26h`.
  # 기존 7일 창은 동일 URL을 7일 내내 반복 제출해 quota 낭비.
  WINDOW = 26.hours

  def collect_urls
    urls = []

    Topic.published.where("updated_at > ?", WINDOW.ago).find_each do |topic|
      urls << "https://#{HOST}/topics/#{topic.slug}"
    end

    AuditCase.published.where("updated_at > ?", WINDOW.ago).find_each do |ac|
      urls << "https://#{HOST}/audit-cases/#{ac.slug}"
    end

    Guide.published.where("updated_at > ?", WINDOW.ago).find_each do |guide|
      urls << "https://#{HOST}/guides/#{guide.slug}"
    end

    # 새 콘텐츠가 있을 때만 홈페이지 목록 함께 제출 (순서 변경 반영)
    urls.unshift("https://#{HOST}/") if urls.any?

    urls.uniq
  end
end
