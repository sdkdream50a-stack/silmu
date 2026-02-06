# 원가계산서 검토 가이드 컨트롤러
class CostCalculationsController < ApplicationController

  # GET /tools/cost-calculation
  def index
    @service_types = CostCalculationReviewService.get_service_types
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
