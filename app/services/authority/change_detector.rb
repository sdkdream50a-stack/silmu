# frozen_string_literal: true

# P1.5 §19 — FETCH → NORMALIZE → HASH → COMPARE → STORE VERSION
#
# ⚠️ 이 서비스는 READ-ONLY DETECTOR 다(§4).
#    authority_* 테이블에만 쓰고, Topic/Guide/AuditCase/Tool/Template 의 **본문을 절대 건드리지 않는다.**
module Authority
  class ChangeDetector
    Outcome = Struct.new(:status, :document, :version, :change_event, :message, keyword_init: true) do
      def changed? = status == :changed
      def unchanged? = status == :unchanged
      def failed? = status == :failed
    end

    def initialize(fetcher: nil)
      @fetchers = { "law_api" => fetcher || LawApiFetcher.new }
    end

    def check(document, now: Time.current)
      source = document.authority_source
      fetcher = @fetchers[source.fetch_strategy]
      return failure(document, source, "PARSE_FAILED", "지원하지 않는 fetch_strategy: #{source.fetch_strategy}") if fetcher.nil?

      result = fetcher.fetch(document.title)
      return failure(document, source, result.failure_kind, result.message) if result.failed?

      normalized = Normalizer.normalize(result.raw_content, format: result.format)
      hash = AuthorityVersion.digest(normalized)
      previous = document.authority_versions.order(fetched_at: :desc).first

      diff = DiffEngine.compare(previous, result.metadata, hash, new_content: normalized)

      source.record_success!(at: now)
      document.update!(last_checked_at: now)

      if diff.nil?
        return Outcome.new(status: :unchanged, document: document, version: previous,
                           message: "변경 없음 (hash 일치)")
      end

      version = store_version!(document, result, normalized, hash, now)
      event = AuthorityChangeEvent.create!(
        authority_document: document,
        old_version_id: previous&.id,
        new_version_id: version.id,
        detected_at: now,
        change_type: diff.change_type,
        diff_level: diff.level,
        diff_summary: diff.summary,
        machine_diff: diff.machine_diff,
        effective_at: version.effective_at,
        impact_status: "PENDING",
        review_status: "OPEN"
      )
      document.update!(current_version: version)

      Outcome.new(status: :changed, document: document, version: version,
                  change_event: event, message: diff.summary)
    end

    private

    def store_version!(document, result, normalized, hash, now)
      meta = result.metadata
      AuthorityVersion.create!(
        authority_document: document,
        version_identifier: meta[:mst],
        revision_number: meta[:revision_number],
        revision_kind: meta[:revision_kind],
        promulgated_at: parse_date(meta[:promulgated_on]),
        effective_at: parse_date(meta[:effective_on]),
        fetched_at: now,
        source_url: result.source_url,
        content_hash: hash,
        raw_metadata: meta.transform_keys(&:to_s),
        normalized_content: normalized
      )
    end

    # 법제처 포맷 YYYYMMDD
    def parse_date(value)
      return nil if value.blank?
      return Date.parse(value) if value.to_s.include?("-")

      s = value.to_s.gsub(/\D/, "")
      return nil unless s.length == 8

      Date.strptime(s, "%Y%m%d")
    rescue Date::Error
      nil
    end

    def failure(document, source, kind, message)
      source.record_failure!(kind, message)
      document.update!(last_checked_at: Time.current)
      Outcome.new(status: :failed, document: document, message: "#{kind}: #{message}")
    end
  end
end
