class Topic < ApplicationRecord
  include PgSearch::Model
  include LegalVerifiable
  include AuthorityMetadata
  include AgencyScope

  # 부모-자식 관계 (서브토픽)
  belongs_to :parent, class_name: "Topic", optional: true
  has_many :subtopics, class_name: "Topic", foreign_key: "parent_id", dependent: :destroy

  # 검색 설정
  pg_search_scope :search_by_keyword,
    against: [ :name, :keywords, :summary ],
    using: {
      tsearch: { prefix: true, dictionary: "simple" },
      trigram: { threshold: 0.1 }
    }

  # Sector enum (0: common 공통, 1: local_gov 지자체, 2: edu 교육행정)
  enum :sector, { common: 0, local_gov: 1, edu: 2 }, default: :common
  # "common" 또는 blank 전달 시 전체 반환 (common은 모든 sector에 공유되므로)
  scope :for_sector, ->(s) { where(sector: [ :common, s ]) if s.present? && s != "common" }

  # 6차 권위자 P1 — sector=edu 내부 분리 (전문가 패널 9:1 추천)
  # school: 단위학교 행정실 (학교회계 §30-2 + 교육공무원·지방공무원)
  # edu_office: 시도교육청 본청·지원청 (지방교육자치법 + 지방재정법)
  # nil: edu가 아닌 토픽 (common/local_gov)
  enum :org_type, { school: 0, edu_office: 1 }, prefix: :org

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
  before_save :update_law_verified_at, if: -> { law_content_changed? || decree_content_changed? || rule_content_changed? }
  after_commit :expire_count_cache
  # 2026-05-18: 본문/법령 변경에도 ping (published 컬럼 미변경 시에도 의미있는 갱신 알림)
  after_commit :notify_indexnow, if: lambda {
    published? && (
      saved_change_to_published? || saved_change_to_name? || saved_change_to_summary? ||
        saved_change_to_law_content? || saved_change_to_decree_content? ||
        saved_change_to_rule_content? || saved_change_to_commentary?
    )
  }
  before_update :cascade_slug_change, if: :slug_changed?

  # 통합 검색: 복수 토픽 반환 (멀티워드 토큰 AND 매칭 + 동의어 확장, 없으면 pg_search)
  # 각 토큰(동의어 변형 중 하나라도)이 name/keywords/summary 어느 필드든 매칭되어야 함.
  # 띄어쓰기 정규화(공백 제거 매칭)는 토큰 길이 4자 이상일 때만 적용 (단문 오탐 방지).
  # 랭킹: name 전 토큰 매칭 > keywords 매칭 > 나머지, 동순위 내 view_count DESC.
  def self.search_multiple(query, limit: 4)
    return none if query.blank?
    token_variants = SearchQueryParser.tokens(query)
    return none if token_variants.empty?

    clauses = []
    binds = {}
    literal_clauses = []
    token_variants.each_with_index do |variants, ti|
      per_token = []
      literal_per_token = []
      variants.each_with_index do |variant, vi|
        key = :"t#{ti}_#{vi}"
        pattern = "%#{sanitize_sql_like(variant)}%"
        binds[key] = pattern
        per_token << "name ILIKE :#{key} OR keywords ILIKE :#{key} OR summary ILIKE :#{key}"
        literal_per_token << sanitize_sql_array([ "name ILIKE ? OR keywords ILIKE ? OR summary ILIKE ?", pattern, pattern, pattern ])
        if variant.length >= 4
          dkey = :"d#{ti}_#{vi}"
          dpattern = "%#{sanitize_sql_like(variant.gsub(/\s+/, ''))}%"
          binds[dkey] = dpattern
          per_token << "REPLACE(name, ' ', '') ILIKE :#{dkey} OR REPLACE(keywords, ' ', '') ILIKE :#{dkey} OR REPLACE(summary, ' ', '') ILIKE :#{dkey}"
          literal_per_token << sanitize_sql_array([ "REPLACE(name, ' ', '') ILIKE ? OR REPLACE(keywords, ' ', '') ILIKE ? OR REPLACE(summary, ' ', '') ILIKE ?", dpattern, dpattern, dpattern ])
        end
      end
      clauses << "(#{per_token.join(' OR ')})"
      literal_clauses << "(#{literal_per_token.join(' OR ')})"
    end

    # 랭킹: 전 토큰(동의어 변형 포함)이 name에 매칭되면 0, keywords면 1, 그 외 2.
    name_all = token_variants.map { |variants|
      "(" + variants.map { |v| sanitize_sql_array([ "name ILIKE ?", "%#{sanitize_sql_like(v)}%" ]) }.join(" OR ") + ")"
    }.join(" AND ")
    kw_all = token_variants.map { |variants|
      "(" + variants.map { |v| sanitize_sql_array([ "keywords ILIKE ?", "%#{sanitize_sql_like(v)}%" ]) }.join(" OR ") + ")"
    }.join(" AND ")
    rank_sql = "CASE WHEN #{name_all} THEN 0 WHEN #{kw_all} THEN 1 ELSE 2 END"

    matches = published
                .where(clauses.join(" AND "), binds)
                .order(Arel.sql("#{rank_sql} ASC, view_count DESC"))
                .limit(limit)
    return matches if matches.any?

    # 전 토큰 AND 가 0건이면 부분집합으로 완화한다. 정확 매칭이 이미 0건이므로 순위 역전은 없다.
    relaxed = relaxed_match(literal_clauses, rank_sql, limit)
    return relaxed if relaxed && relaxed.any?

    search_by_keyword(query).merge(published).limit(limit)
  end

  # 점진적 완화 — 토큰 과반 이상이 매칭되면 채택하고, 매칭 토큰 수가 많은 순으로 정렬한다.
  # 자연어 질문에서 조사·어미를 걸러도 남는 비내용어("처음" 등) 때문에 AND 가 깨지는 경우를 구한다.
  # ORDER BY 는 바인드를 받지 못하므로 sanitize 된 리터럴 절을 쓴다(binds 판본과 동일한 패턴).
  def self.relaxed_match(literal_clauses, rank_sql, limit)
    return nil if literal_clauses.size < 2

    hit_count = literal_clauses.map { |c| "CASE WHEN #{c} THEN 1 ELSE 0 END" }.join(" + ")
    required = (literal_clauses.size / 2.0).ceil

    published
      .where("(#{hit_count}) >= #{required}")
      .order(Arel.sql("(#{hit_count}) DESC, #{rank_sql} ASC, view_count DESC"))
      .limit(limit)
  end

  # "바로 답" 히트로 인정하는 변형의 최소 길이 — 파서 MIN_STEM·컨트롤러 length>=2 와 같은 기준.
  ANSWER_MIN_TOKEN = 2

  # 검색어에 대한 "바로 답" — **기존 FAQ 원문만** 쓴다. 요약하거나 생성하지 않는다.
  # 후보 토픽의 faq_list 중 질문에 검색어 내용 토큰이 과반 이상 들어간 항목을 고르고,
  # 과반 미달이면 nil 을 준다. 약한 매칭에 "바로 답" 딱지를 붙이면 그게 거짓 신뢰다(P1.6 §21·§32).
  # 반환: { topic:, question:, answer:, hits: } 또는 nil
  def self.answer_for(query, topics)
    return nil if query.blank? || topics.blank?

    token_variants = SearchQueryParser.tokens(query)
    return nil if token_variants.empty?

    # "바로 답"은 신뢰도가 가장 높은 자리다. 과반만으로는 2토큰 질문에서 토큰 1개만 맞아도
    # 통과해 **다른 질문의 답**이 올라온다(실측: "병가 진단서" → "병가는 연 60일" 이 뽑혔다).
    # 그래서 최소 2토큰을 요구한다(토큰이 1개뿐인 질문은 그 1개). 틀린 답보다 없는 답이 낫다.
    required = [ (token_variants.size / 2.0).ceil, 2 ].max.clamp(1, token_variants.size)

    # DISTINCTIVE TOKEN GATE (P1.6 독립검증 HIGH 2건) — 검색 결과 범위는 건드리지 않고
    # "바로 답" 승격만 좁힌다. 일반 토큰("지급"·"기준")은 어느 업무에나 붙어서
    # **무엇을 묻는지 특정하지 못한다.** 그것만 맞은 FAQ 를 확신 있게 올리면
    # "차비 지급 기준" 에 "숙박비 지급 기준" 이 답으로 뜬다(실측).
    distinctive = token_variants.reject { |variants| SearchQueryParser.generic_variants?(variants) }

    # 고유 토큰이 하나도 없는 질문("지급 기준")은 어느 FAQ 를 골라도 근거가 없다.
    # 틀린 답보다 없는 답이 낫다 — 검색 결과는 그대로 보여주고 바로 답만 포기한다.
    # (아래 per-FAQ 게이트도 빈 distinctive 를 통과시키지 않는다. 이 줄은 정책을 눈에 보이게
    #  적어두고 FAQ 순회를 건너뛰는 것이며, 강제의 유일한 지점이 아니다.)
    return nil if distinctive.empty?

    best = nil

    topics.each do |topic|
      topic.faq_list.each do |faq|
        next unless faq.is_a?(Hash)

        question = faq["question"].to_s
        answer   = faq["answer"].to_s
        next if question.blank? || answer.blank?

        # 1글자 변형은 히트로 세지 않는다(P1.6 독립검증). include? 가 경계 없는 부분일치라
        # "차" 가 "차이는?" 안에서, "비" 가 "일비는" 안에서 걸려 **다른 질문의 답**이 승격됐다.
        # 파서의 MIN_STEM·컨트롤러의 length>=2 와 같은 기준이다.
        hits = token_variants.count { |variants|
          variants.any? { |v| v.length >= ANSWER_MIN_TOKEN && question.include?(v) }
        }
        next if hits < required

        # 고유 토큰은 **낱말 경계로 완전일치**해야 한다. include? 는 경계가 없어
        # "차비" 가 "주차비" 안에서 걸렸다(실측). 개수(hits)는 종전 기준을 그대로 쓰고,
        # 여기서는 "사용자가 실제로 물은 것이 이 질문에 있는가"만 따로 본다.
        question_tokens = SearchQueryParser.answer_tokens(question)
        next unless distinctive.any? { |variants|
          variants.any? { |v| v.length >= ANSWER_MIN_TOKEN && question_tokens.include?(v.downcase) }
        }

        best = { topic: topic, question: question, answer: answer, hits: hits } if best.nil? || hits > best[:hits]
      end
    end

    best
  end

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
    keywords.split(",").map(&:strip)
  end

  # 키워드별 매칭 토픽을 단일 쿼리로 조회 (N+1 방지)
  # 반환값: { "키워드" => Topic 또는 nil }
  def keyword_topic_map(limit: 8)
    kws = keyword_list.first(limit)
    return {} if kws.empty?

    subtopics_loaded = subtopics.published.to_a

    safe_kws = kws.map { |k| Topic.sanitize_sql_like(k) }

    tbl = Topic.arel_table
    name_matches = kws.map { |k| tbl[:name].matches(k) }
    kw_matches   = safe_kws.map { |k| tbl[:keywords].matches("%#{k}%") }
    combined     = (name_matches + kw_matches).reduce(:or)

    candidates = Topic.published
                      .where.not(id: id)
                      .where(combined)
                      .to_a

    kws.each_with_object({}) do |keyword, map|
      kw_down = keyword.downcase
      match = subtopics_loaded.find { |t| t.name.downcase == kw_down }
      match ||= candidates.find { |t| t.name.downcase == kw_down }
      match ||= candidates.find { |t| t.keywords.to_s.downcase.include?(kw_down) }
      map[keyword] = match
    end
  end

  # 교차 연결 (topic_slug 기반 Association)
  has_many :guides,      foreign_key: :topic_slug, primary_key: :slug, dependent: :nullify
  has_many :audit_cases, foreign_key: :topic_slug, primary_key: :slug, dependent: :nullify

  # 관련 감사사례 (DB 기반)
  def related_audit_cases
    AuditCase.published.where(topic_slug: slug).recent
  end

  # FAQ 배열로 반환 (jsonb는 이미 Array, 레거시 String은 JSON.parse)
  def faq_list
    return [] if faqs.blank?
    return faqs if faqs.is_a?(Array)
    JSON.parse(faqs)
  rescue JSON::ParserError => e
    Rails.logger.warn "[Topic#faq_list] JSON 파싱 실패 (id=#{id}): #{e.message}"
    []
  end

  # 법령 3단 데이터가 있는지
  def has_law_content?
    law_content.present? || decree_content.present? || rule_content.present?
  end

  # 카테고리 목록
  CATEGORIES = {
    "contract" => "계약",
    "budget" => "예산/결산",
    "expense" => "지출",
    "salary" => "급여/수당",
    "subsidy" => "보조금",
    "property" => "공유재산",
    "travel" => "여비/출장",
    "duty" => "복무",
    "other" => "기타"
  }.freeze

  def category_name
    CATEGORIES[category] || category
  end

  private

  def update_law_verified_at
    self.law_verified_at = Time.current
    self.law_base_date = Time.zone.today.strftime("%Y.%m.%d")
  end

  def notify_indexnow
    SitemapPingJob.perform_later([ "https://#{SitemapPingJob::HOST}/topics/#{slug}" ])
  end

  def expire_count_cache
    Rails.cache.delete("stats/topic_count")
    Rails.cache.delete("topics/all_published_v2")
    Rails.cache.delete("topic_related/#{slug}")
    Rails.cache.delete("topic_audit_cases/#{slug}")
    Rails.cache.delete("topic_keyword_map/#{slug}")
    # Sprint B Phase 1 — RelatedContentResolver 캐시 무효화
    Rails.cache.delete("related_content_v2/#{slug}/topics")
    Rails.cache.delete("related_content_v2/#{slug}/audit_cases")
    Rails.cache.delete("related_content_v2/#{slug}/guides")
    # 부모 토픽의 keyword_map도 무효화 (서브토픽 변경 시 부모 키워드 매핑에 영향)
    Rails.cache.delete("topic_keyword_map/#{parent&.slug}") if parent_id.present?
    # 뷰 fragment cache 무효화: 토픽 내용 변경 시 버전 증가 → 캐시 키가 달라져 자연 무효화
    if saved_change_to_name? || saved_change_to_summary? || saved_change_to_published? || saved_change_to_category? || saved_change_to_sector?
      Rails.cache.increment("topics/fragment_version")
      # 홈 큐레이션 캐시 버전 무효화 (sector별 홈화면 캐시)
      Rails.cache.increment("home/curated_version")
    end
  end

  def generate_slug
    self.slug = name.parameterize.presence || "topic-#{SecureRandom.hex(4)}"
  end

  # slug 변경 시 연관 레코드의 topic_slug를 일괄 업데이트 (orphan 방지)
  def cascade_slug_change
    old_slug = slug_was
    new_slug = slug
    Guide.where(topic_slug: old_slug).update_all(topic_slug: new_slug)
    AuditCase.where(topic_slug: old_slug).update_all(topic_slug: new_slug)
    TopicComment.where(topic_slug: old_slug).update_all(topic_slug: new_slug)
    # 구 slug 기반 캐시 무효화 (update_all은 콜백을 건너뛰므로 수동 처리)
    Rails.cache.delete("topic_related/#{old_slug}")
    Rails.cache.delete("topic_audit_cases/#{old_slug}")
    Rails.cache.delete("topic_keyword_map/#{old_slug}")
    Rails.cache.delete("audit_cases/all_published_v2")
    Rails.cache.delete("guides/all")
    # Sprint B Phase 1 — RelatedContentResolver 캐시 무효화
    [ "topics", "audit_cases", "guides" ].each do |kind|
      Rails.cache.delete("related_content_v2/#{old_slug}/#{kind}")
      Rails.cache.delete("related_content_v2/#{new_slug}/#{kind}")
    end
    # 301 리디렉션 레코드 생성 (Search Console 404 방지)
    SlugRedirect.upsert(
      { old_slug: old_slug, new_slug: new_slug, resource_type: "Topic", created_at: Time.current, updated_at: Time.current },
      unique_by: [ :old_slug, :resource_type ]
    )
    Rails.logger.info "[Topic] slug 변경: #{old_slug} → #{new_slug} (연쇄 업데이트 + 리디렉션 등록 완료)"
  end
end
