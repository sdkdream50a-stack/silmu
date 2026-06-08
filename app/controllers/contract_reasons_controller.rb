class ContractReasonsController < ApplicationController
  def index
    set_meta_tags(
      title: "수의계약 사유서 생성기",
      description: "수의계약 사유서를 간편하게 작성합니다. 계약구분과 사유를 선택하면 지방계약법 등 법적 근거가 자동 삽입된 사유서를 생성해 결재 서류로 바로 활용할 수 있습니다.",
      keywords: "수의계약 사유서, 수의계약 요청서, 법적 근거, 지방계약법",
      og: { title: "수의계약 사유서 생성기 — 실무.kr", url: canonical_url }
    )
  end

  def download_hwpx
    binary = HwpxExportService.generate_contract_reason(download_params)

    if binary
      contract_name = download_params[:contract_name].to_s.gsub(/[^\w가-힣\s\-]/, "").strip.presence || "수의계약사유서"
      send_data binary,
                filename: "수의계약사유서_#{contract_name}.hwpx",
                type: "application/octet-stream",
                disposition: "attachment"
    else
      redirect_to contract_reason_path, alert: "HWPX 파일 생성에 실패했습니다. 잠시 후 다시 시도해 주세요."
    end
  end

  private

  def download_params
    params.permit(
      :contract_name, :type_label, :budget, :budget_korean, :vat_label,
      :company, :business_no, :delivery, :reason_detail,
      :reason_law, :reason_law_text, :background, :dept, :manager
    )
  end
end
