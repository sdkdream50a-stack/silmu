# frozen_string_literal: true

# 인사혁신처 보도자료 RSS 모니터링 Job (2026-05-17 신설)
#
# 매일 인사혁신처 보도자료 RSS를 폴링하여 봉급·수당·여비·보수지침 등 매년 갱신
# 단가에 영향을 미치는 키워드가 포함된 신규 보도자료를 감지하면 운영자에게 알림.
#
# 배경: 「공무원보수규정」 별표 3 봉급표·「공무원수당 등에 관한 규정」 별표·
# 「공무원보수 등의 업무지침」 별표는 매년 1~2월 일괄 개정. silmu 콘텐츠가
# 따라가지 못해 발생한 13건 정정 사례(2026-05-17) 재발 방지.
#
# 권위자 패널 C 권고: "회고적 lint가 아닌 신규 유형 발견 메커니즘 필요"
#
# 알림 채널: Sentry capture_message (severity: warning) → 운영자 dashboard에 노출
class MpmRssMonitorJob < ApplicationJob
  queue_as :default

  RSS_URL = "https://www.mpm.go.kr/board/rss.do?boardId=bbs_0000000000000029&mode=fed&proc=rss"

  # 매년 갱신 단가 관련 키워드 (silmu 도구·시드 영향)
  YEARLY_CHANGE_KEYWORDS = %w[
    봉급 봉급표 호봉
    수당 가족수당 명절휴가비 직급보조비 시간외 성과상여금 정근수당
    여비 출장 숙박비 일비 식비
    보수지침 보수업무지침 보수규정
    연금 퇴직수당 기여금
    건강보험 장기요양 4대보험
  ].freeze

  CACHE_KEY = "mpm_rss/last_seen_pubdate"
  CACHE_TTL = 30.days
  HTTP_TIMEOUT = 10

  def perform
    Rails.logger.info "[MpmRssMonitorJob] 인사혁신처 RSS 폴링 시작"

    xml = fetch_rss
    return Rails.logger.warn("[MpmRssMonitorJob] RSS 응답 없음") if xml.blank?

    items = parse_items(xml)
    return Rails.logger.warn("[MpmRssMonitorJob] RSS 항목 0건") if items.empty?

    last_seen = Rails.cache.read(CACHE_KEY) # ISO8601 String 또는 nil
    last_seen_time = last_seen ? Time.zone.parse(last_seen) : 7.days.ago

    new_items = items.select { |i| i[:pub_date] && i[:pub_date] > last_seen_time }
    matched = new_items.select { |i| matches_yearly_change?(i) }

    if matched.any?
      matched.each { |item| notify_match(item) }
      Rails.logger.warn "[MpmRssMonitorJob] 매년 갱신 키워드 매칭 #{matched.size}건"
    else
      Rails.logger.info "[MpmRssMonitorJob] 매칭 없음 (신규 #{new_items.size}건)"
    end

    # 가장 최근 pub_date 캐싱 (다음 폴링 baseline)
    latest = items.map { |i| i[:pub_date] }.compact.max
    Rails.cache.write(CACHE_KEY, latest.iso8601, expires_in: CACHE_TTL) if latest
  end

  private

  def fetch_rss
    require "net/http"
    uri = URI(RSS_URL)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: HTTP_TIMEOUT) do |http|
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = "silmu-bot/1.0 (https://silmu.kr)"
      res = http.request(req)
      res.is_a?(Net::HTTPSuccess) ? res.body : nil
    end
  rescue => e
    Rails.logger.error "[MpmRssMonitorJob] RSS fetch 실패: #{e.class} #{e.message}"
    nil
  end

  def parse_items(xml)
    doc = Nokogiri::XML(xml)
    doc.css("item").map do |node|
      {
        title: node.css("title").text.strip,
        link: node.css("link").text.strip,
        description: node.css("description").text.strip,
        pub_date: parse_pub_date(node.css("pubDate").text)
      }
    end
  rescue => e
    Rails.logger.error "[MpmRssMonitorJob] RSS 파싱 실패: #{e.class} #{e.message}"
    []
  end

  def parse_pub_date(str)
    return nil if str.blank?
    Time.zone.parse(str)
  rescue
    nil
  end

  def matches_yearly_change?(item)
    haystack = "#{item[:title]} #{item[:description]}"
    YEARLY_CHANGE_KEYWORDS.any? { |kw| haystack.include?(kw) }
  end

  def notify_match(item)
    msg = "[MpmRssMonitorJob] 매년 갱신 영향 보도자료 감지: #{item[:title]}"
    Rails.logger.warn "#{msg} (#{item[:link]})"

    if defined?(Sentry)
      Sentry.capture_message(msg, level: :warning, extra: {
        title: item[:title],
        link: item[:link],
        pub_date: item[:pub_date]&.iso8601,
        matched_keywords: YEARLY_CHANGE_KEYWORDS.select { |k| item[:title].include?(k) || item[:description].include?(k) }
      })
    end
  end
end
