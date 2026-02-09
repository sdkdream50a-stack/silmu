class PdfToolsController < ApplicationController
  before_action :validate_pdf_file, only: [:split, :merge, :add_page_numbers]

  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/pdf].freeze

  def index
    # PDF 도구 메인 페이지
    set_meta_tags(
      title: "PDF 도구",
      description: "PDF 분할, 합치기, 페이지번호 추가 등 공무원 업무에 유용한 PDF 편집 도구.",
      keywords: "PDF 분할, PDF 합치기, 페이지번호, PDF 도구, PDF 편집",
      og: { title: "PDF 도구 — 실무.kr", url: request.original_url }
    )
  end

  def split
    unless params[:file].present?
      return render json: { error: "PDF 파일을 업로드해주세요." }, status: :unprocessable_entity
    end

    begin
      result = PdfProcessorService.split(
        params[:file],
        ranges: params[:ranges] # "1-3,5,7-10" 형태
      )

      if result[:files].length == 1
        send_data result[:files].first[:data],
                  filename: result[:files].first[:name],
                  type: "application/pdf",
                  disposition: "attachment"
      else
        # 여러 파일은 ZIP으로 압축
        send_data result[:zip_data],
                  filename: "split_pdfs.zip",
                  type: "application/zip",
                  disposition: "attachment"
      end
    rescue RuntimeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error("PDF split error: #{e.message}")
      render json: { error: "PDF 분할 중 오류가 발생했습니다." }, status: :unprocessable_entity
    end
  end

  def merge
    unless params[:files].present? && params[:files].length >= 2
      return render json: { error: "2개 이상의 PDF 파일을 업로드해주세요." }, status: :unprocessable_entity
    end

    begin
      result = PdfProcessorService.merge(params[:files])

      send_data result[:data],
                filename: result[:name],
                type: "application/pdf",
                disposition: "attachment"
    rescue RuntimeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error("PDF merge error: #{e.message}")
      render json: { error: "PDF 합치기 중 오류가 발생했습니다." }, status: :unprocessable_entity
    end
  end

  def add_page_numbers
    unless params[:file].present?
      return render json: { error: "PDF 파일을 업로드해주세요." }, status: :unprocessable_entity
    end

    begin
      options = {
        position: params[:position] || "bottom_center",
        start_number: (params[:start_number] || 1).to_i,
        format: params[:format] || "number", # number, dash, parenthesis
        font_size: (params[:font_size] || 10).to_i,
        skip_first: params[:skip_first] == "true"
      }

      result = PdfProcessorService.add_page_numbers(params[:file], options)

      send_data result[:data],
                filename: result[:name],
                type: "application/pdf",
                disposition: "attachment"
    rescue RuntimeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error("PDF page numbers error: #{e.message}")
      render json: { error: "쪽번호 추가 중 오류가 발생했습니다." }, status: :unprocessable_entity
    end
  end

  def info
    unless params[:file].present?
      return render json: { error: "PDF 파일을 업로드해주세요." }, status: :unprocessable_entity
    end

    begin
      info = PdfProcessorService.get_info(params[:file])
      render json: info
    rescue => e
      Rails.logger.error("PDF info error: #{e.message}")
      render json: { error: "PDF 정보 읽기 중 오류가 발생했습니다." }, status: :unprocessable_entity
    end
  end

  private

  def validate_pdf_file
    files = [params[:file], params[:files]].flatten.compact

    files.each do |file|
      next unless file.respond_to?(:content_type)

      unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
        return render json: { error: "PDF 파일만 업로드 가능합니다." }, status: :unprocessable_entity
      end

      if file.size > MAX_FILE_SIZE
        return render json: { error: "파일 크기는 50MB 이하여야 합니다." }, status: :unprocessable_entity
      end
    end
  end
end
