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
    # img_src는 OpenGraph 썸네일·외부 아티클 이미지 동적 URL 대응 위해 https: 유지.
    # (:https 가 이미 AdSense 크리에이티브·픽셀을 포함한다 — 별도 추가 불필요)
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
                       "scripts.clarity.ms",
                       "static.cloudflareinsights.com",
                       "t1.kakaocdn.net",        # Kakao 공유 SDK
                       # ── AdSense (2026-09-12 재활성화) ──
                       # 공식 문서(support.google.com/adsense/answer/16283098)는 nonce 기반 strict CSP만
                       # "지원"한다고 명시한다. 그 방식은 'strict-dynamic'+https: 라서 위 allowlist 전체를
                       # 무력화하고 unsafe-eval까지 열어 — 광고와 무관한 축(jsdelivr·sheetjs·clarity)의
                       # 경화까지 함께 풀린다. 그래서 경화를 유지하는 allowlist를 먼저 쓴다.
                       # 트레이드오프: Google이 도메인을 바꾸면 예고 없이 광고가 깨질 수 있다 →
                       # 서빙 모니터(AdSense IMPRESSIONS)로 감지하고, 실제로 깨지면 그때 strict로 올린다.
                       "pagead2.googlesyndication.com",
                       "tpc.googlesyndication.com",
                       "partner.googleadservices.com",
                       "googleads.g.doubleclick.net"

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
                       "c.clarity.ms",
                       "c.bing.com",
                       "cloudflareinsights.com",
                       "api.iconify.design",
                       "api.simplesvg.com",
                       "api.unisvg.com",
                       # ── AdSense (2026-09-12) ──
                       "pagead2.googlesyndication.com",
                       "googleads.g.doubleclick.net",
                       "ep1.adtrafficquality.google",
                       "ep2.adtrafficquality.google"

    # frame_src: 지금까지 미지정이라 default_src(:self)를 상속했고 그래서 광고 iframe이 차단됐다.
    # 광고 크리에이티브는 전부 iframe으로 렌더되므로 이 지시자 없이는 스크립트를 넣어도 광고가 0이다.
    # :self 를 함께 적어 기존(동일출처 iframe) 동작을 보존한다.
    policy.frame_src   :self,
                       "googleads.g.doubleclick.net",
                       "tpc.googlesyndication.com",
                       "www.google.com",          # reCAPTCHA/광고 인터스티셜 경유
                       "ep1.adtrafficquality.google",
                       "ep2.adtrafficquality.google"

    policy.frame_ancestors :none
    policy.base_uri :self    # <base> 주입을 통한 relative URL 탈취 방지
    policy.form_action :self # 폼 제출지 self 고정
  end

  # CSP 강제 적용 모드 (enforce)
  config.content_security_policy_report_only = false
end
