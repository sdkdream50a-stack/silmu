class SitemapPingEngineJob < ApplicationJob
  queue_as :default

  def perform(engine, urls)
    require "net/http"
    urls.each do |url|
      status = submit_indexnow(engine, url)
      Rails.logger.info "[SitemapPing] #{engine} #{url}: #{status}"
    end
  end

  private

  def submit_indexnow(engine, url)
    key = Rails.application.credentials.dig(:indexnow, :key) || SitemapPingJob::INDEXNOW_KEY
    uri = URI("https://#{engine}/indexnow")
    uri.query = URI.encode_www_form(url: url, key: key)
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
