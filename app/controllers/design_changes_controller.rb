# 설계변경 검토서 도우미 컨트롤러
class DesignChangesController < ApplicationController

  # GET /tools/design-change
  def index
    @change_reasons = DesignChangeReviewService.get_change_reasons
  end

  # GET /design-changes/detail/:reason
  def detail
    result = DesignChangeReviewService.get_reason_detail(params[:reason])

    respond_to do |format|
      format.json { render json: result }
    end
  end

  # POST /design-changes/generate
  def generate
    result = DesignChangeReviewService.generate(
      reason: params[:reason],
      original_design: params[:original_design],
      changed_design: params[:changed_design],
      detail_reason: params[:detail_reason],
      cost_impact: params[:cost_impact],
      change_amount: params[:change_amount],
      schedule_change: params[:schedule_change],
      schedule_days: params[:schedule_days]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
