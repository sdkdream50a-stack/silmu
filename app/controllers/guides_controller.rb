class GuidesController < ApplicationController
  # 가이드 카테고리 → OG 이미지 카테고리 매핑
  GUIDE_OG_CATEGORY_MAP = {
    "contract"  => "contract",
    "budget"    => "budget",
    "expense"   => "expense",
    "salary"    => "salary",
    "subsidy"   => "subsidy",
    "property"  => "property",
    "travel"    => "travel",
    "duty"      => "duty",
    "audit"     => "audit",
    "tools"     => "tools"
  }.freeze
  def index
    @guides            = Rails.cache.fetch("guides/all/v2", expires_in: 1.hour) { Guide.published.ordered.to_a }
    @popular_guides    = Rails.cache.fetch("guides/popular", expires_in: 1.hour) { Guide.published.order(view_count: :desc).limit(5).to_a }
    @audit_case_count  = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }

    # "최근 본 가이드": 이미 캐시된 @guides에서 찾기 → DB 쿼리 제거 + public 캐시 항상 활성화
    recent_slugs = JSON.parse(cookies[:recent_guides] || "[]") rescue []
    if recent_slugs.any?
      guides_by_slug = @guides.index_by(&:slug)
      @recent_guides = recent_slugs.filter_map { |slug| guides_by_slug[slug] }
    else
      @recent_guides = []
    end

    # 시리즈 그룹핑 (series 있는 가이드만)
    series_guides = @guides.select { |g| g.series.present? }
    @series_groups = series_guides.group_by(&:series).transform_values { |gs| gs.sort_by(&:series_order) }

    # 뷰 헤더용 통계: 시리즈 제외한 일반 가이드만 카테고리 분류
    non_series = @guides.reject { |g| g.series.present? }
    grouped = non_series.group_by(&:category)
    top = grouped.max_by { |_, v| v.size }
    @top_category, @top_category_count = top ? [top[0], top[1].size] : [nil, 0]
    @category_count = grouped.keys.size
    @guide_categories = grouped.keys

    # HTTP 캐싱: DB 쿼리가 없으므로 항상 public 캐시 가능
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    canonical_url = request.original_url.split("?").first
    description_text = "물품 구매·수의계약·적격심사·검수·예정가격·여비 등 공무원 계약·예산 업무를 현행 법령 기준으로 단계별 안내합니다. 체크리스트·서식 템플릿·자동화 계산기와 함께 업무 정확도를 높이고 감사 지적 위험을 줄이세요. 지자체·교육청 계약 담당자를 위한 무료 실무 가이드 모음입니다."
    meta = {
      title: "공무원 계약·예산 업무 가이드 — 물품구매·검수·여비 단계별 안내",
      description: description_text,
      keywords: "업무 가이드, 물품 구매, 검수조서, 예정가격, 수의계약, 여비, 연가",
      og: {
        title: "업무 가이드 — 실무.kr",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp"
      },
      canonical: canonical_url
    }
    meta[:robots] = "noindex, follow" if params[:category].present?
    set_meta_tags(meta)
  end

  def show
    @guide = Guide.published.find_by(slug: params[:slug])

    unless @guide
      new_slug = SlugRedirect.resolve(params[:slug], "Guide")
      if new_slug
        redirect_to guide_path(new_slug), status: :moved_permanently
        return
      end
      raise ActiveRecord::RecordNotFound
    end

    # full content 없이 external_link만 있는 가이드는 해당 페이지로 리디렉트
    if @guide.external_link.present? && !@guide.has_full_content?
      @guide.increment_view!
      redirect_to @guide.external_link, status: :moved_permanently
      return
    end

    @guide.increment_view!

    # 최근 본 가이드 쿠키 업데이트 (최대 5개)
    recent = JSON.parse(cookies[:recent_guides] || "[]") rescue []
    recent = ([  @guide.slug] + recent).uniq.first(5)
    cookies[:recent_guides] = { value: recent.to_json, expires: 30.days, same_site: :lax }

    # topic_slug 필드로 연결된 Topic 우선, 없으면 external_link 기반 폴백 (캐시로 DB 쿼리 제거)
    @related_topic = Rails.cache.fetch("guide_topic/#{@guide.slug}", expires_in: 1.hour) do
      if @guide.topic_slug.present?
        Topic.published.find_by(slug: @guide.topic_slug)
      elsif @guide.external_link&.start_with?("/topics/")
        Topic.published.find_by(slug: @guide.external_link.delete_prefix("/topics/"))
      end
    end

    # 시리즈 네비게이션 (series 설정된 가이드만)
    if @guide.series.present?
      @series_guides = Rails.cache.fetch("guides/series/#{@guide.series}", expires_in: 1.hour) do
        Guide.published.where(series: @guide.series).order(series_order: :asc).to_a
      end
      current_idx = @series_guides.index { |g| g.id == @guide.id }
      @prev_guide = (current_idx && current_idx > 0) ? @series_guides[current_idx - 1] : nil
      @next_guide = current_idx ? @series_guides[current_idx + 1] : nil
    end

    @related_guides = Rails.cache.fetch("guides/related/#{@guide.slug}", expires_in: 1.hour) do
      same_cat = Guide.published.where(category: @guide.category).where.not(id: @guide.id).ordered.limit(2).to_a
      fill     = [3 - same_cat.size, 0].max
      others   = fill > 0 ? Guide.published.where.not(category: @guide.category).where.not(id: @guide.id).ordered.limit(fill).to_a : []
      same_cat + others
    end

    # HTTP 캐싱: 가이드 상세 (view_count 업데이트는 DB만 영향)
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    canonical_url = request.original_url.split("?").first
    # description 보강: guide.description + sections[:why_it_matters] 조합으로 120자+ 달성
    desc_parts = [ @guide.description.to_s ]
    if @guide.sections.present?
      why = @guide.sections[:why_it_matters].to_s.presence
      desc_parts << why if why
    end
    rich_desc = desc_parts.join(" ").truncate(155)

    set_og_image(category: GUIDE_OG_CATEGORY_MAP[@guide.category])
    set_meta_tags(
      title: @guide.title,
      description: rich_desc,
      keywords: "#{@guide.category}, #{@guide.title}, 공무원 실무",
      og: {
        title: @guide.title,
        description: rich_desc,
        url: canonical_url
      },
      canonical: canonical_url
    )
  rescue ActiveRecord::RecordNotFound
    redirect_to guides_path, alert: "가이드를 찾을 수 없습니다."
  end

  # 감사 빈출 지적 TOP 30 가이드
  def audit_frequent_issues
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "감사 빈출 지적 TOP 30 — 계약·예산·인사·보조금 분야별 정리",
      description: "감사원·지자체 감사에서 가장 자주 지적되는 사항 30가지를 분야별로 정리했습니다. 계약·예산·인사·보조금 담당자가 실수하기 쉬운 항목과 예방법을 한 페이지에서 확인하세요.",
      keywords: "감사 빈출 지적,감사원 지적,계약 감사,예산 감사,보조금 감사,감사 대비,공무원 감사",
      og: {
        title: "감사 빈출 지적 TOP 30 — 실무.kr",
        description: "계약·예산·인사·보조금 분야 감사 빈출 지적사항 30가지와 예방법을 한 페이지에서 확인하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp",
        type: "website"
      },
      canonical: canonical_url
    )
  end

  # 국가계약 vs 지방계약 비교 가이드
  def national_vs_local_contract
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "국가계약 vs 지방계약 비교 — 핵심 차이점 한눈에 보기",
      description: "국가계약법과 지방계약법의 핵심 차이를 15개 항목별로 비교 정리했습니다. 수의계약 한도, 입찰 절차, 계약보증금, 지체상금 등 담당자가 혼동하기 쉬운 부분을 명확히 구분하세요.",
      keywords: "국가계약법,지방계약법,국가계약 지방계약 차이,계약법 비교,지방자치단체 계약,국가기관 계약",
      og: {
        title: "국가계약 vs 지방계약 비교 — 실무.kr",
        description: "국가계약법·지방계약법 핵심 차이 15개 항목 비교. 수의계약 한도·입찰·보증금·지체상금 구분.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp",
        type: "website"
      },
      canonical: canonical_url
    )
  end

  # 계약 흐름도 페이지
  def contract_flow
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "계약 흐름도 — 공무원 계약 업무 전 과정 시각화",
      description: "계획 수립부터 대금 지급까지 공무원 계약 업무의 전체 프로세스를 단계별 흐름도로 한눈에 파악하세요. 수의계약·경쟁입찰·협상계약 등 계약 방식별 절차와 핵심 체크포인트를 시각적으로 정리했습니다.",
      og: {
        title: "계약 흐름도 — 공무원 계약 업무 전 과정 시각화",
        description: "계획 수립부터 대금 지급까지 공무원 계약 업무의 전체 프로세스를 단계별 흐름도로 한눈에 파악하세요. 수의계약·경쟁입찰·협상계약 등 계약 방식별 절차와 핵심 체크포인트를 시각적으로 정리했습니다.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp",
        type: "website"
      },
      canonical: canonical_url
    )
  end

  # 계약업무 사전 체크리스트
  def pre_contract_checklist
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "계약업무 사전 체크리스트",
      description: "계약 체결 전 반드시 확인해야 할 사항을 체크리스트로 정리했습니다.",
      og: {
        title: "계약업무 사전 체크리스트 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp"
      },
      canonical: canonical_url
    )
  end

  # 자료실/FAQ
  def resources
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "공공계약 판례·유권해석·FAQ 모음",
      description: "수의계약·입찰·계약이행 관련 대법원 판례 해설, 기획재정부·행안부 유권해석, 실무 FAQ를 한곳에서 확인하세요. 공무원 계약 담당자를 위한 공식 해석 자료 모음.",
      keywords: "공공계약 판례, 유권해석, 계약 FAQ, 수의계약 판례, 입찰 판례, 계약담당자 FAQ",
      og: {
        title: "공공계약 판례·유권해석·FAQ 모음 — 실무.kr",
        description: "수의계약·입찰·계약이행 판례 해설과 기재부·행안부 유권해석을 한곳에서 확인하세요.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp"
      },
      canonical: canonical_url
    )
    @resources = [
      { id: 1, title: "입찰자격제한 처분 관련 대법원 판례 해설", category: "판례", date: "2026.01.28", type: "판례해설" },
      { id: 2, title: "수의계약 체결 시 주의사항 FAQ", category: "FAQ", date: "2026.01.25", type: "FAQ" },
      { id: 3, title: "2026년 계약집행 특례 안내", category: "공지", date: "2026.01.20", type: "공지사항" },
      { id: 4, title: "부정당업자 제재 절차 안내", category: "FAQ", date: "2026.01.18", type: "FAQ" },
      { id: 5, title: "분할계약 금지 관련 유권해석", category: "판례", date: "2026.01.15", type: "유권해석" }
    ]
  end
end
