# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data,
                       "cdn.jsdelivr.net",
                       "fonts.gstatic.com",
                       "fonts.googleapis.com"
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline,
                       "cdn.sheetjs.com",
                       "cdnjs.cloudflare.com",
                       "unpkg.com"
    policy.style_src   :self, :unsafe_inline,
                       "cdn.jsdelivr.net",
                       "fonts.googleapis.com"
    policy.connect_src :self, :https
    policy.frame_ancestors :none
  end

  # Report violations without enforcing the policy (안전하게 먼저 모니터링).
  config.content_security_policy_report_only = true
end
