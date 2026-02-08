class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_default_meta_tags
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:newsletter_agreed])
    devise_parameter_sanitizer.permit(:account_update, keys: [:newsletter_agreed])
  end

  def set_default_meta_tags
    set_meta_tags(
      site: "실무",
      separator: "|",
      reverse: true,
      description: "공무원을 위한 계약 실무 가이드 — 수의계약, 입찰, 검수, 예산 업무를 쉽고 정확하게",
      og: { site_name: "실무", type: "website", locale: "ko_KR" },
      twitter: { card: "summary_large_image" }
    )
  end
end
