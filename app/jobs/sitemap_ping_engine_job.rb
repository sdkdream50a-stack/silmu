class SitemapPingEngineJob < ApplicationJob
  queue_as :default

  # 429 Too Many Requests 때는 재시도 대기로 완화 (기본 discard 방지)
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

  def perform(engine, urls)
    require "net/http"
    require "json"

    # IndexNow 사양: 한 요청의 모든 URL은 동일 host여야 함.
    # 따라서 host별로 그룹핑해 엔진당 최대 2회(silmu.kr / exam.silmu.kr) POST.
    urls.group_by { |u| URI(u).host rescue nil }.compact.each do |host, host_urls|
      status = submit_indexnow(engine, host, host_urls)
      Rails.logger.info "[SitemapPing] #{engine} #{host} (#{host_urls.size} URLs): #{status}"
    end
  end

  private

  def submit_indexnow(engine, host, urls)
    key = Rails.application.credentials.dig(:indexnow, :key) || SitemapPingJob::INDEXNOW_KEY
    uri = URI("https://#{engine}/indexnow")

    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json; charset=utf-8")
    request.body = {
      host: host,
      key: key,
      keyLocation: "https://#{host}/#{key}.txt",
      urlList: urls
    }.to_json

    response = http.request(request)
    if response.code.to_i < 400
      :ok
    else
      # 4xx/5xx 시 응답 본문 앞부분을 로깅 (엔진별 페이로드 호환 디버깅)
      body_sample = response.body.to_s.byteslice(0, 200)
      Rails.logger.warn "[SitemapPing] #{engine} #{host} #{response.code}: #{body_sample}"
      :"error_#{response.code}"
    end
  rescue => e
    Rails.logger.error "[SitemapPing] #{engine} #{host} 실패: #{e.message}"
    :error
  end
end
