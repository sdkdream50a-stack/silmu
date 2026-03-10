class AuditCasesController < ApplicationController
  def index
    @category = params[:category]
    @severity = params[:severity]

    # 전체를 캐싱 후 Ruby에서 필터링 → DB 쿼리 0 (캐시 히트 시)
    all_cases = Rails.cache.fetch("audit_cases/all_published", expires_in: 30.minutes) do
      AuditCase.published.recent.to_a
    end
    @categories  = all_cases.map(&:category).compact.uniq.sort
    @total_count = all_cases.size

    @audit_cases = all_cases
    @audit_cases = @audit_cases.select { |ac| ac.category == @category } if @category.present?
    @audit_cases = @audit_cases.select { |ac| ac.severity == @severity } if @severity.present?
    # 뷰 fragment cache 버전
    @fragment_version = Rails.cache.read("audit_cases/fragment_version") || 0

    # HTTP 캐싱: 5분간 캐시
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour

    meta = {
      title: "감사사례 모음 — 계약 실무 감사 지적 사례",
      description: "공공계약 감사에서 자주 지적되는 사례를 카테고리별로 정리했습니다. 수의계약, 입찰, 계약이행, 대금지급 등 분야별 감사 지적사항과 대응 방법을 확인하세요.",
      keywords: "감사사례,감사 지적,계약 감사,수의계약 감사,입찰 감사,공공계약 감사,감사 대비",
      canonical: canonical_url,
      og: {
        title: "감사사례 모음 — 계약 실무 감사 지적 사례",
        description: "공공계약 감사에서 자주 지적되는 사례를 분야별로 정리했습니다.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      }
    }
    meta[:robots] = "noindex, follow" if @category.present? || @severity.present?
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
    @audit_case = AuditCase.published.find_by!(slug: params[:slug])
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

    set_meta_tags(
      title: "#{@audit_case.title} — 실제 감사 지적 사례와 대응 방법",
      description: "#{@audit_case.issue.truncate(150)}",
      keywords: "감사사례,#{@audit_case.category},#{@audit_case.legal_basis}",
      canonical: canonical_url,
      og: {
        title: "#{@audit_case.title} — 감사사례",
        description: @audit_case.issue.truncate(200),
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "article"
      }
    )
  end
end
