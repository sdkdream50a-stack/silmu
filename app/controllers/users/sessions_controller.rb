class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: :destroy

  private

  def after_sign_in_path_for(resource)
    if request.subdomain == "exam"
      exam_root_url(subdomain: "exam")
    else
      stored_location_for(resource) || root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if request.subdomain == "exam"
      exam_root_url(subdomain: "exam")
    else
      root_path
    end
  end
end
