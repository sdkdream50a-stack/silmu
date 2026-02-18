class AuditCasesController < ApplicationController
  def index
    @category = params[:category]
    @severity = params[:severity]

    # 전체를 한 번만 로드 후 Ruby에서 필터링 → 3 쿼리 → 1 쿼리
    all_cases    = AuditCase.published.recent.to_a
    @categories  = all_cases.map(&:category).compact.uniq.sort
    @total_count = all_cases.size

    @audit_cases = all_cases
    @audit_cases = @audit_cases.select { |ac| ac.category == @category } if @category.present?
    @audit_cases = @audit_cases.select { |ac| ac.severity == @severity } if @severity.present?

    meta = {
      title: "감사사례 모음 — 계약 실무 감사 지적 사례",
      description: "공공계약 감사에서 자주 지적되는 사례를 카테고리별로 정리했습니다. 수의계약, 입찰, 계약이행, 대금지급 등 분야별 감사 지적사항과 대응 방법을 확인하세요.",
      keywords: "감사사례,감사 지적,계약 감사,수의계약 감사,입찰 감사,공공계약 감사,감사 대비",
      canonical: canonical_url,
      og: {
        title: "감사사례 모음 — 계약 실무 감사 지적 사례",
        description: "공공계약 감사에서 자주 지적되는 사례를 분야별로 정리했습니다.",
        url: canonical_url
      }
    }
    meta[:robots] = "noindex, follow" if @category.present? || @severity.present?
    set_meta_tags(meta)
  end

  def show
    @audit_case = AuditCase.published.find_by!(slug: params[:slug])
    @audit_case.increment_view!
    @related_topic = @audit_case.related_topic
    @related_cases = AuditCase.published
                              .where(category: @audit_case.category)
                              .where.not(id: @audit_case.id)
                              .limit(4)

    set_meta_tags(
      title: "#{@audit_case.title} — 감사사례",
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
