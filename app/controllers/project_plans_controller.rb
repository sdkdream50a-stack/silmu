class ProjectPlansController < ApplicationController
  def index
    set_meta_tags(
      title: "사업계획서 생성기",
      description: "수의계약 사업계획서를 간편하게 작성합니다. 사업명, 필요성, 예산 등을 입력하면 공문 서식의 사업계획서를 자동 생성.",
      keywords: "사업계획서, 수의계약, 사업계획 수립, 공문 서식",
      og: { title: "사업계획서 생성기 — 실무.kr", url: canonical_url }
    )
  end

  def download_hwpx
    binary = HwpxExportService.generate_project_plan(download_params)

    if binary
      project_name = download_params[:project_name].to_s.gsub(/[^\w가-힣\s\-]/, "").strip.presence || "사업계획서"
      send_data binary,
                filename: "사업계획서_#{project_name}.hwpx",
                type: "application/octet-stream",
                disposition: "attachment"
    else
      redirect_to project_plan_path, alert: "HWPX 파일 생성에 실패했습니다. 잠시 후 다시 시도해 주세요."
    end
  end

  private

  def download_params
    params.permit(
      :project_name, :department, :manager, :contact,
      :necessity, :current_status, :content, :schedule,
      :budget, :budget_korean, :budget_item, :effect
    )
  end
end
