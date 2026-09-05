# frozen_string_literal: true

# P1.5 §22 — 신선도 점검 잡.
#
# 구 `LegalComplianceJob` 과의 결정적 차이:
#   구 잡: AI 출력으로 `topic.update!` 를 실행해 **게시 콘텐츠를 직접 수정**할 수 있었다.
#   이 잡: authority_* 테이블과 콘텐츠의 freshness_state 3개 컬럼만 쓴다. **본문을 만지지 않는다.**
#
# 요구 성질(§22): idempotent · bounded · rate-limited · observable · retry-safe · non-destructive
class AuthorityFreshnessCheckJob < ApplicationJob
  queue_as :default

  # bounded — 한 번 실행에서 검사할 문서 수 상한
  MAX_DOCUMENTS_PER_RUN = 20
  # rate-limited — 외부 기관 호출 간격
  REQUEST_INTERVAL_SECONDS = 1.0
  # §25 — 무한 retry 금지. 연속 실패가 쌓이면 그 소스는 건너뛴다.
  MAX_CONSECUTIVE_FAILURES = 5

  # retry-safe: 잡 전체를 재시도하지 않는다. 문서 단위로 실패를 흡수하고 다음 주기에 다시 본다.
  discard_on StandardError do |job, error|
    Rails.logger.error "[AuthorityFreshnessCheckJob] 처리 불가 오류: #{error.class} #{error.message}"
  end

  def perform(document_ids: nil, limit: MAX_DOCUMENTS_PER_RUN, dry_run: false)
    documents = target_documents(document_ids, limit)
    detector = Authority::ChangeDetector.new
    analyzer = Authority::ImpactAnalyzer.new
    report = { checked: 0, unchanged: 0, changed: 0, failed: 0, tasks_created: 0, skipped_failing: 0,
               alerts_sent: 0 }

    documents.each_with_index do |document, index|
      source = document.authority_source
      if source.failure_count >= MAX_CONSECUTIVE_FAILURES
        report[:skipped_failing] += 1
        Rails.logger.warn "[AuthorityFreshness] 연속 실패 #{source.failure_count}회 — 건너뜀: #{source.key}"
        # degraded 상태에서도 아직 안 알렸다면 알린다. 여기서 막히면 사람이 알 경로가 없다.
        report[:alerts_sent] += 1 if alert_operator(source)
        next
      end

      sleep(REQUEST_INTERVAL_SECONDS) if index.positive? && !Rails.env.test?

      outcome = detector.check(document)
      report[:checked] += 1

      case outcome.status
      when :unchanged then report[:unchanged] += 1
      when :failed
        report[:failed] += 1
        # 출처 장애가 길어지면 콘텐츠를 지우지 않고 상태만 낮춘다(§32)
        if source.last_failure_kind == "SOURCE_UNAVAILABLE" && source.failure_count >= 3
          ContentFreshnessUpdater.mark_source_unavailable(document)
        end
        report[:alerts_sent] += 1 if alert_operator(source)
      when :changed
        report[:changed] += 1
        next if dry_run

        tasks = analyzer.analyze(outcome.change_event)
        ContentFreshnessUpdater.apply_change_event(outcome.change_event, tasks)
        report[:tasks_created] += tasks.size
      end
    end

    Rails.logger.info "[AuthorityFreshness] #{report.to_json}"
    report
  end

  private

  # P1.55B §10 — 연속 실패가 임계값에 이르면 운영자에게 알린다. 한 장애 episode 당 1회.
  #
  # best-effort: 알림 전송 실패가 **수집 자체를 실패시키면 안 된다**(§29).
  # 발송에 실패하면 alerted_at 을 찍지 않으므로 다음 주기에 다시 시도한다.
  def alert_operator(source)
    return false unless source.alert_due?

    AuthoritySourceMailer.failure_alert(source).deliver_now
    source.mark_alerted!
    Rails.logger.warn "[AuthorityFreshness] 소스 장애 알림 발송: #{source.key} (연속 #{source.failure_count}회)"
    true
  rescue StandardError => e
    Rails.logger.error "[AuthorityFreshness] 알림 발송 실패(수집은 계속): #{e.class} #{e.message}"
    false
  end

  # idempotent — 같은 주기 안에서 다시 돌려도 due? 가 false 라 재검사하지 않는다.
  def target_documents(document_ids, limit)
    scope = AuthorityDocument.includes(:authority_source).joins(:authority_source)
                             .where(authority_sources: { enabled: true })
    return scope.where(id: document_ids).limit(limit) if document_ids.present?

    scope.select { |d| d.authority_source.due? }.first(limit)
  end
end
