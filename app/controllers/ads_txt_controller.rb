# ads.txt를 컨트롤러에서 서빙 — Cloudflare 1년 캐시 우회
# Google AdSense 크롤러가 항상 최신 파일을 가져갈 수 있도록 짧은 TTL 적용
class AdsTxtController < ApplicationController
  def show
    # 1일 캐시: Google AdSense 크롤러가 변경사항을 빠르게 인식
    response.headers["Cache-Control"] = "public, max-age=86400"
    response.headers["CDN-Cache-Control"] = "max-age=86400"

    render plain: ads_txt_content, content_type: "text/plain"
  end

  private

  def ads_txt_content
    "google.com, ca-pub-6241798439911569, DIRECT, f08c47fec0942fa0\n"
  end
end
