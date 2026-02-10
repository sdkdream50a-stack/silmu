class DocumentAnalysisController < ApplicationController
  # 정적 HTML(public/forms/)에서 호출하므로 CSRF 예외 처리 + Origin 검증으로 보완
  skip_before_action :verify_authenticity_token, only: [:analyze]
  before_action :verify_request_origin, only: [:analyze]

  MAX_FILE_SIZE = 20.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze

  # IP당 분당 5회, 일일 50회 제한
  RATE_LIMIT = 5
  RATE_PERIOD = 1.minute
  DAILY_LIMIT = 50

  def analyze
    # 속도 제한 검사
    if rate_limited?
      return render json: { success: false, error: "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요." }, status: :too_many_requests
    end

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

  private

  def rate_limited?
    ip = request.remote_ip

    minute_key = "doc_analysis_rate:#{ip}"
    minute_count = Rails.cache.read(minute_key).to_i
    return true if minute_count >= RATE_LIMIT

    daily_key = "doc_analysis_daily:#{ip}:#{Date.today}"
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
