# 계약보증금·하자보증금·인지세·지체상금 계산기 컨트롤러
class ContractGuaranteesController < ApplicationController
  # GET /tools/contract-guarantee
  def index
    @guarantee_types = ContractGuaranteeService.get_contract_guarantee_types
    @defect_work_types = ContractGuaranteeService.get_defect_work_types
    @delay_penalty_types = ContractGuaranteeService.get_delay_penalty_types
    set_meta_tags(
      title: "계약보증금 계산기",
      description: "계약보증금, 하자보증금, 인지세를 자동으로 계산합니다. 계약 유형별 보증금률 자동 적용.",
      keywords: "계약보증금, 하자보증금, 인지세, 보증금 계산기, 계약보증금률",
      og: { title: "계약보증금 계산기 — 실무.kr", url: canonical_url }
    )
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

  # POST /contract-guarantees/delay-penalty
  def delay_penalty
    result = ContractGuaranteeService.calculate_delay_penalty(
      contract_amount: params[:contract_amount],
      delay_days: params[:delay_days],
      contract_type: params[:contract_type]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
