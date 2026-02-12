# 설계변경 검토서 도우미 컨트롤러
class DesignChangesController < ApplicationController

  # GET /tools/design-change
  def index
    @change_reasons = DesignChangeReviewService.get_change_reasons
    set_meta_tags(
      title: "설계변경 검토서 도우미",
      description: "설계변경 사유별 검토서를 자동으로 작성합니다. 설계변경 요건과 절차를 안내합니다.",
      keywords: "설계변경, 설계변경 검토서, 설계변경 사유, 공사 설계변경",
      og: { title: "설계변경 검토서 도우미 — 실무.kr", url: canonical_url }
    )
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
