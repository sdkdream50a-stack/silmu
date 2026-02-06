# 계약보증금·하자보증금·인지세 계산기 컨트롤러
class ContractGuaranteesController < ApplicationController

  # GET /tools/contract-guarantee
  def index
    @guarantee_types = ContractGuaranteeService.get_contract_guarantee_types
    @defect_work_types = ContractGuaranteeService.get_defect_work_types
  end

  # POST /contract-guarantees/calculate
  def calculate
    result = ContractGuaranteeService.calculate(
      contract_amount: params[:contract_amount],
      guarantee_type: params[:guarantee_type],
      defect_work_types: params[:defect_work_types]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
