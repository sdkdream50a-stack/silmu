class PdfToolsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:split, :merge, :add_page_numbers]
  before_action :validate_pdf_file, only: [:split, :merge, :add_page_numbers]

  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/pdf].freeze

  def index
    # PDF 도구 메인 페이지
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
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
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
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
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
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
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
      render json: { error: e.message }, status: :unprocessable_entity
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
