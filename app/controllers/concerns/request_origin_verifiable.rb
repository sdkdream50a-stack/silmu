module RequestOriginVerifiable
  extend ActiveSupport::Concern

  private

  def verify_request_origin
    allowed_origins = [ request.base_url, "https://silmu.kr", "https://www.silmu.kr" ]
    origin = request.headers["Origin"] || request.headers["Referer"]&.then { |r| URI.parse(r).then { |u| "#{u.scheme}://#{u.host}#{":#{u.port}" unless [ 80, 443 ].include?(u.port)}" } rescue nil }

    unless origin.present? && allowed_origins.any? { |allowed| origin.start_with?(allowed) }
      render json: { success: false, error: "허용되지 않은 요청입니다." }, status: :forbidden
    end
  end
end
