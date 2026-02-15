# Created: 2026-02-16 00:20
class SitemapPingJob < ApplicationJob
  queue_as :default

  SITEMAP_URL = "https://silmu.kr/sitemap.xml"

  PING_ENDPOINTS = {
    "Google" => "https://www.google.com/ping?sitemap=#{SITEMAP_URL}",
    "Bing (IndexNow)" => "https://www.bing.com/ping?sitemap=#{SITEMAP_URL}",
    "Naver" => "https://searchadvisor.naver.com/indexnow?url=#{SITEMAP_URL}"
  }.freeze

  def perform
    require "net/http"

    results = PING_ENDPOINTS.map do |engine, url|
      status = ping(url)
      Rails.logger.info "[SitemapPing] #{engine}: #{status}"
      { engine: engine, status: status }
    end

    Rails.logger.info "[SitemapPing] 완료 - 성공: #{results.count { |r| r[:status] == :ok }}/#{results.size}"
  end

  private

  def ping(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    response.code.to_i < 400 ? :ok : :"error_#{response.code}"
  rescue => e
    Rails.logger.error "[SitemapPing] 실패: #{e.message}"
    :error
  end
end
