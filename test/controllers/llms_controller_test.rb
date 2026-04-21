require "test_helper"

class LlmsControllerTest < ActionDispatch::IntegrationTest
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
