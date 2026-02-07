class SitemapController < ApplicationController
  def index
    @topics = Topic.published.select(:slug, :updated_at)
    @audit_cases = AuditCase.published.select(:slug, :updated_at)
    @guides = GuidesController::GUIDES
    @templates = TemplatesController::TEMPLATES

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
