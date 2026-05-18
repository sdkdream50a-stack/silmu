# frozen_string_literal: true
# silmu SEO 자동 진단 — GSC API 없이 외부 측정 가능한 지표를 매일 자동 기록
# 운영 방식: recurring.yml에 등록되어 매일 자정 실행
# 출력: log/seo_health.jsonl (JSON Lines 형식, 일별 1줄)
#
# 측정 항목:
# 1. sitemap.xml URL 개수 + HTTP 상태
# 2. audit_cases / topics / guides thin content 비율
# 3. 최근 24h IndexNow ping 송신 카운트 (SolidQueue 로그 기반)
# 4. 핵심 페이지(홈·sitemap·robots) HTTP 응답
#
# GSC API 연동(색인 수·노출수)은 OAuth 설정 후 별도 task로 추가 예정.

require "net/http"
require "uri"
require "json"

namespace :silmu do
  desc "silmu SEO 일일 자동 진단 — sitemap·thin content·IndexNow 송신 지표 측정"
  task seo_health: :environment do
    timestamp = Time.zone.now
    results = { timestamp: timestamp.iso8601 }

    # 1. sitemap.xml — URL 개수 + HTTP 상태 + 응답 시간
    sitemap_uri = URI("https://silmu.kr/sitemap.xml")
    start = Time.now
    begin
      sitemap_resp = Net::HTTP.get_response(sitemap_uri)
      sitemap_urls = sitemap_resp.body.to_s.scan(%r{<loc>([^<]+)</loc>}).flatten
      results[:sitemap] = {
        http_status: sitemap_resp.code.to_i,
        url_count: sitemap_urls.size,
        elapsed_ms: ((Time.now - start) * 1000).round
      }
    rescue StandardError => e
      results[:sitemap] = { error: e.class.name, message: e.message[0, 200] }
    end

    # 2. thin content 비율
    [ AuditCase, Topic, Guide ].each do |model|
      table = model.table_name
      content_cols = case model.name
                     when "AuditCase" then %w[detail lesson]
                     when "Topic" then %w[law_content decree_content rule_content commentary]
                     when "Guide" then %w[description sections]
                     end
      content_expr = content_cols.map { |c| "char_length(coalesce(#{c}::text,''))" }.join(" + ")
      total = model.public_send(:published).count
      thin = model.public_send(:published).where("#{content_expr} < 1500").count
      results[table.to_sym] = { total:, thin:, ratio: (total.positive? ? (thin * 100.0 / total).round(1) : 0) }
    end

    # 3. 최근 24h IndexNow 송신 — SolidQueue 잡 카운트
    # SolidQueue는 별도 DB connection 사용 가능 → ActiveRecord::Base 테이블 검사 대신 직접 시도
    if defined?(SolidQueue::Job)
      begin
        since = 24.hours.ago
        results[:indexnow_24h] = {
          sitemap_ping_jobs: SolidQueue::Job.where(class_name: "SitemapPingJob").where("created_at > ?", since).count,
          engine_ping_jobs: SolidQueue::Job.where(class_name: "SitemapPingEngineJob").where("created_at > ?", since).count,
          google_ping_jobs: SolidQueue::Job.where(class_name: "GoogleSitemapPingJob").where("created_at > ?", since).count
        }
      rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
        results[:indexnow_24h] = { skipped: "SolidQueue DB 미연결: #{e.class.name}" }
      end
    end

    # 4. 핵심 페이지 HTTP 검증
    core_pages = %w[/ /robots.txt /sitemap.xml /audit-cases /topics /guides]
    results[:core_pages] = core_pages.map do |path|
      uri = URI("https://silmu.kr#{path}")
      resp = Net::HTTP.get_response(uri)
      { path:, http_status: resp.code.to_i }
    rescue StandardError => e
      { path:, error: e.class.name }
    end

    # 출력 + 영구 기록
    puts results.to_json
    log_path = Rails.root.join("log/seo_health.jsonl")
    File.open(log_path, "a") { |f| f.puts(results.to_json) }
    puts "[seo_health] #{log_path} 기록 완료"
  end
end
