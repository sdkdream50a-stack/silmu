class SitemapController < ApplicationController
  def index
    @topics = Topic.published.select(:slug, :updated_at)
    @audit_cases = AuditCase.published.select(:slug, :updated_at)
    @guides = Guide.published.select(:slug, :updated_at)
    @templates = TemplatesController::TEMPLATES

    expires_in 10.minutes, public: true

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
