# 소요예산 추정 컨트롤러
class EstimationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:calculate]

  # GET /tools/budget-estimator
  def index
    @price_catalog = EstimateCalculatorService.price_catalog
  end

  # POST /estimations/calculate
  def calculate
    result = case params[:type]
    when "construction"
      items = parse_items(params[:items])
      EstimateCalculatorService.estimate_construction(
        items: items,
        grade: params[:grade] || "standard"
      )
    when "service"
      EstimateCalculatorService.estimate_service(
        service_type: params[:service_type],
        duration: params[:duration],
        personnel_count: params[:personnel_count],
        grade: params[:grade] || "standard"
      )
    when "goods"
      items = parse_items(params[:items])
      EstimateCalculatorService.estimate_goods(
        items: items,
        grade: params[:grade] || "standard"
      )
    when "design_fee"
      EstimateCalculatorService.estimate_design_fee(
        construction_cost: params[:construction_cost],
        design_type: params[:design_type],
        include_supervision: params[:include_supervision] == "true" || params[:include_supervision] == true,
        supervision_type: params[:supervision_type] || "periodic"
      )
    else
      { success: false, error: "유효하지 않은 추정 유형입니다." }
    end

    respond_to do |format|
      format.json { render json: result }
      format.turbo_stream do
        @result = result
        render turbo_stream: turbo_stream.replace("estimation-result", partial: "estimations/result", locals: { result: @result })
      end
    end
  end

  private

  def parse_items(items_param)
    return [] if items_param.blank?

    items_param.map do |item|
      {
        type: item[:type],
        quantity: item[:quantity]
      }
    end
  end
end
