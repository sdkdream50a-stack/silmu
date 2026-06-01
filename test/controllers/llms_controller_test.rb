require "test_helper"

class LlmsControllerTest < ActionDispatch::IntegrationTest
  test "llms.txt returns 200 plain text (dynamic summary)" do
    get llms_url
    assert_response :success
    assert_equal "text/plain", response.media_type
  end

  test "llms.txt summary lists topics and audit case count dynamically" do
    get llms_url
    assert_includes response.body, "## 핵심 법령 가이드 (Topics"
    assert_includes response.body, "https://silmu.kr/topics/"
    assert_match(/감사사례 \d+건/, response.body)
  end

  test "llms-full.txt returns 200 plain text" do
    get llms_full_url
    assert_response :success
    assert_equal "text/plain", response.media_type
  end

  test "llms-full.txt includes AEO disclaimer block" do
    get llms_full_url
    assert_includes response.body, "법률자문이 아닙니다"
    assert_includes response.body, "law_base_date"
    assert_includes response.body, "https://silmu.kr/topics/"
  end

  test "llms-full.txt sets public cache headers" do
    get llms_full_url
    assert_match(/public/, response.headers["Cache-Control"].to_s)
  end
end
