require "test_helper"

# 2026-09-12 도구 사용 계측(tool_start/tool_complete) 회귀.
# 계측 스니펫은 /tools 에서만 나가야 한다 — 다른 페이지에 새면 tool_id 가 오염된다.
class ToolAnalyticsTest < ActionDispatch::IntegrationTest
  test "tool pages carry the tool analytics snippet" do
    host! "silmu.kr"

    get "/tools/budget-execution-rate"

    assert_response :success
    assert_includes response.body, '"tool_start"'
    assert_includes response.body, '"tool_complete"'
  end

  # 음성 대조 — 위 양성이 통과할 때만 의미가 있다.
  test "non-tool pages do not carry it" do
    host! "silmu.kr"

    get "/guides/#{guides(:one).slug}"

    assert_response :success
    refute_includes response.body, '"tool_complete"'
  end

  # tool_complete 는 #result-area 관례에 의존한다. 그 관례가 사라지면
  # 이벤트가 조용히 0 이 되므로 앵커를 고정한다(실측: 21개 중 5개만 이 관례를 쓴다).
  test "result-area anchor still exists on an instrumented tool" do
    host! "silmu.kr"

    get "/tools/budget-execution-rate"

    assert_includes response.body, 'id="result-area"',
                    "#result-area 가 사라졌다 — tool_complete 가 영원히 0 이 된다"
  end
end
