class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # 글로벌 에러 핸들링 — 5xx → 적절한 4xx 응답으로 전환 (Search Console 5xx 오류 해소)
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::RoutingError, with: :render_not_found

  before_action :set_default_meta_tags
  before_action :capture_utm_params
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Lograge payload 확장 — remote_ip, user_id를 JSON 로그에 주입
  def append_info_to_payload(payload)
    super
    payload[:remote_ip] = request.remote_ip
    payload[:user_id] = current_user&.id if respond_to?(:current_user)
  end

  private

  def render_not_found
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "Not Found" }, status: :not_found }
      format.any  { head :not_found }
    end
  end

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
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :newsletter_agreed ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :newsletter_agreed ])
  end

  def set_default_meta_tags
    og_image = @og_image_path.presence || "https://silmu.kr/og-image.webp"
    default_description = "공무원을 위한 계약 실무 가이드 — 수의계약, 입찰, 검수, 예산 업무를 쉽고 정확하게"
    set_meta_tags(
      site: "실무.kr",
      separator: "|",
      reverse: true,
      description: default_description,
      canonical: canonical_url,
      og: { site_name: "실무.kr", type: "website", locale: "ko_KR", image: { _: og_image, width: 1200, height: 630, type: "image/webp" } },
      # twitter title/description은 OG 자동 폴백되지 않음 — 명시 출력 (Twitter Card 권장 표준)
      twitter: { card: "summary_large_image", site: "@silmu_kr", image: og_image, title: "실무.kr", description: default_description }
    )
  end

  # 카테고리별 OG 이미지 경로 설정 및 메타태그 즉시 반영
  # 컨트롤러에서 before_action 또는 액션 내에서 호출:
  #   set_og_image(category: "contract")
  # set_default_meta_tags보다 나중에 실행되어도 set_meta_tags가 merge되므로 정상 반영됨
  def set_og_image(category: nil)
    base = "https://silmu.kr/og"
    @og_image_path = case category
    when "contract"  then "#{base}/og-contract.svg"
    when "budget"    then "#{base}/og-budget.svg"
    when "expense"   then "#{base}/og-expense.svg"
    when "salary"    then "#{base}/og-salary.svg"
    when "subsidy"   then "#{base}/og-subsidy.svg"
    when "property"  then "#{base}/og-property.svg"
    when "travel"    then "#{base}/og-travel.svg"
    when "duty"      then "#{base}/og-duty.svg"
    when "audit"     then "#{base}/og-audit.svg"
    when "tools"     then "#{base}/og-tools.svg"
    when "exam"      then "#{base}/og-exam.svg"
    else "https://silmu.kr/og-image.webp"
    end
    # 즉시 메타태그에 반영 (set_default_meta_tags 이후 호출 시에도 덮어쓰기)
    set_meta_tags(
      og: { image: { _: @og_image_path, width: 1200, height: 630, type: "image/svg+xml" } },
      twitter: { image: @og_image_path }
    )
  end

  # SEO: 쿼리 파라미터 제거한 canonical URL 반환
  def canonical_url
    @canonical_url ||= request.original_url.split("?").first
  end
  helper_method :canonical_url
end
