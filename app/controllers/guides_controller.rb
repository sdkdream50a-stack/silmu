class GuidesController < ApplicationController
  def index
    @guides            = Rails.cache.fetch("guides/all", expires_in: 1.hour) { Guide.published.ordered.to_a }
    @popular_guides    = Rails.cache.fetch("guides/popular", expires_in: 1.hour) { Guide.published.order(view_count: :desc).limit(5).to_a }
    @audit_case_count  = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }

    recent_slugs = JSON.parse(cookies[:recent_guides] || "[]") rescue []
    if recent_slugs.any?
      guides_by_slug = Guide.published.where(slug: recent_slugs).index_by(&:slug)
      @recent_guides = recent_slugs.filter_map { |slug| guides_by_slug[slug] }
    else
      @recent_guides = []
    end

    canonical_url = request.original_url.split("?").first
    meta = {
      title: "업무 가이드",
      description: "공무원 계약·검수·예산 업무를 단계별로 안내하는 실무 가이드. 물품 구매, 수의계약, 검수조서, 예정가격 작성 등.",
      keywords: "업무 가이드, 물품 구매, 검수조서, 예정가격, 수의계약, 여비, 연가",
      og: {
        title: "업무 가이드 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      },
      canonical: canonical_url
    }
    meta[:robots] = "noindex, follow" if params[:category].present?
    set_meta_tags(meta)
  end

  def show
    @guide = Guide.published.find_by!(slug: params[:slug])

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

    # external_link가 topic을 가리키는 경우 관련 Topic 로드
    if @guide.external_link&.start_with?("/topics/")
      topic_slug = @guide.external_link.delete_prefix("/topics/")
      @related_topic = Topic.published.find_by(slug: topic_slug)
    end

    @related_guides = Rails.cache.fetch("guides/related/#{@guide.slug}", expires_in: 1.hour) do
      same_cat = Guide.published.where(category: @guide.category).where.not(id: @guide.id).ordered.limit(2).to_a
      fill     = [3 - same_cat.size, 0].max
      others   = fill > 0 ? Guide.published.where.not(category: @guide.category).where.not(id: @guide.id).ordered.limit(fill).to_a : []
      same_cat + others
    end

    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: @guide.title,
      description: @guide.description.to_s.truncate(155),
      keywords: "#{@guide.category}, #{@guide.title}, 공무원 실무",
      og: {
        title: @guide.title,
        description: @guide.description.to_s.truncate(200),
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      },
      canonical: canonical_url
    )
  rescue ActiveRecord::RecordNotFound
    redirect_to guides_path, alert: "가이드를 찾을 수 없습니다."
  end

  # 계약 흐름도 페이지
  def contract_flow
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "계약 흐름도",
      description: "공무원 계약 업무의 전체 프로세스를 시각적 흐름도로 한눈에 파악할 수 있습니다.",
      og: {
        title: "계약 흐름도 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
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
        image: "https://silmu.kr/og-image.png"
      },
      canonical: canonical_url
    )
  end

  # 자료실/FAQ
  def resources
    canonical_url = request.original_url.split("?").first
    set_meta_tags(
      title: "자료실",
      description: "계약 실무에 필요한 판례 해설, FAQ, 유권해석, 공지사항을 모아놓은 자료실입니다.",
      keywords: "자료실, 판례, 유권해석, 계약 FAQ, 계약집행 특례",
      og: {
        title: "자료실 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
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
