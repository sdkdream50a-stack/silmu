# frozen_string_literal: true

# Sprint B Phase 1 안전망 — RelatedContentResolver 회귀 방지
#
# 배경: commit d8be8a5(2026-05-17) RelatedContentResolver 풀스택 운영 라이브.
#       서비스·controller·view·캐시 무효화 hook까지 통합됐으나 테스트 부재.
#       점수 튜닝(SCORE_SAME_CATEGORY 등) 또는 후보 풀 쿼리 변경 시 회귀 위험 → 안전망 필요.
#
# 검증: 점수 계산, direct topic_slug 우선, fallback 합산, 캐시 키 형식, 빈 키워드 안전성.

require "test_helper"

class RelatedContentResolverTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear

    @host = Topic.create!(
      name: "호스트 토픽",
      slug: "rc-host",
      category: "contract",
      sector: :common,
      keywords: "수의계약,입찰,낙찰",
      view_count: 10,
      published: true
    )

    # same category + 키워드 2개 교집합 (수의계약, 입찰) → 점수 10 + 5(sector) + 6 = 21
    @same_cat_kw_hit = Topic.create!(
      name: "동일 카테고리 키워드 매칭",
      slug: "rc-same-cat-kw",
      category: "contract",
      sector: :common,
      keywords: "수의계약,입찰,계약방식",
      view_count: 5,
      published: true
    )

    # same sector, 다른 category, 키워드 0개 → 5점
    @same_sec_only = Topic.create!(
      name: "동일 sector만",
      slug: "rc-same-sec-only",
      category: "budget",
      sector: :common,
      keywords: "예산편성",
      view_count: 200,
      published: true
    )

    # same category, 키워드 1개 매칭 → 10 + 5 + 3 = 18
    @same_cat_only = Topic.create!(
      name: "동일 카테고리 키워드 1개",
      slug: "rc-same-cat-only",
      category: "contract",
      sector: :common,
      keywords: "낙찰,예정가격",
      view_count: 1,
      published: true
    )
  end

  # ── score_topic ─────────────────────────────────────────────────────────
  test "score_topic: same_category +10, same_sector +5, keyword 교집합 ×3, view_count ×0.001" do
    resolver = RelatedContentResolver.new(@host)

    # same_cat_kw_hit: same_cat(10) + same_sec(5) + 키워드 2개(수의계약·입찰) ×3 + 5×0.001
    score = resolver.send(:score_topic, @same_cat_kw_hit)
    assert_in_delta 21.005, score, 0.0001

    # same_cat_only: same_cat(10) + same_sec(5) + 키워드 1개(낙찰) ×3 + 1×0.001
    assert_in_delta 18.001, resolver.send(:score_topic, @same_cat_only), 0.0001

    # same_sec_only: same_sec(5) + 키워드 0개 + 200×0.001
    assert_in_delta 5.2, resolver.send(:score_topic, @same_sec_only), 0.0001
  end

  # ── topics ──────────────────────────────────────────────────────────────
  test "topics: 점수순 정렬 + 호스트 토픽 제외 + TOPIC_LIMIT(6) 적용" do
    resolver = RelatedContentResolver.new(@host)
    result = resolver.topics

    assert result.size <= RelatedContentResolver::TOPIC_LIMIT
    refute_includes result.map(&:slug), "rc-host", "호스트 토픽 자체는 제외돼야 함"

    setup_slugs = %w[rc-same-cat-kw rc-same-cat-only rc-same-sec-only]
    in_set = result.select { |t| setup_slugs.include?(t.slug) }

    if in_set.size >= 2
      first_two = in_set.first(2).map(&:slug)
      assert_equal "rc-same-cat-kw", first_two.first,
                   "키워드 2개 매칭 토픽이 최상위여야 함 (실제: #{first_two.inspect})"
    end
  end

  # ── audit_cases: direct topic_slug 우선 ──────────────────────────────────
  test "audit_cases: direct topic_slug 매칭이 AUDIT_LIMIT 충족하면 그것만 반환" do
    AuditCase::AUDIT_LIMIT rescue nil

    RelatedContentResolver::AUDIT_LIMIT.times do |i|
      AuditCase.create!(
        title: "Direct AC #{i}",
        slug: "rc-ac-direct-#{i}",
        category: "수의계약",
        sector: :common,
        topic_slug: @host.slug,
        published: true
      )
    end

    # 다른 카테고리 fallback 후보 (호스트와 무관)
    AuditCase.create!(
      title: "Unrelated AC",
      slug: "rc-ac-unrelated",
      category: "예산",
      sector: :common,
      topic_slug: nil,
      published: true
    )

    result = RelatedContentResolver.new(@host).audit_cases
    assert_equal RelatedContentResolver::AUDIT_LIMIT, result.size
    assert(result.all? { |ac| ac.topic_slug == @host.slug },
           "direct 매칭이 충분하면 fallback 없이 direct만 반환해야 함")
  end

  test "audit_cases: direct 부족 시 fallback 합산 (category·keyword 매칭)" do
    AuditCase.create!(
      title: "Direct AC only",
      slug: "rc-ac-direct-only",
      category: "수의계약",
      sector: :common,
      topic_slug: @host.slug,
      published: true
    )

    # category contract 매칭 fallback (host.category와 동일)
    AuditCase.create!(
      title: "Fallback by category",
      slug: "rc-ac-fb-cat",
      category: "contract",
      sector: :common,
      topic_slug: nil,
      published: true
    )

    result = RelatedContentResolver.new(@host).audit_cases
    direct_count = result.count { |ac| ac.topic_slug == @host.slug }

    assert_equal 1, direct_count, "direct 1건은 반드시 포함"
    assert result.size > direct_count, "direct(1) < AUDIT_LIMIT(5)이므로 fallback 합산돼야 함"
  end

  # ── guides: direct topic_slug 우선 ──────────────────────────────────────
  test "guides: direct topic_slug 매칭이 우선 반환" do
    Guide.create!(
      title: "Direct Guide",
      slug: "rc-guide-direct",
      category: "contract",
      sector: :common,
      topic_slug: @host.slug,
      published: true
    )

    result = RelatedContentResolver.new(@host).guides
    assert result.size <= RelatedContentResolver::GUIDE_LIMIT
    assert_includes result.map(&:slug), "rc-guide-direct"
  end

  # ── cache key 형식 ──────────────────────────────────────────────────────
  test "cache_key: 형식이 related_content_v2/{slug}/{kind} 임" do
    resolver = RelatedContentResolver.new(@host)
    assert_equal "related_content_v2/rc-host/topics",      resolver.send(:cache_key, :topics)
    assert_equal "related_content_v2/rc-host/audit_cases", resolver.send(:cache_key, :audit_cases)
    assert_equal "related_content_v2/rc-host/guides",      resolver.send(:cache_key, :guides)
  end

  test "to_h: topics·audit_cases·guides 3개 키를 모두 반환" do
    result = RelatedContentResolver.new(@host).to_h
    assert_equal %i[topics audit_cases guides].sort, result.keys.sort
  end

  # ── 빈 키워드 fallback ──────────────────────────────────────────────────
  test "빈 키워드 토픽: 예외 없이 category 기반 후보 반환" do
    no_kw_host = Topic.create!(
      name: "키워드 없는 호스트",
      slug: "rc-no-kw-host",
      category: "contract",
      sector: :common,
      keywords: "",
      view_count: 0,
      published: true
    )

    assert_nothing_raised do
      result = RelatedContentResolver.new(no_kw_host).topics
      assert result.is_a?(Array)
      refute_includes result.map(&:slug), "rc-no-kw-host"
    end
  end

  # ── 미발행 토픽 제외 ────────────────────────────────────────────────────
  test "published=false 토픽은 후보에서 제외" do
    Topic.create!(
      name: "미발행 토픽",
      slug: "rc-unpublished",
      category: "contract",
      sector: :common,
      keywords: "수의계약,입찰",
      published: false
    )

    result = RelatedContentResolver.new(@host).topics
    refute_includes result.map(&:slug), "rc-unpublished"
  end
end
