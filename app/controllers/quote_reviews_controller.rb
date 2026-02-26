# frozen_string_literal: true

class QuoteReviewsController < ApplicationController
  layout false, only: [:index]
  skip_before_action :verify_authenticity_token, only: [:analyze]
  before_action :verify_request_origin, only: [:analyze]

  MAX_FILE_SIZE = 20.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze

  def index
    set_meta_tags(
      title: "견적서 검토 시스템",
      description: "견적서를 업로드하면 AI가 자동으로 검토하여 체크리스트, 필요서류, 관련규정을 안내합니다.",
      keywords: "견적서, 검토, 체크리스트, 수의계약, 견적서검토",
      og: { title: "견적서 검토 시스템 — 실무.kr", url: canonical_url }
    )
  end

  def analyze
    if rate_limited?
      return render json: { success: false, error: "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요." }, status: :too_many_requests
    end

    file = params[:file]
    unless file.present? && file.respond_to?(:content_type) && ALLOWED_CONTENT_TYPES.include?(file.content_type)
      return render json: { success: false, error: "이미지(JPG, PNG) 또는 PDF 파일만 업로드 가능합니다." }, status: :unprocessable_entity
    end

    if file.size > MAX_FILE_SIZE
      return render json: { success: false, error: "파일 크기는 20MB 이하여야 합니다." }, status: :unprocessable_entity
    end

    result = DocumentAnalyzerService.new.analyze(file: file, document_type: "quote_extraction")

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("QuoteReviewsController error: #{e.message}")
    render json: { success: false, error: "문서 분석 중 오류가 발생했습니다." }, status: :internal_server_error
  end

  private

  def rate_limited?
    key_id = current_user&.id || request.remote_ip

    minute_key = "quote_review_rate:#{key_id}"
    minute_count = Rails.cache.read(minute_key).to_i
    return true if minute_count >= 3

    daily_key = "quote_review_daily:#{key_id}:#{Time.zone.today}"
    daily_count = Rails.cache.read(daily_key).to_i
    return true if daily_count >= 20

    Rails.cache.write(minute_key, minute_count + 1, expires_in: 1.minute)
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
