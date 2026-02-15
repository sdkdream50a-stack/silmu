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

  def perform
    require "net/http"
    require "json"

    urls = collect_urls
    Rails.logger.info "[SitemapPing] #{urls.size}개 URL 제출 시작"

    INDEXNOW_ENGINES.each do |engine|
      status = submit_indexnow(engine, urls)
      Rails.logger.info "[SitemapPing] #{engine}: #{status}"
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

    urls.uniq
  end

  def submit_indexnow(engine, urls)
    uri = URI("https://#{engine}/indexnow")

    body = {
      host: HOST,
      key: INDEXNOW_KEY,
      keyLocation: INDEXNOW_KEY_LOCATION,
      urlList: urls
    }.to_json

    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = body

    response = http.request(request)
    response.code.to_i < 400 ? :ok : :"error_#{response.code}"
  rescue => e
    Rails.logger.error "[SitemapPing] #{engine} 실패: #{e.message}"
    :error
  end
end
