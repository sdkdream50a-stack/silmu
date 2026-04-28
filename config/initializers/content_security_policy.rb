# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # default_src = 'self' 로 경화. 각 디렉티브는 명시적 화이트리스트로 운영.
    # 미지정 디렉티브(media/worker/manifest/frame_src)는 self 로 폴백 → 외부 embed 금지.
    policy.default_src :self

    policy.font_src    :self, :data,
                       "cdn.jsdelivr.net",       # Pretendard
                       "fonts.gstatic.com",      # Google Fonts / Material Symbols
                       "fonts.googleapis.com"

    # img_src는 OpenGraph 썸네일·외부 아티클 이미지 동적 URL 대응 위해 https: 유지.
    # 추후 CDN 프록시 도입 시 축소.
    policy.img_src     :self, :https, :data, :blob,
                       "www.google-analytics.com",
                       "www.clarity.ms"

    policy.object_src  :none

    policy.script_src  :self, :unsafe_inline,
                       "cdn.jsdelivr.net",       # xlsx-js-style (quote_documents 등 엑셀 내보내기)
                       "cdn.sheetjs.com",
                       "cdnjs.cloudflare.com",   # html2canvas, jspdf
                       "unpkg.com",
                       "code.iconify.design",
                       "www.googletagmanager.com",
                       "www.clarity.ms",
                       "t1.kakaocdn.net"         # Kakao 공유 SDK

    policy.style_src   :self, :unsafe_inline,
                       "cdn.jsdelivr.net",       # Pretendard
                       "fonts.googleapis.com"

    # connect_src https: catch-all 제거 → 임의 exfiltration 경로 차단.
    # Iconify 3.x는 SVG 아이콘 데이터를 api.iconify.design에서 fetch
    # (fallback: api.simplesvg.com, api.unisvg.com)
    policy.connect_src :self,
                       "www.google-analytics.com",
                       "region1.analytics.google.com",
                       "stats.g.doubleclick.net",
                       "www.clarity.ms",
                       "api.iconify.design",
                       "api.simplesvg.com",
                       "api.unisvg.com"

    policy.frame_ancestors :none
    policy.base_uri :self    # <base> 주입을 통한 relative URL 탈취 방지
    policy.form_action :self # 폼 제출지 self 고정
  end

  # CSP 강제 적용 모드 (enforce)
  config.content_security_policy_report_only = false
end
