class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_default_meta_tags
  before_action :capture_utm_params
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def require_login_for_ai
    return if current_user

    respond_to do |format|
      format.json { render json: { success: false, error: "로그인이 필요한 기능입니다.", login_required: true }, status: :unauthorized }
      format.html { redirect_to new_user_session_path, alert: "로그인이 필요한 기능입니다." }
      format.any  { render json: { success: false, error: "로그인이 필요한 기능입니다.", login_required: true }, status: :unauthorized }
    end
  end

  def capture_utm_params
    utm_keys = %i[utm_source utm_medium utm_campaign utm_term utm_content]
    utm_data = params.slice(*utm_keys).permit(*utm_keys).to_h.symbolize_keys

    if utm_data.any?
      session[:utm_params] = utm_data
      session[:utm_landed_at] = Time.current.iso8601
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:newsletter_agreed])
    devise_parameter_sanitizer.permit(:account_update, keys: [:newsletter_agreed])
  end

  def set_default_meta_tags
    set_meta_tags(
      site: "실무.kr",
      separator: "|",
      reverse: true,
      description: "공무원을 위한 계약 실무 가이드 — 수의계약, 입찰, 검수, 예산 업무를 쉽고 정확하게",
      og: { site_name: "실무.kr", type: "website", locale: "ko_KR", image: { _: "https://silmu.kr/og-image.png", width: 1200, height: 630, type: "image/png" } },
      twitter: { card: "summary_large_image", image: "https://silmu.kr/og-image.png" }
    )
  end

  # SEO: 쿼리 파라미터 제거한 canonical URL 반환
  def canonical_url
    @canonical_url ||= request.original_url.split('?').first
  end
  helper_method :canonical_url
end
