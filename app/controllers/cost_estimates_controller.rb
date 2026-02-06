# 내역서 + 시공지시서 생성기 컨트롤러
class CostEstimatesController < ApplicationController

  # GET /tools/cost-estimate
  def index
    @construction_types = CostEstimateGeneratorService.get_construction_types
  end

  # GET /cost-estimates/default-items/:type
  def default_items
    result = CostEstimateGeneratorService.get_default_items(params[:type])

    respond_to do |format|
      format.json { render json: result }
    end
  end

  # POST /cost-estimates/generate
  def generate
    result = CostEstimateGeneratorService.generate(
      construction_type: params[:construction_type],
      items: params[:items],
      info: info_params,
      custom_instructions: params[:custom_instructions]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end

  private

  def info_params
    {
      project_name: params[:project_name],
      location: params[:location],
      duration: params[:duration],
      manager: params[:manager],
      department: params[:department]
    }
  end
end
