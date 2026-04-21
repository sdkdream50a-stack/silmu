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
    Rails.logger.info "[SitemapPing] #{urls.size}개 URL 제출 시작 (#{INDEXNOW_ENGINES.size}개 엔진 + Google 병렬)"

    INDEXNOW_ENGINES.each do |engine|
      SitemapPingEngineJob.perform_later(engine, urls)
    end

    # Google은 IndexNow 미지원 → Sitemap Ping API 사용
    GoogleSitemapPingJob.perform_later
  end

  private

  def collect_urls
    # IndexNow는 변경된 콘텐츠 URL만 받음. sitemap.xml은 Google Sitemap Ping API에서 별도 처리.
    urls = [
      "https://#{HOST}/",
      "https://#{EXAM_HOST}/"
    ]

    # 최근 7일간 업데이트된 토픽
    Topic.published.where("updated_at > ?", 7.days.ago).find_each do |topic|
      urls << "https://#{HOST}/topics/#{topic.slug}"
    end

    # 최근 7일간 업데이트된 감사사례
    AuditCase.published.where("updated_at > ?", 7.days.ago).find_each do |ac|
      urls << "https://#{HOST}/audit-cases/#{ac.slug}"
    end

    # 최근 7일간 업데이트된 가이드
    Guide.published.where("updated_at > ?", 7.days.ago).find_each do |guide|
      urls << "https://#{HOST}/guides/#{guide.slug}"
    end

    urls.uniq
  end
end
