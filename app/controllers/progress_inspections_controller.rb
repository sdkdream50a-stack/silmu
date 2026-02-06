# 기성검사 체크리스트 컨트롤러
class ProgressInspectionsController < ApplicationController

  # GET /tools/progress-inspection
  def index
    @inspection_types = ProgressInspectionService.get_inspection_types
  end

  # POST /progress-inspections/generate
  def generate
    result = ProgressInspectionService.generate(
      inspection_type: params[:inspection_type],
      contract_name: params[:contract_name],
      contract_amount: params[:contract_amount],
      contractor: params[:contractor],
      contract_date: params[:contract_date],
      completion_date: params[:completion_date],
      round: params[:round],
      inspection_period: params[:inspection_period],
      inspection_amount: params[:inspection_amount],
      paid_amount: params[:paid_amount]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
