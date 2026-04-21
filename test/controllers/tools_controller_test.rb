require "test_helper"

class ToolsControllerTest < ActionDispatch::IntegrationTest
  test "tools index returns 200" do
    get tools_url
    assert_response :success
  end
end
