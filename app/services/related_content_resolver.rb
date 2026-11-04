# Sprint B Phase 1 (2026-05-17) — Hub&Spoke 자동 연관 추천
#
# 단일 토픽을 입력받아 관련 토픽·감사사례·가이드를 가중치 점수로 추천.
# 기존 controller의 4개 산발 쿼리(같은 카테고리 토픽 / topic_slug 매칭 감사사례·가이드)를
# 통합하고, 키워드 교집합·sector 매칭·인기도까지 반영해 추천 정밀도를 높임.
#
# 조회수는 점수에서 뺐다(2026-11-04): 조회수 높은 토픽으로 링크가 쏠린다.
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

  # 내부 링크 재배치 (2026-11-04) — 조회수·최신순으로 고르면 모든 페이지가 같은 몇 건만 가리켜
  #   다른 페이지로 가는 링크가 없고 페이지마다 같은 요약 카드가 반복된다. 점수가 같으면 조회수 대신
  #   «이 페이지 + 후보» 해시로 순서를 정한다. 페이지마다 후보가 고르게 갈리고, 재시작해도 순서가 같다.
  TOPIC_LINK_COLUMNS = %i[id slug name summary category sector keywords view_count].freeze
  CASE_GUIDE_LIMIT   = 2
  GUIDE_CASE_LIMIT   = 3

  # Guide.category(한국어) → AuditCase.category. topic_slug 가 없는 가이드의 같은 분야 사례를 찾는다.
  GUIDE_AUDIT_CATEGORY_MAP = {
    "계약" => %w[수의계약 입찰 계약체결 계약이행 대금지급 하도급 검수/검사],
    "예산" => %w[예산 회계]
  }.freeze

  def self.spread(records, seed)
    records.sort_by { |record| Digest::MD5.hexdigest("#{seed}/#{record.slug}") }
  end

  # 가이드 화면 «관련 가이드» — 같은 토픽을 앞세우고, 모자라면 같은 분류에서 고르게 채운다.
  def self.guides_for_guide(guide, limit: 3)
    base = Guide.published.where.not(id: guide.id).select(&:has_full_content?)
    same_topic, others = base.partition { |g| guide.topic_slug.present? && g.topic_slug == guide.topic_slug }
    same_category, rest = others.partition { |g| g.category == guide.category }
    [ same_topic, same_category, rest ].flat_map { |group| spread(group, guide.slug) }.first(limit)
  end

  # 가이드 화면 «함께 볼 감사사례» — 가상(noindex) 사례는 싣지 않는다.
  def self.audit_cases_for_guide(guide, topic_slug:, limit: GUIDE_CASE_LIMIT)
    base = AuditCase.published.search_indexable
    direct = topic_slug.present? ? spread(base.where(topic_slug: topic_slug).to_a, guide.slug) : []
    return direct.first(limit) if direct.size >= limit

    categories = GUIDE_AUDIT_CATEGORY_MAP[guide.category.to_s]
    return direct if categories.blank?

    direct + spread(base.where(category: categories).where.not(slug: direct.map(&:slug)).to_a, guide.slug).first(limit - direct.size)
  end

  # 감사사례 화면 «유사 감사사례» — 같은 토픽을 앞세우고, 모자라면 같은 분류에서 고르게 채운다.
  def self.audit_cases_for_case(audit_case, limit: 4)
    candidates = AuditCase.published.search_indexable.where(category: audit_case.category).where.not(id: audit_case.id).to_a
    if audit_case.topic_slug.present?
      candidates += AuditCase.published.search_indexable.where(topic_slug: audit_case.topic_slug).where.not(id: audit_case.id).to_a
    end
    same_topic, others = candidates.uniq(&:id).partition { |ac| audit_case.topic_slug.present? && ac.topic_slug == audit_case.topic_slug }
    (spread(same_topic, audit_case.slug) + spread(others, audit_case.slug)).first(limit)
  end

  # 감사사례 화면 «관련 실무 가이드»
  def self.guides_for_case(audit_case, limit: CASE_GUIDE_LIMIT)
    return [] if audit_case.topic_slug.blank?

    spread(Guide.published.where(topic_slug: audit_case.topic_slug).select(&:has_full_content?), audit_case.slug).first(limit)
  end

  # Topic.category(영문) → AuditCase.category(한국어) 매핑.
  # Topic은 영문 카테고리, AuditCase는 한국어 카테고리를 쓰는 분류 체계 차이를
  # 메우기 위한 변환 테이블. duty/salary/travel은 AuditCase 한국어 분류와
  # 의미적 1:1 대응이 없으므로(인사/복무/급여 카테고리 부재) 매핑을 두지 않음.
  # 이 토픽들은 키워드(title ILIKE) 매칭으로만 fallback.
  AUDIT_CATEGORY_MAP = {
    "contract" => %w[수의계약 입찰 계약체결 계약이행 대금지급 하도급 검수/검사],
    "budget"   => %w[예산 회계]
  }.freeze

  def initialize(topic)
    @topic = topic
    @keywords = topic.keyword_list
  end

  def topics
    Rails.cache.fetch(cache_key(:topics), expires_in: CACHE_TTL) do
      ranked(candidate_topics) { |t| score_topic(t) }.first(TOPIC_LIMIT)
    end
  end

  def audit_cases
    Rails.cache.fetch(cache_key(:audit_cases), expires_in: CACHE_TTL) do
      # F4a (2026-10-05) — 가상 예방 시나리오(SIMULATED·noindex)는 색인되는 토픽 화면에 싣지 않는다.
      #   상세 noindex 만으로는 요약 카드가 토픽 페이지에 그대로 남아 심사 표면이 된다.
      direct = AuditCase.published.search_indexable.where(topic_slug: @topic.slug).recent.to_a
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

  # 점수가 높은 순. 점수가 같으면 이 토픽 기준 해시 순서로 고르게 나눈다.
  def ranked(records)
    self.class.spread(records, @topic.slug).sort_by.with_index { |record, i| [ -yield(record), i ] }
  end

  def title_hits(record)
    @keywords.first(8).count { |kw| record.title.to_s.include?(kw) }
  end

  def candidate_topics
    # 카테고리 OR 키워드 매칭으로 후보 풀. 링크에 쓸 컬럼만 읽는다(본문 컬럼은 캐시에 싣지 않는다).
    base = Topic.published.where.not(slug: @topic.slug).select(*TOPIC_LINK_COLUMNS)
    if @keywords.any?
      base.where(
        "category = :cat OR sector = :sector OR (#{keyword_or_clause(:keywords)})",
        cat: @topic.category, sector: Topic.sectors[@topic.sector], **keyword_binds
      ).to_a
    else
      base.where(category: @topic.category).to_a
    end
  end

  def fallback_audit_cases(exclude_slugs:)
    mapped = AUDIT_CATEGORY_MAP[@topic.category.to_s] || []

    base = AuditCase.published.search_indexable
    base = base.where.not(slug: exclude_slugs) if exclude_slugs.any?

    candidates =
      if mapped.any? && @keywords.any?
        base.where(
          "category IN (:cats) OR (#{keyword_or_clause(:title)})",
          cats: mapped, **keyword_binds
        ).to_a
      elsif @keywords.any?
        base.where(keyword_or_clause(:title), **keyword_binds).to_a
      elsif mapped.any?
        base.where(category: mapped).to_a
      else
        []
      end
    ranked(candidates) { |ac| title_hits(ac) }.first(AUDIT_LIMIT)
  end

  def fallback_guides(exclude_ids:)
    base = Guide.published
    base = base.where.not(id: exclude_ids) if exclude_ids.any?
    if @keywords.any?
      ranked(base.where(keyword_or_clause(:title), **keyword_binds).to_a) { |g| title_hits(g) }.first(GUIDE_LIMIT)
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
    score + intersection * SCORE_KEYWORD_HIT
  end
end
