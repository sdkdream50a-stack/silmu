# robots.txt를 컨트롤러에서 서빙 — 짧은 캐시 TTL 적용 (Cloudflare 캐시 제어)
class RobotsController < ApplicationController
  def show
    expires_in 1.hour, public: true, stale_while_revalidate: 24.hours

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

      # AI 검색 봇 허용 (트래픽 유입)
      User-agent: OAI-SearchBot
      Allow: /

      User-agent: ChatGPT-User
      Allow: /

      User-agent: PerplexityBot
      Allow: /

      Sitemap: https://silmu.kr/sitemap.xml
      Sitemap: https://exam.silmu.kr/sitemap.xml
    ROBOTS
  end
end
