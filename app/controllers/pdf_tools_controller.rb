class PdfToolsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:split, :merge, :add_page_numbers]

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
end
