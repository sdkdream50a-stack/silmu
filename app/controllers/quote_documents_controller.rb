class QuoteDocumentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:extract]
  before_action :require_login_for_ai, only: [:extract]
  before_action :verify_request_origin, only: [:extract]

  MAX_FILE_SIZE = 20.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze

  RATE_LIMIT = 5
  RATE_PERIOD = 1.minute
  DAILY_LIMIT = 50

  def index
    set_meta_tags(
      title: "견적서 일괄 문서생성",
      description: "견적서 1장을 업로드하면 사업계획서·소요예산·예정가격 조서를 한 번에 자동 생성합니다.",
      keywords: "견적서, 사업계획서, 소요예산, 예정가격, 수의계약, 일괄생성",
      og: { title: "견적서 일괄 문서생성 — 실무.kr", url: request.original_url }
    )
  end

  def extract
    if rate_limited?
      return render json: { success: false, error: "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요." }, status: :too_many_requests
    end

    # 다중 파일(files[]) 또는 단일 파일(file) 지원
    files = if params[:files].present?
      Array(params[:files])
    elsif params[:file].present?
      [params[:file]]
    else
      return render json: { success: false, error: "파일을 업로드해주세요." }, status: :unprocessable_entity
    end

    files.each do |file|
      unless file.respond_to?(:content_type) && ALLOWED_CONTENT_TYPES.include?(file.content_type)
        return render json: { success: false, error: "지원하지 않는 파일 형식입니다. (PDF, JPG, PNG만 가능)" }, status: :unprocessable_entity
      end

      if file.size > MAX_FILE_SIZE
        return render json: { success: false, error: "개별 파일 크기는 20MB 이하여야 합니다." }, status: :unprocessable_entity
      end
    end

    result = DocumentAnalyzerService.new.analyze_multiple(files: files, document_type: "quote_extraction")

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("QuoteDocumentsController error: #{e.message}")
    render json: { success: false, error: "문서 분석 중 오류가 발생했습니다." }, status: :internal_server_error
  end

  private

  def rate_limited?
    key_id = current_user&.id || request.remote_ip

    minute_key = "quote_doc_rate:#{key_id}"
    minute_count = Rails.cache.read(minute_key).to_i
    return true if minute_count >= RATE_LIMIT

    daily_key = "quote_doc_daily:#{key_id}:#{Date.today}"
    daily_count = Rails.cache.read(daily_key).to_i
    return true if daily_count >= DAILY_LIMIT

    Rails.cache.write(minute_key, minute_count + 1, expires_in: RATE_PERIOD)
    Rails.cache.write(daily_key, daily_count + 1, expires_in: 24.hours)
    false
  end

  def verify_request_origin
    allowed_origins = [request.base_url, "https://silmu.kr", "https://www.silmu.kr"]
    origin = request.headers["Origin"] || request.headers["Referer"]&.then { |r| URI.parse(r).then { |u| "#{u.scheme}://#{u.host}#{":#{u.port}" unless [80, 443].include?(u.port)}" } rescue nil }

    unless origin.present? && allowed_origins.any? { |allowed| origin.start_with?(allowed) }
      render json: { success: false, error: "허용되지 않은 요청입니다." }, status: :forbidden
    end
  end
end
