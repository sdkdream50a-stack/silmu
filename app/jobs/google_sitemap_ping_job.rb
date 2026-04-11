# Google Sitemap Ping API
# Google은 IndexNow를 지원하지 않으므로 별도 ping 엔드포인트 사용
# https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap#addsitemap
class GoogleSitemapPingJob < ApplicationJob
  queue_as :default

  def perform
    require "net/http"

    SitemapPingJob::SITEMAP_URLS.each do |sitemap_url|
      ping_google(sitemap_url)
    end
  end

  private

  def ping_google(sitemap_url)
    uri = URI("https://www.google.com/ping")
    uri.query = URI.encode_www_form(sitemap: sitemap_url)
    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    Rails.logger.info "[GooglePing] #{sitemap_url}: #{response.code}"
  rescue => e
    Rails.logger.error "[GooglePing] #{sitemap_url} 실패: #{e.message}"
  end
end
