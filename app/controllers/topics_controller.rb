class TopicsController < ApplicationController
  include TopicConfig

  # 카테고리 키 → OG 이미지 카테고리 매핑
  OG_CATEGORY_MAP = {
    "contract"  => "contract",
    "budget"    => "budget",
    "expense"   => "expense",
    "salary"    => "salary",
    "subsidy"   => "subsidy",
    "property"  => "property",
    "travel"    => "travel",
    "duty"      => "duty"
  }.freeze

  def index
    all_topics = Rails.cache.fetch("topics/all_published_v2", expires_in: 30.minutes) do
      Topic.published.to_a
    end

    # 카테고리별 토픽 수 + 대표 토픽 3개 + 실무 자산 집계 (허브 페이지용)
    @hub_categories = CATEGORY_ORDER.filter_map do |key|
      topics = all_topics.select { |t| t.category == key }
      next if topics.empty?
      slugs = topics.map(&:slug)
      flowchart_count = slugs.count { |s| FLOWCHART_SLUGS.include?(s) }
      tool_count = slugs.sum { |s| (TOPIC_TOOLS[s] || []).size }
      { key: key, cfg: CATEGORY_CONFIG[key], count: topics.size, preview: topics.first(3),
        flowchart_count: flowchart_count, tool_count: tool_count, topics: topics }
    end
    @total_count = all_topics.size

    # 카테고리별 fragment cache 키로 활용 가능한 버전 힌트
    @fragment_version = Rails.cache.read("topics/fragment_version") || 0

    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_meta_tags(
      title: "법령 가이드 — 주요 법령·절차 완벽 정리",
      description: "수의계약, 경쟁입찰, 계약체결, 대금지급 등 공무원이 꼭 알아야 할 계약·예산 관련 주요 법령을 쉽고 정확하게 안내합니다.",
      keywords: "법령가이드, 수의계약, 경쟁입찰, 계약체결, 지방계약법, 공무원 법령",
      og: {
        title: "법령 가이드 | 실무.kr",
        description: "수의계약·경쟁입찰·계약체결 등 주요 법령을 법률→시행령→규칙 체계로 정리",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp",
        type: "website"
      },
      canonical: canonical_url
    )
  end

  def category
    @key = params[:key]
    @cfg = CATEGORY_CONFIG[@key]
    return redirect_to topics_path, status: :moved_permanently unless @cfg

    all_topics = Rails.cache.fetch("topics/all_published_v2", expires_in: 30.minutes) do
      Topic.published.to_a
    end
    raw_topics = all_topics.select { |t| t.category == @key }
    @topics = sort_topics_for_category(@key, raw_topics)

    if @key == "contract"
      @contract_subgroups = build_contract_subgroups(@topics)
      @current_subgroup = params[:subgroup].presence
    end

    # 카테고리별 fragment cache 키로 활용 가능한 버전 힌트
    @fragment_version = Rails.cache.read("topics/fragment_version") || 0

    # 서브그룹 필터 URL은 중복 색인 방지
    @meta_robots = params[:subgroup].present? ? "noindex, follow" : nil

    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_og_image(category: OG_CATEGORY_MAP[@key])
    set_meta_tags(
      title: "#{@cfg[:label]} 법령 가이드 — 실무.kr",
      description: "#{@cfg[:desc]} 관련 주요 법령을 법률→시행령→규칙 체계로 정리합니다.",
      keywords: "#{@cfg[:label]}, 법령가이드, #{@cfg[:desc]}",
      canonical: canonical_url,
      og: {
        title: "#{@cfg[:label]} 법령 가이드 | 실무.kr",
        description: "#{@cfg[:desc]} 관련 주요 법령을 법률→시행령→규칙 체계로 정리합니다.",
        url: canonical_url,
        type: "website"
      }
    )
  end

  def show
    # parent를 미리 로드하여 @topic.parent 접근 시 추가 쿼리 방지
    @topic = Topic.includes(:parent).find_by(slug: params[:slug])

    # 슬러그 변경된 경우 301 리디렉션 (Search Console 404 해소)
    unless @topic
      new_slug = SlugRedirect.resolve(params[:slug], "Topic")
      if new_slug
        redirect_to topic_path(new_slug), status: :moved_permanently
        return
      end
      raise ActiveRecord::RecordNotFound
    end
    @topic.increment_view!
    # 같은 카테고리의 다른 토픽 (현재 토픽 제외, 최대 6개)
    @related_topics = Rails.cache.fetch("topic_related_list/#{@topic.slug}", expires_in: 1.hour) do
      Topic.published
           .where(category: @topic.category)
           .where.not(slug: @topic.slug)
           .limit(6)
           .to_a
    end
    @related_guide = Rails.cache.fetch("topic_guide/#{@topic.slug}", expires_in: 1.hour) do
      Guide.published.find_by(topic_slug: @topic.slug) ||
        Guide.published.find_by(external_link: "/topics/#{@topic.slug}")
    end
    # [LCP 최적화] @related_articles 제거 — 뷰에서 미사용 (불필요한 DB 쿼리 + 캐시 제거)
    @related_audit_cases = Rails.cache.fetch("topic_audit_cases/#{@topic.slug}", expires_in: 1.hour) do
      @topic.related_audit_cases.to_a
    end
    @audit_case_total = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }

    # Sprint #2-D — feedback up 카운트 (Krug 사회적 증거, 5건 미만은 노출 X)
    @topic_helpful_count = Rails.cache.fetch("topic_helpful/#{@topic.slug}", expires_in: 30.minutes) do
      TopicFeedback.up.where(topic_slug: @topic.slug).count
    end

    # 법제처 API — 토픽별 법령 원문 참조 링크 (7일 캐시)
    # [LCP 최적화] 캐시 miss 시 API를 동기 호출하지 않고 백그라운드 워밍 → 페이지 렌더 블로킹 방지
    # [중복 방지] unless_exist: true로 동시 요청 시 job 하나만 enqueue
    cached_refs = Rails.cache.read("topic_law_refs/v1/#{@topic.slug}")
    if cached_refs.nil?
      flag_key = "law_ref_warming/#{@topic.slug}"
      if Rails.cache.write(flag_key, true, expires_in: 5.minutes, unless_exist: true)
        LawReferenceWarmJob.perform_later(@topic.slug)
      end
      @law_references = {}
    else
      @law_references = cached_refs
    end

    # 플로차트 존재 여부 (P1-1: 플로차트 없으면 기본 탭을 '법령 내용'으로 변경)
    @has_flowchart = FLOWCHART_SLUGS.include?(@topic.slug)

    # 부모 토픽인 경우 키워드별 매칭 토픽을 미리 조회 (캐시로 2쿼리 제거)
    @keyword_topic_map = if @topic.parent_id.nil?
      Rails.cache.fetch("topic_keyword_map/#{@topic.slug}", expires_in: 1.hour) do
        @topic.keyword_topic_map
      end
    else
      {}
    end

    # 서브토픽인 경우: 부모와 형제 토픽을 미리 로드 (뷰에서 DB 쿼리 방지)
    if @topic.parent_id.present?
      @parent_topic = @topic.parent
      @sibling_topics = @parent_topic.subtopics.published.where.not(id: @topic.id).to_a
    end

    # 키워드 파라미터가 있으면 해당 키워드 섹션 표시
    @active_keyword = params[:keyword]

    # 토픽별 관련 도구 (3단계: 도구 카드)
    tool_keys = TOPIC_TOOLS[@topic.slug] || [ :contract_method, :contract_documents ]
    @related_tools = tool_keys.map { |k| TOOL_DEFINITIONS[k]&.merge(key: k) }.compact
    @page_rendered_at = Time.current

    # AGO 2026 — AI 크롤러용 마크다운 alternative (`/topics/:slug.md`)
    if request.format.md?
      expires_in 1.hour, public: true
      render plain: render_topic_markdown(@topic), content_type: "text/markdown; charset=utf-8"
      return
    end

    # 5차 권위자 AGO #19 — HTTP Link 헤더로 .md alternate 노출 (curl·봇 친화)
    md_url = "#{canonical_url}.md"
    response.set_header("Link", %Q(<#{md_url}>; rel="alternate"; type="text/markdown"))

    # HTTP 캐싱: 토픽 상세 페이지 (view_count 업데이트는 DB만 영향, 응답 캐시 가능)
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    # SEO 메타 태그
    set_og_image(category: OG_CATEGORY_MAP[@topic.category])
    # GEO/AEO 2026 권고 — article 메타 풍부화 (Facebook·카톡 공유 + 검색엔진 article 신호)
    article_modified_at = (@topic.law_verified_at.presence || @topic.updated_at).iso8601
    # keywords는 "수의계약, 1인견적, 2인 이상 견적" 형식 — 콤마로만 split (공백 split 시 복합어 깨짐)
    article_tags = @topic.keywords.to_s.split(",").map(&:strip).reject(&:blank?).first(10)
    seo_title    = "#{@topic.name} — #{topic_law_reference(@topic)} 근거·절차·실무사례 완전정리"
    og_title     = "#{@topic.name} 실무 가이드 | 실무.kr"
    og_desc      = generate_seo_description(@topic, 200)
    set_meta_tags(
      title: seo_title,
      description: generate_seo_description(@topic),
      keywords: @topic.keywords,
      canonical: canonical_url,
      og: {
        title: og_title,
        description: og_desc,
        url: canonical_url,
        type: "article",
        article: {
          published_time: @topic.created_at.iso8601,
          modified_time: article_modified_at,
          section: @topic.category_name,
          tag: article_tags
        }
      },
      # Twitter Card 명시 (OG 폴백 없음)
      twitter: { title: og_title, description: og_desc }
    )
  end

  private

  # 카테고리별 토픽 정렬 (계약은 논리적 순서, 나머지는 그대로)
  def sort_topics_for_category(key, topics)
    return topics unless key == "contract"

    contract_order = %w[
      private-contract private-contract-limit private-contract-amount
      single-quote dual-quote quote-collection-guide private-contract-justification
      price-negotiation emergency-contract small-amount-contract split-contract-prohibition
      bidding bid-announcement e-bidding estimated-price multiple-price
      lowest-bid-rate bid-qualification spec-price-split-bid goods-selection-committee
      bid-participation-restriction qualification-failure e-bidding-error-faq
      contract-execution e-procurement-guide unit-price-contract long-term-contract
      joint-contract subcontract goods-vs-service-contract
      contract-guarantee-deposit bid-deposit performance-guarantee defect-warranty
      contract-guarantee-exemption
      inspection payment advance-payment late-penalty
      penalty-reduction-procedure completion-payment-checklist
      design-change price-escalation contract-termination
      additional-contract-limit contract-period-extension contract-amount-adjustment
    ]
    topics.sort_by { |t| contract_order.index(t.slug) || 999 }
  end

  def build_contract_subgroups(contract_topics)
    return [] if contract_topics.blank?

    slug_to_topic = contract_topics.index_by(&:slug)
    subgroup_id_slugs = CONTRACT_SUBGROUP_DEFS.map { |d| d[:id] }.to_set

    CONTRACT_SUBGROUP_DEFS.filter_map do |defn|
      group_topics = defn[:slugs].filter_map { |s| slug_to_topic.delete(s) }
      next if group_topics.empty?

      defn.merge(topics: group_topics)
    end.tap do |groups|
      # 매핑되지 않은 토픽 중 서브그룹 개요 토픽(id와 slug가 같은 것)은 제외
      remaining = slug_to_topic.values.reject { |t| subgroup_id_slugs.include?(t.slug) }
      groups.last[:topics].concat(remaining) if remaining.any? && groups.any?
    end
  end

  # 토픽 카테고리에 따라 적절한 법령 참조 문구를 반환
  def topic_law_reference(topic)
    case topic.category
    when "travel", "duty", "salary" then "공무원 법령"
    when "subsidy" then "보조금 관리법"
    when "property" then "공유재산법"
    else
      topic.sector == "edu" ? "교육재정 법령" : "지방계약법"
    end
  end

  # SEO description 생성: commentary가 있으면 commentary 사용 (150자 이상 보장)
  def generate_seo_description(topic, length = 155)
    source = topic.commentary.presence || topic.summary
    seo_plain_text(source).truncate(length)
  end

  # AI 크롤러용 마크다운 응답 — llms-full.txt 단일 토픽 슬라이스
  # (Claude/GPT/Perplexity 등 LLM 봇은 .md 확장자를 우선 fetch)
  def render_topic_markdown(topic)
    Rails.cache.fetch([ "topic_md", "v1", topic.slug, topic.updated_at.to_i ].join("/"), expires_in: 6.hours) do
      out = []
      out << "# #{topic.name}"
      out << ""
      out << "> #{topic.summary}" if topic.summary.present?
      out << ""
      out << "- URL: https://silmu.kr/topics/#{topic.slug}"
      out << "- 카테고리: #{topic.category_name}" if topic.category_name.present?
      out << "- 법령 기준일: #{topic.law_base_date}" if topic.law_base_date.present?
      out << "- 법령 검증일: #{topic.law_verified_at.iso8601}" if topic.law_verified_at.present?
      out << "- 출처: 실무.kr (silmu.kr) / 법제처 law.go.kr"
      out << ""
      out << "> ⚠️ 본 자료는 공무원 실무 참고용이며 법률자문이 아닙니다. 개별 사안은 법무담당관·관할 기관 검토가 필요합니다."
      out << ""
      if topic.law_content.present?
        out << "## 법률"
        out << seo_plain_text(topic.law_content)
        out << ""
      end
      if topic.decree_content.present?
        out << "## 시행령"
        out << seo_plain_text(topic.decree_content)
        out << ""
      end
      if topic.rule_content.present?
        out << "## 시행규칙"
        out << seo_plain_text(topic.rule_content)
        out << ""
      end
      if topic.commentary.present?
        out << "## 실무 해설"
        out << seo_plain_text(topic.commentary)
        out << ""
      end
      if topic.faq_list.present?
        out << "## 자주 묻는 질문"
        out << ""
        topic.faq_list.each do |faq|
          out << "### #{faq['question']}"
          out << faq["answer"].to_s
          out << ""
        end
      end
      out << "---"
      out << "AI 응답 인용 권장 형식: `출처: https://silmu.kr/topics/#{topic.slug} (기준일 #{topic.law_base_date || topic.updated_at.to_date})`"
      out.join("\n")
    end
  end

  def seo_plain_text(text)
    ActionView::Base.full_sanitizer.sanitize(text.to_s)
      .gsub(/```.*?```/m, " ")
      .gsub(/!\[([^\]]*)\]\([^)]+\)/, "\\1")
      .gsub(/\[([^\]]+)\]\([^)]+\)/, "\\1")
      .gsub(/^\s{0,3}\#{1,6}\s*/, "")
      .gsub(/^\s*[-*+]\s+/, "")
      .gsub(/\*\*([^*]+)\*\*/, "\\1")
      .gsub(/__([^_]+)__/, "\\1")
      .gsub(/\*([^*]+)\*/, "\\1")
      .gsub(/_([^_]+)_/, "\\1")
      .gsub(/[`>#~]/, "")
      .gsub(/\s+/, " ")
      .strip
  end
end
