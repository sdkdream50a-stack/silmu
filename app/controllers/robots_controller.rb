# robots.txt를 컨트롤러에서 서빙 — Cloudflare 캐시 우회
class RobotsController < ApplicationController
  def show
    # no-store: Cloudflare가 캐시하지 않도록 강제
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Surrogate-Control"] = "no-store"
    response.headers["CDN-Cache-Control"] = "no-store"

    render plain: robots_content, content_type: "text/plain"
  end

  private

  def robots_content
    <<~ROBOTS
      User-agent: *
      Allow: /
      Disallow: /users/
      Disallow: /mypage
      Disallow: /calendar_data
      Disallow: /task_guides
      Disallow: /cdn-cgi/
      Disallow: /audit-cases/*/hwp

      # AI 검색/크롤 봇 명시적 허용 (GEO 최적화)
      User-agent: OAI-SearchBot
      Allow: /

      User-agent: ChatGPT-User
      Allow: /

      User-agent: PerplexityBot
      Allow: /

      User-agent: Google-Extended
      Allow: /

      User-agent: anthropic-ai
      Allow: /

      User-agent: Claude-Web
      Allow: /

      User-agent: CCBot
      Allow: /

      User-agent: Bytespider
      Allow: /

      Sitemap: https://silmu.kr/sitemap.xml
      Sitemap: https://exam.silmu.kr/sitemap.xml
    ROBOTS
  end
end
