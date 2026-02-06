class DocumentAnalysisController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:analyze]

  MAX_FILE_SIZE = 20.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze

  def analyze
    unless params[:file].present?
      return render json: { success: false, error: "파일을 업로드해주세요." }, status: :unprocessable_entity
    end

    file = params[:file]
    document_type = params[:document_type] || "service"

    # 파일 검증
    unless file.respond_to?(:content_type) && ALLOWED_CONTENT_TYPES.include?(file.content_type)
      return render json: { success: false, error: "지원하지 않는 파일 형식입니다. (PDF, JPG, PNG만 가능)" }, status: :unprocessable_entity
    end

    if file.size > MAX_FILE_SIZE
      return render json: { success: false, error: "파일 크기는 20MB 이하여야 합니다." }, status: :unprocessable_entity
    end

    result = DocumentAnalyzerService.new.analyze(file: file, document_type: document_type)

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("DocumentAnalysisController error: #{e.message}")
    render json: { success: false, error: "문서 분석 중 오류가 발생했습니다." }, status: :internal_server_error
  end
end
