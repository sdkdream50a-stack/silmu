# Google Sitemap Ping — 2024년 폐지됨
# 대안: Google Search Console API (서비스 계정) 또는 IndexNow (Bing/Naver/Yandex만)
# 이 Job은 IndexNow 보충 ping으로 전환 — Google은 GSC에서 자동 크롤링에 의존
class GoogleSitemapPingJob < ApplicationJob
  queue_as :default

  # IndexNow로 최근 변경 URL 제출 (Google Ping API 폐지 대안)
  def perform
    Rails.logger.info "[SitemapPing] Google Ping API 폐지 — IndexNow 보충 실행"
    SitemapPingJob.perform_later
  end
end
