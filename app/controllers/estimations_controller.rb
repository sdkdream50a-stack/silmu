# 소요예산 추정 컨트롤러
class EstimationsController < ApplicationController

  # GET /tools/budget-estimator
  def index
    @price_catalog = EstimateCalculatorService.price_catalog
    set_meta_tags(
      title: "소요예산 추정기",
      description: "사업 유형별 소요예산을 간편하게 추정합니다. 공사, 물품, 용역별 예산 산출.",
      keywords: "소요예산, 예산 추정, 예산 계산기, 공사 예산, 물품 예산",
      og: { title: "소요예산 추정기 — 실무", url: request.original_url }
    )
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
