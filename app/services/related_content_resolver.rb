# Sprint B Phase 1 (2026-05-17) — Hub&Spoke 자동 연관 추천
#
# 단일 토픽을 입력받아 관련 토픽·감사사례·가이드를 가중치 점수로 추천.
# 기존 controller의 4개 산발 쿼리(같은 카테고리 토픽 / topic_slug 매칭 감사사례·가이드)를
# 통합하고, 키워드 교집합·sector 매칭·인기도까지 반영해 추천 정밀도를 높임.
#
# 예상 효과 (gimi9 권위자 패널 추정): 체류시간 +40%, MAU +15%
class RelatedContentResolver
  TOPIC_LIMIT = 6
  AUDIT_LIMIT = 5
  GUIDE_LIMIT = 3
  CACHE_TTL = 1.hour

  SCORE_SAME_CATEGORY = 10
  SCORE_SAME_SECTOR   = 5
  SCORE_KEYWORD_HIT   = 3
  SCORE_DIRECT_SLUG   = 100   # topic_slug 직접 매칭은 절대 우선
  VIEW_WEIGHT         = 0.001

  def initialize(topic)
    @topic = topic
    @keywords = topic.keyword_list
  end

  def topics
    Rails.cache.fetch(cache_key(:topics), expires_in: CACHE_TTL) do
      candidates = candidate_topics
      candidates.sort_by { |t| -score_topic(t) }.first(TOPIC_LIMIT)
    end
  end

  def audit_cases
    Rails.cache.fetch(cache_key(:audit_cases), expires_in: CACHE_TTL) do
      direct = AuditCase.published.where(topic_slug: @topic.slug).recent.to_a
      return direct.first(AUDIT_LIMIT) if direct.size >= AUDIT_LIMIT

      fallback = fallback_audit_cases(exclude_slugs: direct.map(&:slug))
      (direct + fallback).first(AUDIT_LIMIT)
    end
  end

  def guides
    Rails.cache.fetch(cache_key(:guides), expires_in: CACHE_TTL) do
      direct = Guide.published.where(topic_slug: @topic.slug).to_a
      return direct.first(GUIDE_LIMIT) if direct.size >= GUIDE_LIMIT

      fallback = fallback_guides(exclude_ids: direct.map(&:id))
      (direct + fallback).first(GUIDE_LIMIT)
    end
  end

  def to_h
    { topics: topics, audit_cases: audit_cases, guides: guides }
  end

  private

  def cache_key(kind)
    "related_content_v2/#{@topic.slug}/#{kind}"
  end

  def candidate_topics
    base = Topic.published.where.not(slug: @topic.slug)
    # 카테고리 OR 키워드 매칭으로 후보 풀 (최대 50개)
    if @keywords.any?
      base.where(
        "category = :cat OR sector = :sector OR (#{keyword_or_clause(:keywords)})",
        cat: @topic.category, sector: Topic.sectors[@topic.sector], **keyword_binds
      ).limit(50).to_a
    else
      base.where(category: @topic.category).limit(50).to_a
    end
  end

  def fallback_audit_cases(exclude_slugs:)
    base = AuditCase.published.recent.where(category: @topic.category)
    base = base.where.not(slug: exclude_slugs) if exclude_slugs.any?
    if @keywords.any?
      base.where(
        "category = :cat OR (#{keyword_or_clause(:title)})",
        cat: @topic.category, **keyword_binds
      ).limit(AUDIT_LIMIT).to_a
    else
      base.limit(AUDIT_LIMIT).to_a
    end
  end

  def fallback_guides(exclude_ids:)
    base = Guide.published
    base = base.where.not(id: exclude_ids) if exclude_ids.any?
    if @keywords.any?
      base.where(keyword_or_clause(:title), **keyword_binds).limit(GUIDE_LIMIT).to_a
    else
      base.where(category: @topic.category).limit(GUIDE_LIMIT).to_a
    end
  end

  def keyword_or_clause(column)
    @keywords.first(8).each_with_index.map { |_, i| "#{column} ILIKE :kw_#{i}" }.join(" OR ")
  end

  def keyword_binds
    @keywords.first(8).each_with_index.with_object({}) do |(kw, i), hash|
      hash["kw_#{i}".to_sym] = "%#{Topic.sanitize_sql_like(kw)}%"
    end
  end

  def score_topic(t)
    score = 0
    score += SCORE_SAME_CATEGORY if t.category == @topic.category
    score += SCORE_SAME_SECTOR   if t.sector   == @topic.sector
    other_kws = t.keyword_list
    intersection = (@keywords & other_kws).size
    score += intersection * SCORE_KEYWORD_HIT
    score += (t.view_count || 0) * VIEW_WEIGHT
    score
  end
end
