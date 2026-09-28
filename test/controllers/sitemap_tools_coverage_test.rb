require "test_helper"

# sitemap 도구 누락 회귀 (2026-09-17 전수감사). sitemap 뷰는 도구 URL 을 손으로 적어
# /tools/standard-term-checker 가 빠져 있었다. 레지스트리의 모든 /tools/* 경로가 sitemap 에 있어야 한다.
class SitemapToolsCoverageTest < ActionDispatch::IntegrationTest
  test "every registered /tools path is listed in sitemap.xml" do
    host! "silmu.kr"
    get "/sitemap.xml"
    assert_response :success

    helper = controller.view_context
    tool_paths = helper.tools_registry.map { |t| t[:path].to_s }.select { |p| p.start_with?("/tools/") }.uniq
    assert_operator tool_paths.size, :>=, 30, "레지스트리에서 도구 경로를 읽지 못하면 이 검사는 공허하다"

    missing = tool_paths.reject { |p| response.body.include?("<loc>https://silmu.kr#{p}</loc>") }
    assert_empty missing, "sitemap 누락: #{missing.join(', ')}"
  end
end

# 색인 가능·self-canonical 허브인데 sitemap 에서 빠져 있던 4개 (2026-09-28 비도구 신뢰 감사 08).
class SitemapHubCoverageTest < ActionDispatch::IntegrationTest
  test "indexable hub pages are listed in sitemap.xml" do
    host! "silmu.kr"
    get "/sitemap.xml"
    assert_response :success

    missing = %w[/school-office /school-office/calendar /guides/resources /ai-assistant]
                .reject { |p| response.body.include?("<loc>https://silmu.kr#{p}</loc>") }
    assert_empty missing, "sitemap 누락: #{missing.join(', ')}"
  end
end
