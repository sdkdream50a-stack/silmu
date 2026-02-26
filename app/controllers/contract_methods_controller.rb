# 계약방식 결정 도구 컨트롤러
class ContractMethodsController < ApplicationController

  # GET /tools/contract-method
  def index
    @contract_types = ContractMethodService.contract_types
    @special_enterprises = ContractMethodService.special_enterprises
    set_meta_tags(
      title: "계약방식 결정 도우미 — 수의계약·경쟁입찰 자동 판단",
      description: "공사·물품·용역 금액을 입력하면 수의계약, 소액수의, 경쟁입찰 여부를 자동으로 판단합니다. 2026년 지방계약법 기준 적용, 청년창업·소기업·여성기업 특례금액도 한 번에 확인하세요.",
      keywords: "계약방식, 수의계약 기준, 소액수의, 경쟁입찰, 계약방식 결정",
      og: { title: "계약방식 결정 도우미 — 실무.kr", url: canonical_url }
    )
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
