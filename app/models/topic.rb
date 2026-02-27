class Topic < ApplicationRecord
  include PgSearch::Model

  # 부모-자식 관계 (서브토픽)
  belongs_to :parent, class_name: 'Topic', optional: true
  has_many :subtopics, class_name: 'Topic', foreign_key: 'parent_id', dependent: :destroy

  # 검색 설정
  pg_search_scope :search_by_keyword,
    against: [:name, :keywords, :summary],
    using: {
      tsearch: { prefix: true, dictionary: "simple" },
      trigram: { threshold: 0.1 }
    }

  # Scopes
  scope :published, -> { where(published: true) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :popular, -> { order(view_count: :desc) }
  scope :root_topics, -> { where(parent_id: nil) }

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  after_commit :expire_count_cache

  # 키워드 매칭으로 토픽 찾기
  def self.find_by_query(query, exclude_slug: nil)
    return none if query.blank?

    scope = published
    scope = scope.where.not(slug: exclude_slug) if exclude_slug.present?

    # 1. 정확한 이름 매칭
    exact = scope.where("name ILIKE ?", "%#{sanitize_sql_like(query)}%").first
    return exact if exact

    # 2. 키워드 매칭
    keyword_match = scope.where("keywords ILIKE ?", "%#{sanitize_sql_like(query)}%").first
    return keyword_match if keyword_match

    # 3. 전문 검색
    scope.search_by_keyword(query).first
  end

  # 관련 토픽 찾기
  def related_topics(limit: 5)
    Topic.published
         .where(category: category)
         .where.not(id: id)
         .limit(limit)
  end

  # 조회수 증가 (update_counters: updated_at 보존, atomic 단일 쿼리)
  def increment_view!
    self.class.update_counters(id, view_count: 1)
  end

  # 키워드 배열로 반환
  def keyword_list
    return [] if keywords.blank?
    keywords.split(',').map(&:strip)
  end

  # 키워드별 매칭 토픽을 단일 쿼리로 조회 (N+1 방지)
  # 반환값: { "키워드" => Topic 또는 nil }
  def keyword_topic_map(limit: 8)
    kws = keyword_list.first(limit)
    return {} if kws.empty?

    subtopics_loaded = subtopics.published.to_a

    safe_kws = kws.map { |k| Topic.sanitize_sql_like(k) }
    name_cond = kws.map { "name ILIKE ?" }.join(" OR ")
    kw_cond   = safe_kws.map { "keywords ILIKE ?" }.join(" OR ")

    candidates = Topic.published
                      .where.not(id: id)
                      .where(
                        "(#{name_cond}) OR (#{kw_cond})",
                        *kws,
                        *safe_kws.map { |k| "%#{k}%" }
                      )
                      .to_a

    kws.each_with_object({}) do |keyword, map|
      kw_down = keyword.downcase
      match = subtopics_loaded.find { |t| t.name.downcase == kw_down }
      match ||= candidates.find { |t| t.name.downcase == kw_down }
      match ||= candidates.find { |t| t.keywords.to_s.downcase.include?(kw_down) }
      map[keyword] = match
    end
  end

  # 관련 감사사례 (DB 기반)
  def related_audit_cases
    AuditCase.published.where(topic_slug: slug).recent
  end

  # FAQ 배열로 반환 (JSON 파싱)
  def faq_list
    return [] if faqs.blank?
    JSON.parse(faqs) rescue []
  end

  # 법령 3단 데이터가 있는지
  def has_law_content?
    law_content.present? || decree_content.present? || rule_content.present?
  end

  # 카테고리 목록
  CATEGORIES = {
    'contract' => '계약',
    'budget' => '예산/결산',
    'expense' => '지출',
    'salary' => '급여/수당',
    'subsidy' => '보조금',
    'property' => '공유재산',
    'travel' => '여비/출장',
    'duty' => '복무',
    'other' => '기타'
  }.freeze

  def category_name
    CATEGORIES[category] || category
  end

  private

  def expire_count_cache
    Rails.cache.delete("stats/topic_count")
    Rails.cache.delete("topics/all_published_v2")
    Rails.cache.delete("topic_related/#{slug}")
    Rails.cache.delete("topic_audit_cases/#{slug}")
  end

  def generate_slug
    self.slug = name.parameterize.presence || "topic-#{SecureRandom.hex(4)}"
  end
end
