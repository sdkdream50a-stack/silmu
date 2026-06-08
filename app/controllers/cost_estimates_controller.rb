# 물량내역서 + 시방서 생성기 컨트롤러
class CostEstimatesController < ApplicationController
  # GET /tools/cost-estimate
  def index
    @construction_types = CostEstimateGeneratorService.get_construction_types
    set_meta_tags(
      title: "물량내역서+시방서 생성기",
      description: "공사 유형을 선택하면 물량내역서와 시방서를 자동으로 생성합니다. 공무원이 설계서·내역서를 작성하는 시간을 줄이도록 표준 서식으로 한 번에 만들어 드립니다.",
      keywords: "물량내역서, 시방서, 공사 내역서, 내역서 생성, 설계서",
      og: { title: "물량내역서+시방서 생성기 — 실무.kr", url: canonical_url }
    )
  end

  # GET /cost-estimates/default-items/:type
  def default_items
    result = CostEstimateGeneratorService.get_default_items(params[:type])

    respond_to do |format|
      format.json { render json: result }
    end
  end

  # POST /cost-estimates/generate
  def generate
    result = CostEstimateGeneratorService.generate(
      construction_types: params[:construction_types] || [ params[:construction_type] ].compact,
      contract_type: params[:contract_type] || "private",
      items: params[:items],
      info: info_params,
      custom_instructions: params[:custom_instructions]
    )

    respond_to do |format|
      format.json { render json: result }
    end
  end

  private

  def info_params
    {
      project_name: params[:project_name],
      location: params[:location],
      duration: params[:duration],
      manager: params[:manager],
      department: params[:department],
      approval_staff: params[:approval_staff],
      approval_team: params[:approval_team],
      approval_section: params[:approval_section],
      approval_director: params[:approval_director]
    }
  end
end
