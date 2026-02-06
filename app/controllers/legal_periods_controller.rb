# 법정기간 계산기 컨트롤러
class LegalPeriodsController < ApplicationController

  # GET /tools/legal-period
  def index
    @period_types = LegalPeriodService.get_period_types
  end

  # POST /legal-periods/calculate
  def calculate
    result = LegalPeriodService.calculate(
      period_type: params[:period_type],
      estimated_amount: params[:estimated_amount],
      announcement_date: params[:announcement_date],
      urgent: params[:urgent],
      notification_date: params[:notification_date],
      payment_type: params[:payment_type],
      inspection_date: params[:inspection_date],
      completion_date: params[:completion_date],
      work_types: params[:work_types],
      penalty_type: params[:penalty_type],
      contract_amount: params[:contract_amount],
      due_date: params[:due_date],
      actual_date: params[:actual_date]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
