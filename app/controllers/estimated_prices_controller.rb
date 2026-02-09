# 예정가격 계산기 컨트롤러
class EstimatedPricesController < ApplicationController

  # GET /tools/estimated-price
  def index
    @contract_types = EstimatedPriceService.get_contract_types
    set_meta_tags(
      title: "예정가격 계산기",
      description: "물품·용역·공사의 예정가격을 자동으로 산정합니다. 부가세, 일반관리비, 이윤 등을 자동 반영.",
      keywords: "예정가격, 예정가격 계산기, 예정가격 산정, 부가세, 일반관리비",
      og: { title: "예정가격 계산기 — 실무.kr", url: request.original_url }
    )
  end

  # POST /estimated-prices/calculate
  def calculate
    result = EstimatedPriceService.calculate(
      contract_type: params[:contract_type],
      unit_price: params[:unit_price],
      quantity: params[:quantity],
      delivery_fee: params[:delivery_fee],
      install_fee: params[:install_fee],
      direct_labor: params[:direct_labor],
      overhead: params[:overhead],
      direct_expense: params[:direct_expense],
      general_admin: params[:general_admin],
      profit: params[:profit],
      material: params[:material],
      indirect_labor: params[:indirect_labor],
      industrial_insurance: params[:industrial_insurance],
      expense: params[:expense]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
