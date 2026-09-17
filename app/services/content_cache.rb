# frozen_string_literal: true

# G-57 (2026-09-18) — 콘텐츠 변경 후 캐시 무효화의 단일 입구.
#
# ── 무슨 일이 있었나 (운영 사고, 2026-09-18 배포)
#   content migration 7개를 적용해 DB 본문이 새 값이 됐는데 Rails origin 이 옛 값을 계속 반환했다.
#   복구는 운영 콘솔에서 캐시 키 784개를 **손으로** 지워서 했다.
#
# ── 원인 3개 (전부 실측)
#   ① content migration 30/40 개가 `update_columns` 로 쓴다 → after_commit 무효화 콜백이
#      **아예 실행되지 않는다**(Topic#expire_count_cache · Guide#expire_cache · AuditCase#expire_count_cache).
#   ② 그 콜백이 실행됐더라도 fragment/curated 버전 증가는 `saved_change_to_name?`·`summary?`·
#      `published?`·`category?`·`sector?` 에만 걸려 있다. migration 이 바꾸는 본문 컬럼
#      (law_content·decree_content·regulation_content·interpretation_content…)은 그 목록에 없다.
#   ③ Guide#expire_cache 는 `topic_guide/<slug>` 를 지우는데 **그 키는 아무도 쓰지 않는다.**
#      실제로 쓰고 읽는 키는 `topic_guide_ext/<slug>`(topics_controller)다 — 무효화가 허공을 지웠다.
#
#   그리고 AR 객체/목록을 담는 키(`topics/all_published_v2` 등)는 **객체의 속성값을 그대로 저장**하므로,
#   TTL 이 끝날 때까지 낡은 본문을 서빙한다. 이게 «DB 는 맞는데 화면은 틀리다» 의 정체다.
#
# ── 이 클래스가 하는 일
#   콘텐츠를 바꾼 쪽(migration runner · 배포 절차 · 콘솔)이 **한 줄로** 무효화를 호출하게 한다.
#   무엇을 지웠는지 수를 돌려주므로, 「지웠다고 말했지만 0건이었다」를 구별할 수 있다.
#
# ── 하지 않는 것
#   패턴 삭제(delete_matched)에 의존하지 않는다. 운영 캐시 스토어는 solid_cache 이고
#   패턴 삭제 지원이 보장되지 않는다. 키를 열거해 지운다 — 열거가 곧 등록부다.
class ContentCache
  # 콘텐츠가 바뀌면 낡는 **전역 키**(레코드 1건에 매이지 않는 목록·집계).
  GLOBAL_KEYS = %w[
    topics/all_published_v2
    audit_cases/all_published_v2
    guides/all/v2
    guides/popular
    home/popular_guides/v1
    home/task_entry_counts/v1
    standard_terms/synonym_index/v1
    stats/topic_count
    stats/guide_count
    stats/audit_case_count
    stats/audit_case_verified
    stats/sector_counts/v2
    chatbot_popular_topics
    chatbot_recent_popular
  ].freeze

  # 레코드 slug 로 갈라지는 키. `%{slug}` 를 치환한다.
  TOPIC_SLUG_KEYS = %w[
    topic_guide_ext/%{slug}
    topic_related/%{slug}
    topic_audit_cases/%{slug}
    topic_keyword_map/%{slug}
    topic_helpful/%{slug}
    topic_law_refs/v1/%{slug}
    related_content_v2/%{slug}/topics
    related_content_v2/%{slug}/audit_cases
    related_content_v2/%{slug}/guides
  ].freeze

  GUIDE_SLUG_KEYS = %w[
    guide_topic/%{slug}
    guides/related/%{slug}
  ].freeze

  AUDIT_CASE_SLUG_KEYS = %w[
    audit_case_topic/%{slug}
    audit_case_related/%{slug}
  ].freeze

  # guides/series/<series> 는 slug 가 아니라 series 값으로 갈라진다.
  GUIDE_SERIES_KEY = "guides/series/%{series}"

  # 키에 이 버전을 태우면 증가만으로 무효화된다(fragment cache 가 쓰는 방식).
  VERSION_COUNTERS = %w[
    topics/fragment_version
    audit_cases/fragment_version
    home/curated_version
  ].freeze

  Report = Struct.new(:deleted, :bumped, :series_deleted, keyword_init: true) do
    def to_s = "deleted=#{deleted} bumped=#{bumped} series=#{series_deleted}"
    def any? = deleted.positive? || bumped.positive?
  end

  class << self
    # 콘텐츠를 바꾼 뒤 부르는 단 하나의 입구.
    #
    #   ContentCache.invalidate!                      # 전부 (배포·migration 후)
    #   ContentCache.invalidate!(topic_slugs: %w[a b]) # 특정 토픽만
    #
    # slug 를 주지 않으면 published 레코드 전체를 순회한다. 배포당 1회라 비용을 감당한다.
    def invalidate!(topic_slugs: nil, guide_slugs: nil, audit_case_slugs: nil)
      deleted = 0

      GLOBAL_KEYS.each { |k| deleted += 1 if delete(k) }

      topic_slugs = resolve_slugs(topic_slugs, Topic)
      guide_slugs = resolve_slugs(guide_slugs, Guide)
      audit_case_slugs = resolve_slugs(audit_case_slugs, AuditCase)

      deleted += delete_slug_keys(TOPIC_SLUG_KEYS, topic_slugs)
      deleted += delete_slug_keys(GUIDE_SLUG_KEYS, guide_slugs)
      deleted += delete_slug_keys(AUDIT_CASE_SLUG_KEYS, audit_case_slugs)

      series_deleted = delete_guide_series

      bumped = 0
      VERSION_COUNTERS.each do |k|
        # increment 는 키가 없으면 nil 을 돌려준다 — 그때는 1로 세워 다음 증가가 먹게 한다.
        bumped += 1 if Rails.cache.increment(k) || Rails.cache.write(k, 1)
      end

      Report.new(deleted: deleted, bumped: bumped, series_deleted: series_deleted)
    end

    private

    def resolve_slugs(given, klass)
      return Array(given).compact.uniq if given.present?

      klass.published.pluck(:slug).compact.uniq
    rescue StandardError => e
      Rails.logger.warn "[ContentCache] #{klass} slug 조회 실패: #{e.message}"
      []
    end

    def delete_slug_keys(templates, slugs)
      count = 0
      slugs.each do |slug|
        templates.each { |t| count += 1 if delete(format(t, slug: slug)) }
      end
      count
    end

    # guides/series/<series> 는 slug 가 아니라 series 값으로 갈라진다.
    def delete_guide_series
      Guide.published.distinct.pluck(:series).compact.reject(&:blank?).count do |series|
        delete(format(GUIDE_SERIES_KEY, series: series))
      end
    rescue StandardError => e
      Rails.logger.warn "[ContentCache] guide series 조회 실패: #{e.message}"
      0
    end

    # delete 는 키가 없었으면 false 를 돌려준다 — 「지운 수」를 정직하게 세기 위해 그대로 쓴다.
    def delete(key)
      Rails.cache.delete(key)
    rescue StandardError => e
      Rails.logger.warn "[ContentCache] #{key} 삭제 실패: #{e.message}"
      false
    end
  end
end
