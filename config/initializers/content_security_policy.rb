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
    policy.img_src     :self, :https, :data, :blob,
                       "www.google-analytics.com",
                       "www.clarity.ms"
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline,
                       "cdn.sheetjs.com",
                       "cdnjs.cloudflare.com",
                       "unpkg.com",
                       "code.iconify.design",
                       "www.googletagmanager.com",
                       "www.clarity.ms",
                       "t1.kakaocdn.net"
    policy.style_src   :self, :unsafe_inline,
                       "cdn.jsdelivr.net",
                       "fonts.googleapis.com"
    policy.connect_src :self, :https,
                       "www.google-analytics.com",
                       "region1.analytics.google.com",
                       "www.clarity.ms"
    policy.frame_ancestors :none
  end

  # CSP 강제 적용 모드 (enforce)
  config.content_security_policy_report_only = false
end
