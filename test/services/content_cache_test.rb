# frozen_string_literal: true

require "test_helper"

# G-57 (2026-09-18) — 콘텐츠 캐시 무효화.
#
# 이 테스트는 사고를 두 방향에서 막는다.
#   ① 기구가 실제로 지우는지 (동작)
#   ② **새 미버전 캐시 키가 등록 없이 추가되는 것** (결함 클래스의 상시 강제)
#
# ②가 이 파일의 핵심이다. 784키를 손으로 지운 사고는 «이 키를 깜빡했다» 가 아니라
# «깜빡할 수 있는 구조» 였기 때문에 일어났다.
class ContentCacheTest < ActiveSupport::TestCase
  setup do
    @store = ActiveSupport::Cache::MemoryStore.new
    @original = Rails.cache
    Rails.cache = @store
  end

  teardown { Rails.cache = @original }

  # ── ① 동작
  test "전역 키를 실제로 지운다" do
    ContentCache::GLOBAL_KEYS.each { |k| Rails.cache.write(k, "stale") }

    report = ContentCache.invalidate!

    ContentCache::GLOBAL_KEYS.each do |k|
      assert_nil Rails.cache.read(k), "#{k} 가 남아 있다"
    end
    assert_operator report.deleted, :>=, ContentCache::GLOBAL_KEYS.size
  end

  test "토픽 slug 키를 지운다 — 사고의 진짜 키 topic_guide_ext 포함" do
    Rails.cache.write("topic_guide_ext/penalty-reduction-procedure", "옛 가이드")
    Rails.cache.write("topic_related/penalty-reduction-procedure", "옛 관련")

    ContentCache.invalidate!(topic_slugs: [ "penalty-reduction-procedure" ])

    assert_nil Rails.cache.read("topic_guide_ext/penalty-reduction-procedure"),
               "2026-09-18 사고의 그 키가 그대로 남았다"
    assert_nil Rails.cache.read("topic_related/penalty-reduction-procedure")
  end

  test "fragment·curated 버전 카운터를 올린다" do
    ContentCache::VERSION_COUNTERS.each { |k| Rails.cache.write(k, 5) }

    report = ContentCache.invalidate!

    ContentCache::VERSION_COUNTERS.each do |k|
      assert_operator Rails.cache.read(k).to_i, :>, 5, "#{k} 가 안 올라갔다"
    end
    assert_equal ContentCache::VERSION_COUNTERS.size, report.bumped
  end

  test "카운터가 없던 상태에서도 버전을 세운다" do
    # increment 는 키가 없으면 nil 이다 — 그때 조용히 넘기면 다음 증가도 먹지 않는다.
    ContentCache::VERSION_COUNTERS.each { |k| Rails.cache.delete(k) }
    ContentCache.invalidate!
    ContentCache::VERSION_COUNTERS.each do |k|
      assert_not_nil Rails.cache.read(k), "#{k} 가 세워지지 않았다"
    end
  end

  # 음성 대조 — 콘텐츠와 무관한 키는 건드리지 않는다.
  test "무관한 키(레이트리밋·GA4·검증)는 지우지 않는다" do
    unrelated = {
      "quote_review/1.2.3.4/minute" => 3,
      "ga4/silmu/real_time_users" => 12,
      "blog_verify/article_exists/253973/9" => true,
      "pagespeed/abc123" => 88
    }
    unrelated.each { |k, v| Rails.cache.write(k, v) }

    ContentCache.invalidate!

    unrelated.each do |k, v|
      assert_equal v, Rails.cache.read(k), "무관한 키 #{k} 를 지웠다"
    end
  end

  test "지운 수를 정직하게 센다 — 없던 키는 세지 않는다" do
    # 아무 키도 미리 쓰지 않았다. 전역 키가 하나도 없으면 deleted 가 0 이어야 한다.
    ContentCache::GLOBAL_KEYS.each { |k| Rails.cache.delete(k) }
    report = ContentCache.invalidate!(topic_slugs: [], guide_slugs: [], audit_case_slugs: [])
    assert_equal 0, report.deleted,
                 "없던 키를 지웠다고 센다 — 「지웠다」 보고를 믿을 수 없게 된다"
  end

  # ── ② 결함 클래스 상시 강제
  #
  # app/ 의 모든 Rails.cache.fetch 키를 훑어, 콘텐츠 파생 키가
  #   (a) 키 안에 버전/updated_at 을 태우고 있거나
  #   (b) ContentCache 등록부에 있거나
  #   (c) 콘텐츠와 무관하다고 아래 목록에 명시돼 있어야
  # 한다. 셋 다 아니면 실패한다 — 그게 2026-09-18 사고의 구조다.
  VERSION_BEARING = /
    updated_at | cache_key | fragment_version | curated_version |
    \/v\d | _v\d | cv\# | version
  /x

  # 콘텐츠와 무관한 키(외부 API·검증 캐시). **접두어**로 대조하고 이유를 함께 적는다.
  #   여기 넣는 것은 «우리 콘텐츠를 담지 않는다» 는 주장이다 — 담고 있으면 등록부로 가야 한다.
  CONTENT_UNRELATED = {
    "chatbot_cafe_articles"    => "외부 카페 수집물 — 우리 콘텐츠 아님",
    "chatbot_cafe_total_count" => "외부 카페 집계",
    "blog_verify/"             => "법제처 API 조문 존재 확인 캐시 — 외부 사실, 우리 본문 아님",
    "pagespeed/"               => "PageSpeed Insights API 응답 — 외부 측정값"
  }.freeze

  test "콘텐츠 파생 캐시 키는 버전을 태우거나 등록부에 있어야 한다" do
    registered = (
      ContentCache::GLOBAL_KEYS +
      ContentCache::TOPIC_SLUG_KEYS + ContentCache::GUIDE_SLUG_KEYS +
      ContentCache::AUDIT_CASE_SLUG_KEYS + [ ContentCache::GUIDE_SERIES_KEY ]
    ).map { |k| k.sub("%{slug}", "").sub("%{series}", "") }

    offenders = []

    Dir.glob(Rails.root.join("app/**/*.{rb,erb}")).each do |file|
      File.read(file).scan(/Rails\.cache\.fetch\(\s*"([^"]+)"/) do |(key)|
        next if key.match?(VERSION_BEARING)
        next if CONTENT_UNRELATED.keys.any? { |prefix| key.start_with?(prefix) }

        normalized = key.gsub(/#\{[^}]*\}/, "")
        next if registered.any? { |r| normalized.start_with?(r.gsub(/#\{[^}]*\}/, "")) || r.start_with?(normalized) }

        offenders << "#{file.sub("#{Rails.root}/", "")}: #{key}"
      end
    end

    assert_empty offenders, <<~MSG
      버전도 없고 등록부에도 없는 캐시 키가 있다. 콘텐츠를 고쳐도 최대 TTL 동안 옛 값이 나간다
      (2026-09-18 G-57 사고와 같은 구조). 다음 중 하나를 하라:
        · 키에 updated_at / fragment_version 을 태운다
        · ContentCache 의 GLOBAL_KEYS / *_SLUG_KEYS 에 등록한다
        · 콘텐츠와 무관하면 이 테스트의 CONTENT_UNRELATED 에 이유와 함께 적는다
      #{offenders.map { |o| "  - #{o}" }.join("\n")}
    MSG
  end

  test "등록부가 지우는 키는 실제로 어딘가에서 읽힌다" do
    # 2026-09-18 사고의 원인 ③: Guide 가 `topic_guide/<slug>` 를 지웠지만 그 키는 아무도 안 썼다.
    # 존재하지 않는 키를 지우는 «허공 무효화» 를 다시 만들지 않는다.
    sources = Dir.glob(Rails.root.join("app/**/*.{rb,erb}")).map { |f| File.read(f) }.join("\n")
    dangling = []

    (ContentCache::GLOBAL_KEYS +
     ContentCache::TOPIC_SLUG_KEYS + ContentCache::GUIDE_SLUG_KEYS +
     ContentCache::AUDIT_CASE_SLUG_KEYS + [ ContentCache::GUIDE_SERIES_KEY ]).each do |template|
      prefix = template.split(/%\{(?:slug|series)\}/).first
      next if prefix.blank?
      # fetch/read/write 중 하나로 그 접두어가 등장해야 한다.
      dangling << template unless sources.include?("\"#{prefix}")
    end

    assert_empty dangling,
                 "아무도 쓰지 않는 키를 지우고 있다(허공 무효화): #{dangling.inspect}"
  end

  test "Guide 무효화가 실제로 쓰이는 topic_guide_ext 키를 지운다" do
    src = Rails.root.join("app/models/guide.rb").read
    assert_includes src, 'Rails.cache.delete("topic_guide_ext/',
                    "Guide 가 아직 존재하지 않는 topic_guide/ 키를 지우고 있다"
    assert_not_includes src, 'Rails.cache.delete("topic_guide/',
                        "쓰이지 않는 topic_guide/ 삭제가 남아 있다"
  end

  test "content migration runner 가 무효화를 호출한다" do
    src = Rails.root.join("lib/tasks/silmu_content_migrate.rake").read

    # 파일 어딘가에 문자열이 있는 것으로는 부족하다 — **content_migrate 태스크 본문 안**,
    # 그리고 완료 보고 **전에** 있어야 한다. (뮤테이션 실측: 문자열 존재만 보면
    #  content_migrate 안의 호출을 no-op 으로 바꿔도 통과했다. 별도 태스크의 같은 문자열이
    #  검사를 만족시켰기 때문이다.)
    task_body = src[/task content_migrate:.*?(?=^  desc |^  namespace )/m]
    assert task_body.present?, "content_migrate 태스크 본문을 찾지 못했다 — 검사가 대상을 놓쳤다"

    assert_includes task_body, "ContentCache.invalidate!",
                    "migration 적용 후 캐시 무효화가 절차에 없다 — 수동 복구로 되돌아간다"
    assert_match(/applied_count\.positive\?/, task_body,
                 "적용 0건일 때도 캐시를 비운다 — 불필요한 부하")

    invalidate_at = task_body.index("ContentCache.invalidate!")
    done_at = task_body.index("ContentMigration 완료")
    assert done_at.present?, "완료 보고 줄을 찾지 못했다"
    assert_operator invalidate_at, :<, done_at,
                    "완료를 보고한 뒤에 무효화한다 — 순서가 뒤집혔다"
  end

  test "수동·배포용 무효화 태스크가 0건이면 실패한다" do
    src = Rails.root.join("lib/tasks/silmu_content_migrate.rake").read
    task_body = src[/task content_cache_invalidate:.*?\n  end/m]
    assert task_body.present?, "content_cache_invalidate 태스크가 없다"
    assert_includes task_body, "ContentCache.invalidate!"
    assert_match(/abort/, task_body,
                 "아무것도 지우지 못했는데 성공으로 끝난다 — 「지웠다」를 믿을 수 없게 된다")
  end
end
