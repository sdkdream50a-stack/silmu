# 계약방식 결정 도구 컨트롤러
class ContractMethodsController < ApplicationController

  # GET /tools/contract-method
  def index
    @contract_types = ContractMethodService.contract_types
    @special_enterprises = ContractMethodService.special_enterprises
  end

  # POST /contract-methods/determine
  def determine
    result = ContractMethodService.determine(
      contract_type: params[:contract_type],
      estimated_price: params[:estimated_price],
      special_enterprise: params[:special_enterprise]
    )

    render json: result
  end

  # GET /contract-methods/table/:type
  def table
    @type = params[:type]
    @table = ContractMethodService.threshold_table(@type)

    respond_to do |format|
      format.json { render json: { table: @table } }
    end
  end
end
