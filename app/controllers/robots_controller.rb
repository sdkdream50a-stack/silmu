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

      # 쿼리 파라미터 필터 페이지 — 크롤 예산 절약 (canonical로 처리 중)
      Disallow: /audit-cases?
      Disallow: /guides?
      Disallow: /chatbot/search?
      Disallow: /tools/official-document?
      Disallow: /?sector=

      # AI 검색/크롤 봇 명시적 허용 (GEO 최적화)
      # 주의: Cloudflare "Managed robots.txt" 설정이 활성화된 경우 이 규칙보다
      # Cloudflare 블록이 우선 적용됨 → Cloudflare 대시보드에서 비활성화 필요
      User-agent: GPTBot
      Allow: /

      User-agent: OAI-SearchBot
      Allow: /

      User-agent: ChatGPT-User
      Allow: /

      User-agent: PerplexityBot
      Allow: /

      User-agent: Google-Extended
      Allow: /

      User-agent: ClaudeBot
      Allow: /

      User-agent: anthropic-ai
      Allow: /

      User-agent: Claude-Web
      Allow: /

      User-agent: Bingbot
      Allow: /

      User-agent: CCBot
      Allow: /

      User-agent: Bytespider
      Allow: /

      Sitemap: https://silmu.kr/sitemap.xml
      Sitemap: https://exam.silmu.kr/sitemap.xml

      # IndexNow 키 파일 허용
      Allow: /af70a5ade3fa44588a1e92879ecbe8d5.txt
    ROBOTS
  end
end
