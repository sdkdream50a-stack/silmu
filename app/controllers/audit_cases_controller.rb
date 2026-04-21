class AuditCasesController < ApplicationController
  PER_PAGE = 20
  def index
    @category = params[:category]
    @severity = params[:severity]
    @search   = params[:q].to_s.strip
    @page = [ (params[:page].to_i), 1 ].max

    # 전체를 캐싱 후 Ruby에서 필터링 → DB 쿼리 0 (캐시 히트 시)
    # v2: 카테고리 목록도 함께 캐싱 (매 요청마다 map/uniq/sort 불필요)
    all_cases, @categories = Rails.cache.fetch("audit_cases/all_published_v2", expires_in: 30.minutes) do
      cases = AuditCase.published.recent.to_a
      cats  = cases.map(&:category).compact.uniq.sort
      [ cases, cats ]
    end
    @total_count = all_cases.size

    filtered = all_cases
    filtered = filtered.select { |ac| ac.category == @category } if @category.present?
    filtered = filtered.select { |ac| ac.severity == @severity } if @severity.present?
    if @search.present?
      q = @search.downcase
      filtered = filtered.select { |ac| ac.title.downcase.include?(q) || ac.issue.downcase.include?(q) }
    end
    @filtered_count = filtered.size

    # 페이지 범위 보정: 필터 결과가 줄어도 유효 범위 유지
    total_pages = [ (@filtered_count.to_f / PER_PAGE).ceil, 1 ].max
    @page = [ [ @page, total_pages ].min, 1 ].max

    # 페이지네이션: 초기 로드 시 PER_PAGE개만 렌더링 (HTML 크기 ~75% 감소)
    offset = (@page - 1) * PER_PAGE
    @audit_cases = filtered.slice(offset, PER_PAGE) || []
    @has_more = (offset + PER_PAGE) < filtered.size
    @next_page = @page + 1

    # 뷰 fragment cache 버전
    @fragment_version = Rails.cache.read("audit_cases/fragment_version") || 0

    # Turbo Frame "더보기" 요청 시 카드만 반환 (레이아웃 제외)
    if turbo_frame_request_id == "audit-cases-page"
      render partial: "audit_cases/page_frame", layout: false
      return
    end

    # HTTP 캐싱: 5분간 캐시
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_og_image(category: "audit")
    meta = {
      title: "감사사례 모음 — 계약 실무 감사 지적 사례",
      description: "공공계약 감사에서 자주 지적되는 사례를 카테고리별로 정리했습니다. 수의계약, 입찰, 계약이행, 대금지급 등 분야별 감사 지적사항과 대응 방법을 확인하세요.",
      keywords: "감사사례,감사 지적,계약 감사,수의계약 감사,입찰 감사,공공계약 감사,감사 대비",
      canonical: canonical_url,
      og: {
        title: "감사사례 모음 — 계약 실무 감사 지적 사례",
        description: "공공계약 감사에서 자주 지적되는 사례를 카테고리별로 정리했습니다. 수의계약, 입찰, 계약이행, 대금지급 등 분야별 감사 지적사항과 대응 방법을 확인하세요.",
        url: canonical_url
      }
    }
    meta[:robots] = "noindex, follow" if @category.present? || @severity.present? || @search.present?
    set_meta_tags(meta)
  end

  def download_hwp
    response.headers["X-Robots-Tag"] = "noindex"
    @audit_case = AuditCase.published.find_by!(slug: params[:slug])
    binary = HwpxExportService.generate_audit_case(@audit_case)

    if binary
      send_data binary,
                filename: "#{@audit_case.slug}.hwpx",
                type: "application/octet-stream",
                disposition: "attachment"
    else
      redirect_to audit_case_path(slug: params[:slug]), alert: "HWP 파일 생성에 실패했습니다. 잠시 후 다시 시도해 주세요."
    end
  end

  def show
    @audit_case = AuditCase.published.find_by(slug: params[:slug])

    unless @audit_case
      new_slug = SlugRedirect.resolve(params[:slug], "AuditCase")
      if new_slug
        redirect_to audit_case_path(new_slug), status: :moved_permanently
        return
      end
      raise ActiveRecord::RecordNotFound
    end
    @audit_case.increment_view!
    @related_topic = Rails.cache.fetch("audit_case_topic/#{@audit_case.slug}", expires_in: 1.hour) do
      @audit_case.related_topic
    end
    @related_cases = Rails.cache.fetch("audit_case_related/#{@audit_case.slug}", expires_in: 1.hour) do
      AuditCase.published
               .where(category: @audit_case.category)
               .where.not(id: @audit_case.id)
               .limit(4)
               .to_a
    end

    # HTTP 캐싱: 감사사례 상세 (view_count 업데이트는 DB만 영향)
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    set_og_image(category: "audit")
    set_meta_tags(
      title: "#{@audit_case.title} — 실제 감사 지적 사례와 대응 방법",
      description: "#{@audit_case.issue.truncate(150)}",
      keywords: "감사사례,#{@audit_case.category},#{@audit_case.legal_basis}",
      canonical: canonical_url,
      og: {
        title: "#{@audit_case.title} — 감사사례",
        description: @audit_case.issue.truncate(200),
        url: canonical_url,
        type: "article"
      }
    )
  end
end
