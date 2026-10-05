class SitemapController < ApplicationController
  def index
    @topics = Topic.published.select(:slug, :updated_at, :law_verified_at)
    @audit_cases = AuditCase.published.search_indexable.select(:slug, :updated_at)
    @guides = Guide.published.select(:slug, :updated_at)
    # F6 — 실제 서식 파일이 있는 양식만 (파일 없는 미리보기 틀은 noindex · sitemap 제외)
    @templates = TemplatesController.indexable_templates
    @series_slugs = Guide::SERIES_SLUG_MAP.values

    expires_in 10.minutes, public: true

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
