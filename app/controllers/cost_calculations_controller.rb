# 원가계산서 검토 가이드 컨트롤러
class CostCalculationsController < ApplicationController

  # GET /tools/cost-calculation
  def index
    @service_types = CostCalculationReviewService.get_service_types
    set_meta_tags(
      title: "원가계산서 검토 가이드",
      description: "용역·공사 원가계산서의 적정성을 검토합니다. 인건비, 경비, 일반관리비, 이윤 항목별 검토.",
      keywords: "원가계산서, 원가계산 검토, 인건비, 경비, 일반관리비, 이윤",
      og: { title: "원가계산서 검토 가이드 — 실무", url: request.original_url }
    )
  end

  # POST /cost-calculations/review
  def review
    result = CostCalculationReviewService.review(
      service_type: params[:service_type],
      direct_labor: params[:direct_labor],
      overhead: params[:overhead],
      direct_expense: params[:direct_expense],
      general_admin: params[:general_admin],
      profit_or_tech: params[:profit_or_tech],
      vat: params[:vat]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
