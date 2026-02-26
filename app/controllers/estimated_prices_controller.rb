# 추정가격 계산기 컨트롤러
class EstimatedPricesController < ApplicationController

  # GET /tools/estimated-price
  def index
    @contract_types = EstimatedPriceService.get_contract_types
    set_meta_tags(
      title: "추정가격 계산기 — 예정가격·수의계약 기준금액 자동 산출",
      description: "공사·물품·용역의 추정가격(부가세 제외)을 자동으로 산출합니다. 수의계약 기준금액 판단, 일반관리비·이윤 요율 자동 적용, 계약방식까지 한 번에 확인하세요. 2026년 지방계약법 기준.",
      keywords: "추정가격, 추정가격 계산기, 예정가격, 예정가격 계산기, 수의계약 기준금액, 부가세",
      og: { title: "추정가격 계산기 — 실무.kr", url: canonical_url }
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
