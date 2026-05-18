# Google Sitemap Ping — 2024년 폐지됨
# 대안: Google Search Console API (서비스 계정) 또는 IndexNow (Bing/Naver/Yandex만)
#
# 2026-05-18 무한 루프 사건:
#   기존: GoogleSitemapPingJob → SitemapPingJob.perform_later 호출
#   문제: SitemapPingJob도 마지막에 GoogleSitemapPingJob.perform_later 호출 → 양방향 무한 루프
#   증상: 24h SitemapPingJob 76만 건 enqueue (정상 시간당 수십 건)
#   조치: GoogleSitemapPingJob를 no-op으로 변경. IndexNow 보충은 SitemapPingJob이 이미 수행
class GoogleSitemapPingJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[SitemapPing] Google Ping API 폐지 — no-op (IndexNow는 SitemapPingJob이 수행)"
    # 의도적 no-op. SitemapPingJob을 호출하지 않음 (재귀 차단)
  end
end
