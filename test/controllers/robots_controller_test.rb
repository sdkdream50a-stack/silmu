require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  test "main host only advertises main sitemap" do
    host! "silmu.kr"

    get "/robots.txt"

    assert_response :success
    assert_includes response.body, "Sitemap: https://silmu.kr/sitemap.xml"
    refute_includes response.body, "Sitemap: https://exam.silmu.kr/sitemap.xml"
  end

  test "exam host only advertises exam sitemap" do
    host! "exam.silmu.kr"

    get "/robots.txt"

    assert_response :success
    assert_includes response.body, "Sitemap: https://exam.silmu.kr/sitemap.xml"
    refute_includes response.body, "Sitemap: https://silmu.kr/sitemap.xml"
  end
end
