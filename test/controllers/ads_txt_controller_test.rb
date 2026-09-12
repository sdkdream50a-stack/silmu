require "test_helper"

class AdsTxtControllerTest < ActionDispatch::IntegrationTest
  test "serves the authorized seller declaration" do
    host! "silmu.kr"

    get "/ads.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "google.com, pub-6241798439911569, DIRECT, f08c47fec0942fa0"
  end

  # 2026-03-27 c6ee9b0 회귀 — ca-pub 접두사가 AdSense 승인 오류를 냈다.
  # dd547a1 버전을 그대로 복원하면 이 버그가 되살아난다.
  test "publisher id has no ca- prefix" do
    host! "silmu.kr"

    get "/ads.txt"

    refute_includes response.body, "ca-pub-"
  end

  # Cloudflare 1년 캐시 우회가 이 컨트롤러의 존재 이유다(dd547a1).
  test "short ttl so adsense crawler sees changes" do
    host! "silmu.kr"

    get "/ads.txt"

    assert_includes response.headers["Cache-Control"].to_s, "max-age=86400"
  end
end
