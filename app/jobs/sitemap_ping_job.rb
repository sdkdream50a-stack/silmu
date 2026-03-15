# Created: 2026-02-16 00:20
class SitemapPingJob < ApplicationJob
  queue_as :default

  HOST = "silmu.kr"
  INDEXNOW_KEY = "5ae9664d75415a43ef8341b00b97a941"
  INDEXNOW_KEY_LOCATION = "https://#{HOST}/#{INDEXNOW_KEY}.txt"

  # IndexNow 지원 검색엔진 (Bing, Naver, Yandex, Seznam 등)
  INDEXNOW_ENGINES = %w[
    api.indexnow.org
    www.bing.com
    searchadvisor.naver.com
    yandex.com
  ].freeze

  # urls: nil이면 최근 변경분 전체 수집, Array이면 해당 URL만 즉시 제출
  def perform(urls = nil)
    require "net/http"

    urls = urls ? Array(urls) : collect_urls
    Rails.logger.info "[SitemapPing] #{urls.size}개 URL 제출 시작"

    # Bing 권장: 배치 모드 대신 URL별 개별 제출
    INDEXNOW_ENGINES.each do |engine|
      urls.each do |url|
        status = submit_indexnow(engine, url)
        Rails.logger.info "[SitemapPing] #{engine} #{url}: #{status}"
      end
    end
  end

  private

  def collect_urls
    urls = ["https://#{HOST}/", "https://#{HOST}/sitemap.xml"]

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

  def submit_indexnow(engine, url)
    uri = URI("https://#{engine}/indexnow")
    uri.query = URI.encode_www_form(
      url: url,
      key: INDEXNOW_KEY
    )

    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    response.code.to_i < 400 ? :ok : :"error_#{response.code}"
  rescue => e
    Rails.logger.error "[SitemapPing] #{engine} 실패: #{e.message}"
    :error
  end
end
