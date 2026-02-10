class OfficialDocumentsController < ApplicationController
  def index
    set_meta_tags(
      title: "공문서 AI 작성 도우미",
      description: "기안문, 협조문, 통보문 등 공문서를 AI가 행정업무운영규정에 맞게 자동 작성합니다.",
      keywords: "공문서 작성, 기안문, 협조문, 통보문, 보고문, 행정업무운영규정",
      og: { title: "공문서 AI 작성 도우미 — 실무.kr", url: request.original_url }
    )
  end

  def generate
    service = OfficialDocumentService.new(generate_params)
    result = service.generate

    if result
      render json: { success: true, html: result }
    else
      render json: { success: false, error: "공문서 생성에 실패했습니다. 잠시 후 다시 시도해주세요." }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "OfficialDocumentsController error: #{e.message}"
    render json: { success: false, error: "오류가 발생했습니다. 잠시 후 다시 시도해주세요." }, status: :internal_server_error
  end

  private

  def generate_params
    params.permit(
      :doc_type, :recipient, :title, :content_summary,
      :sender_dept, :sender_name, :sender_phone,
      :attachments, :related_doc, :tone
    )
  end
end
