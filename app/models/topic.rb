class Topic < ApplicationRecord
  include PgSearch::Model

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

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # 키워드 매칭으로 토픽 찾기
  def self.find_by_query(query)
    return none if query.blank?

    # 1. 정확한 이름 매칭
    exact = published.where("name ILIKE ?", "%#{query}%").first
    return exact if exact

    # 2. 키워드 매칭
    keyword_match = published.where("keywords ILIKE ?", "%#{query}%").first
    return keyword_match if keyword_match

    # 3. 전문 검색
    published.search_by_keyword(query).first
  end

  # 관련 토픽 찾기
  def related_topics(limit: 5)
    Topic.published
         .where(category: category)
         .where.not(id: id)
         .limit(limit)
  end

  # 조회수 증가
  def increment_view!
    increment!(:view_count)
  end

  # 키워드 배열로 반환
  def keyword_list
    return [] if keywords.blank?
    keywords.split(',').map(&:strip)
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

  def generate_slug
    self.slug = name.parameterize.presence || "topic-#{SecureRandom.hex(4)}"
  end
end
