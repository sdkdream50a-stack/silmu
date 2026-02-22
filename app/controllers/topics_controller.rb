class TopicsController < ApplicationController
  # 토픽별 관련 도구 매핑 (slug → 도구 목록)
  # 각 도구: { path_name:, icon:, title:, desc:, color: }
  TOPIC_TOOLS = {
    "private-contract"        => [:contract_method, :contract_documents, :contract_reason, :quote_review],
    "private-contract-limit"  => [:contract_method, :contract_reason],
    "private-contract-amount" => [:contract_method, :estimated_price],
    "private-contract-overview" => [:contract_method, :contract_documents, :contract_reason],
    "single-quote"            => [:contract_method, :contract_documents, :quote_review, :contract_reason],
    "dual-quote"              => [:contract_method, :contract_documents, :quote_review],
    "emergency-contract"      => [:contract_method, :contract_documents, :contract_reason],
    "price-negotiation"       => [:contract_method, :cost_estimate, :contract_documents],
    "bidding"                 => [:contract_method, :estimated_price, :legal_period, :quote_review],
    "bid-announcement"        => [:estimated_price, :legal_period],
    "e-bidding"               => [:contract_method, :estimated_price, :contract_documents],
    "e-procurement-guide"     => [:contract_method, :contract_documents],
    "contract-execution"      => [:contract_method, :contract_documents, :contract_guarantee, :cost_estimate],
    "contract-guarantee-deposit" => [:contract_guarantee, :contract_documents],
    "estimated-price"         => [:estimated_price, :cost_estimate, :budget_estimator],
    "inspection"              => [:progress_inspection, :contract_documents],
    "payment"                 => [:progress_inspection, :contract_documents],
    "design-change"           => [:design_change, :progress_inspection],
    "price-escalation"        => [:design_change, :estimated_price],
    "late-penalty"            => [:contract_documents],
    "defect-warranty"         => [:contract_documents, :progress_inspection],
    "contract-termination"    => [:contract_documents],
    "joint-contract"          => [:contract_method, :contract_documents],
    "subcontract"             => [:contract_documents],
    "goods-selection-committee" => [:contract_method, :contract_documents, :quote_review],
    "travel-expense"          => [:travel_calculator],
    "budget-carryover"        => [:budget_estimator],
    "year-end-settlement"     => [],
    # 2026-02-18 추가
    "advance-payment"         => [:contract_documents, :progress_inspection],
    "bid-qualification"       => [:contract_method, :estimated_price],
    "bid-deposit"             => [:contract_method, :contract_documents],
    "long-term-contract"      => [:contract_method, :contract_documents],
    "unit-price-contract"     => [:contract_method, :contract_documents],
    "spec-price-split-bid"    => [:contract_method, :estimated_price],
    "performance-guarantee"   => [:contract_guarantee, :contract_documents],
    "multiple-price"          => [:estimated_price, :legal_period],
  }.freeze

  # 토픽별 개별 아이콘 매핑
  TOPIC_ICONS = {
    "private-contract"           => "handshake",
    "private-contract-overview"  => "handshake",
    "private-contract-limit"     => "rule",
    "private-contract-amount"    => "calculate",
    "single-quote"               => "person",
    "dual-quote"                 => "group",
    "emergency-contract"         => "emergency",
    "price-negotiation"          => "forum",
    "bidding"                    => "gavel",
    "bid-announcement"           => "campaign",
    "e-bidding"                  => "computer",
    "e-procurement-guide"        => "shopping_cart",
    "contract-execution"         => "description",
    "contract-guarantee-deposit" => "security",
    "estimated-price"            => "calculate",
    "inspection"                 => "fact_check",
    "payment"                    => "payments",
    "design-change"              => "edit_note",
    "price-escalation"           => "trending_up",
    "late-penalty"               => "schedule",
    "defect-warranty"            => "verified_user",
    "contract-termination"       => "cancel",
    "joint-contract"             => "groups",
    "subcontract"                => "account_tree",
    "goods-selection-committee"  => "inventory_2",
    "travel-expense"             => "flight_takeoff",
    "year-end-settlement"        => "receipt_long",
    "budget-carryover"           => "savings",
    # 2026-02-18 추가
    "advance-payment"            => "payments",
    "bid-qualification"          => "fact_check",
    "bid-deposit"                => "lock",
    "long-term-contract"         => "event_repeat",
    "unit-price-contract"        => "price_change",
    "spec-price-split-bid"       => "call_split",
    "performance-guarantee"      => "verified",
    "multiple-price"             => "format_list_numbered",
  }.freeze

  TOOL_DEFINITIONS = {
    contract_method:   { icon: "gavel",        title: "계약방식 결정",   desc: "금액 입력 → 방식 바로 확인", color: "emerald" },
    contract_documents:{ icon: "fact_check",   title: "서류 체크리스트", desc: "필요 서류 원클릭 생성",       color: "indigo" },
    contract_reason:   { icon: "description",  title: "계약사유서 작성", desc: "수의계약 사유서 자동 작성",   color: "violet" },
    quote_review:      { icon: "receipt_long", title: "견적서 검토",     desc: "견적서 적정성 자동 분석",     color: "amber" },
    estimated_price:   { icon: "calculate",    title: "추정가격 계산기", desc: "부가세 포함 추정가격 산출",   color: "blue" },
    cost_estimate:     { icon: "attach_money", title: "원가계산서",      desc: "원가 항목별 자동 계산",       color: "teal" },
    budget_estimator:  { icon: "account_balance", title: "소요예산 추정", desc: "대략적인 예산 미리 산출",    color: "slate" },
    contract_guarantee:{ icon: "security",     title: "계약보증금 계산", desc: "보증금 요율 자동 계산",       color: "rose" },
    progress_inspection:{ icon: "engineering", title: "기성검사 체크",   desc: "기성·준공 검사 항목 확인",    color: "orange" },
    design_change:     { icon: "edit_note",    title: "설계변경 계산",   desc: "변경 금액 자동 산출",         color: "purple" },
    legal_period:      { icon: "calendar_today", title: "법정기간 계산", desc: "입찰공고 기간 자동 산출",     color: "sky" },
    travel_calculator: { icon: "flight_takeoff", title: "여비계산기",    desc: "출장 여비 자동 계산",         color: "rose" },
  }.freeze

  def index
    all_topics = Topic.published.to_a
    @topics_by_category = all_topics.group_by(&:category)

    # 계약 카테고리: 논리적 순서로 정렬 (수의계약 → 입찰 → 계약체결 → 보증금 → 이행 → 변경/종료)
    contract_order = %w[
      private-contract private-contract-limit private-contract-amount
      single-quote dual-quote quote-collection-guide
      price-negotiation emergency-contract small-amount-contract split-contract-prohibition
      bidding bid-announcement e-bidding estimated-price multiple-price
      lowest-bid-rate bid-qualification spec-price-split-bid goods-selection-committee
      contract-execution e-procurement-guide unit-price-contract long-term-contract
      joint-contract subcontract
      contract-guarantee-deposit bid-deposit performance-guarantee defect-warranty
      inspection payment advance-payment late-penalty
      design-change price-escalation contract-termination
    ]

    if @topics_by_category["contract"]
      @topics_by_category["contract"] = @topics_by_category["contract"].sort_by do |topic|
        idx = contract_order.index(topic.slug)
        idx ? idx : 999 # 순서에 없는 토픽은 맨 뒤로
      end
    end

    @total_count = all_topics.size

    # HTTP 캐싱: CDN/브라우저에서 5분간 캐시, stale-while-revalidate로 백그라운드 갱신
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_meta_tags(
      title: "법령 가이드 — 주요 법령·절차 완벽 정리",
      description: "수의계약, 경쟁입찰, 계약체결, 대금지급 등 공무원이 꼭 알아야 할 계약·예산 관련 주요 법령을 쉽고 정확하게 안내합니다.",
      keywords: "법령가이드, 수의계약, 경쟁입찰, 계약체결, 지방계약법, 공무원 법령",
      og: {
        title: "법령 가이드 | 실무.kr",
        description: "수의계약·경쟁입찰·계약체결 등 주요 법령을 법률→시행령→규칙 체계로 정리",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def show
    @topic = Topic.find_by!(slug: params[:slug])
    @topic.increment_view!
    @related_topics = Rails.cache.fetch("topic_related/#{@topic.slug}", expires_in: 1.hour) do
      @topic.related_topics.to_a
    end
    @related_guide = Rails.cache.fetch("topic_guide/#{@topic.slug}", expires_in: 1.hour) do
      Guide.published.find_by(external_link: "/topics/#{@topic.slug}")
    end
    @related_articles = Rails.cache.fetch("cafe_articles/similar/#{@topic.slug}", expires_in: 6.hours) do
      CafeArticle.find_similar(@topic.name, limit: 10).to_a
    end
    @related_audit_cases = Rails.cache.fetch("topic_audit_cases/#{@topic.slug}", expires_in: 1.hour) do
      @topic.related_audit_cases.to_a
    end
    @audit_case_total = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }

    # 부모 토픽인 경우 키워드별 매칭 토픽을 미리 조회 (N+1 방지)
    @keyword_topic_map = @topic.parent_id.nil? ? @topic.keyword_topic_map : {}

    # 서브토픽인 경우: 부모와 형제 토픽을 미리 로드 (뷰에서 DB 쿼리 방지)
    if @topic.parent_id.present?
      @parent_topic = @topic.parent
      @sibling_topics = @parent_topic.subtopics.published.where.not(id: @topic.id).to_a
    end

    # 키워드 파라미터가 있으면 해당 키워드 섹션 표시
    @active_keyword = params[:keyword]

    # 토픽별 관련 도구 (3단계: 도구 카드)
    tool_keys = TOPIC_TOOLS[@topic.slug] || [:contract_method, :contract_documents]
    @related_tools = tool_keys.map { |k| TOOL_DEFINITIONS[k]&.merge(key: k) }.compact
    @page_rendered_at = Time.current

    # SEO 메타 태그
    set_meta_tags(
      title: "#{@topic.name} — 법령·절차·실무 가이드",
      description: generate_seo_description(@topic),
      keywords: @topic.keywords,
      canonical: canonical_url,
      og: {
        title: "#{@topic.name} 실무 가이드 | 실무.kr",
        description: generate_seo_description(@topic, 200),
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "article"
      }
    )
  end

  private

  # SEO description 생성: commentary가 있으면 commentary 사용 (150자 이상 보장)
  def generate_seo_description(topic, length = 155)
    if topic.commentary.present?
      # commentary에서 HTML 태그 제거 후 앞부분 사용
      ActionView::Base.full_sanitizer.sanitize(topic.commentary)
        .gsub(/\s+/, ' ')
        .strip
        .truncate(length)
    else
      # commentary가 없으면 summary 사용
      topic.summary.truncate(length)
    end
  end
end
