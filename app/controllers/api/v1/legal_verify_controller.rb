# frozen_string_literal: true

# blog_autopilot 전용 법령 검증 API
# POST /api/v1/legal_verify
# Authorization: Bearer <BLOG_API_KEY>
module Api
  module V1
    class LegalVerifyController < ActionController::API
      before_action :authenticate_api_key!

      # POST /api/v1/legal_verify
      # params: { text: "본문 전체", citations: ["인용 목록"] (optional) }
      def verify
        text = params[:text].to_s.strip
        return render json: { error: "text 파라미터가 필요합니다" }, status: :bad_request if text.blank?

        verifier = BlogLegalVerifier.new
        result = verifier.verify(text)

        render json: result
      end

      private

      def authenticate_api_key!
        token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
        expected = Rails.application.credentials.dig(:blog_api, :key)

        unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
          render json: { error: "인증 실패" }, status: :unauthorized
        end
      end
    end
  end
end
