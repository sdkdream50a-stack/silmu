# frozen_string_literal: true

# AEO 인용 모니터링 Job (2026-05-17 신설, 권위자 패널 E 권고)
#
# silmu만의 차별점 측정: Claude·Perplexity 같은 답변엔진(LLM)이 공무원 실무
# 핵심 쿼리에 silmu.kr을 인용하는지 주1회 측정. 결과 추이를 Sentry/로그로 추적.
#
# 배경: silmu.kr이 S+++ Apex SEO 수준(110/100)이지만 실측 AEO 인용 데이터 0건.
# 측정 없이는 SEO 작업의 효과를 알 수 없음. AEO 인용은 GSC와 별개 지표.
#
# V1 (이 commit): web_search 도구 없이 Claude의 답변 본문에 silmu.kr 인용 여부만 측정.
#                 운영 비용 최소화. 측정 베이스라인 확보 목적.
# V2 (차후): web_search 도구 추가로 검색 결과에서 silmu.kr 도메인 빈도 측정.
class AeoCitationMonitorJob < ApplicationJob
  queue_as :default

  # silmu 핵심 도메인을 대표하는 검색 쿼리 (사용자가 LLM에 던질 법한 자연어)
  QUERIES = [
    "공무원 수의계약 한도 2026년 기준",
    "지방계약법 시행령 분할계약 금지 조문",
    "공무원 봉급 실수령액 계산 방법",
    "공무원 시간외수당 산정 공식",
    "공무원 출장 숙박비 상한액 서울 광역시",
    "공무원 가족수당 자녀 첫째 둘째 셋째",
    "공무원 직급보조비 1급 9급 별표",
    "공무원 연가보상비 산식 86%",
    "지방계약법 낙찰하한율 시설공사",
    "공무원 명예퇴직금 vs 정년퇴직 손익 비교"
  ].freeze

  MODEL = "claude-haiku-4-5-20251001"
  MAX_TOKENS = 600
  SILMU_DOMAIN_PATTERN = /silmu\.kr|실무\.kr|실무kr/i

  def perform
    return Rails.logger.warn("[AeoCitationMonitorJob] ANTHROPIC_API_KEY 미설정") if api_key.blank?

    Rails.logger.info "[AeoCitationMonitorJob] AEO 인용 모니터링 시작 (#{QUERIES.size}건 쿼리)"

    client = Anthropic::Client.new
    results = QUERIES.map { |q| measure(client, q) }

    total = results.size
    cited = results.count { |r| r[:cited] }
    citation_rate = (cited.to_f / total * 100).round(1)

    msg = "[AeoCitationMonitorJob] 측정 완료 — silmu 인용 #{cited}/#{total} (#{citation_rate}%)"
    Rails.logger.info msg

    notify_summary(cited: cited, total: total, citation_rate: citation_rate, results: results)
  end

  private

  def api_key
    @api_key ||= ENV["ANTHROPIC_API_KEY"]
  end

  def measure(client, query)
    response = client.messages(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      messages: [ { role: "user", content: query } ]
    )
    text = response.content.first&.text.to_s
    cited = text.match?(SILMU_DOMAIN_PATTERN)
    Rails.logger.info "[AeoCitationMonitorJob] #{cited ? "✓" : "✗"} #{query}"
    { query: query, cited: cited, response_preview: text.first(160) }
  rescue => e
    Rails.logger.error "[AeoCitationMonitorJob] #{query}: #{e.class} #{e.message}"
    { query: query, cited: false, error: e.message }
  end

  def notify_summary(cited:, total:, citation_rate:, results:)
    summary = "AEO 인용 측정: silmu #{cited}/#{total} (#{citation_rate}%)"

    if defined?(Sentry)
      level = citation_rate.zero? ? :warning : :info
      Sentry.capture_message("[AeoCitationMonitorJob] #{summary}", level: level, extra: {
        citation_rate: citation_rate,
        cited_count: cited,
        total_count: total,
        cited_queries: results.select { |r| r[:cited] }.map { |r| r[:query] },
        uncited_queries: results.reject { |r| r[:cited] }.map { |r| r[:query] }
      })
    end
  end
end
