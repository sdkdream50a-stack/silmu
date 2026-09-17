require "test_helper"

# 토픽 → 관련 도구 연결 회귀 (2026-09-17 업무흐름 감사 13).
# 종전: 매핑 없는 토픽은 전부 계약 도구로 떨어져 초과근무·연가·예산 토픽에 계약방식 도구가 붙었다.
class TopicRelatedToolsTest < ActionDispatch::IntegrationTest
  def show(slug:, category:)
    Topic.create!(name: "도구 #{slug}", slug: slug, category: category, sector: "common",
                  summary: "요약", commentary: "본문", keywords: "검사", published: false)
    host! "silmu.kr"
    get "/topics/#{slug}"
    assert_response :success
    # «바로 사용하기» 블록만 본다 — 전역 메뉴·서식 패널에도 도구 링크가 있어 페이지 전체로는 판정이 섞인다.
    section = response.body[/바로 사용하기<\/h3>(.*?)<\/div>\s*<\/div>\s*<% end %>|바로 사용하기\s*<\/h3>(.*?)(?=<!--|<\/aside>)/m]
    section.to_s
  end

  test "NORMAL: salary topic without mapping links pay calculators, not contract tools" do
    body = show(slug: "tools-salary-topic", category: "salary")
    assert_includes body, "/tools/overtime-calculator"
    assert_not_includes body, 'href="/tools/contract-method"'
  end

  test "EDGE: budget-carryover links the carryover/transfer checker instead of the estimator" do
    body = show(slug: "budget-carryover", category: "budget")
    assert_includes body, "/tools/budget-transfer-checker"
  end

  test "LOWER_BOUND: property topic gets no misleading contract tool" do
    body = show(slug: "tools-property-topic", category: "property")
    assert_not_includes body, 'href="/tools/contract-method"'
  end

  test "UPPER_BOUND: late-penalty links the tool that has the delay-penalty tab" do
    body = show(slug: "late-penalty", category: "contract")
    assert_includes body, "/tools/contract-guarantee"
  end

  test "EXCEPTION: every tool key used anywhere resolves to a route helper" do
    keys = (TopicConfig::TOPIC_TOOLS.values.flatten + TopicConfig::CATEGORY_DEFAULT_TOOLS.values.flatten).uniq
    helpers = Rails.application.routes.url_helpers
    keys.each do |k|
      assert TopicConfig::TOOL_DEFINITIONS.key?(k), "TOOL_DEFINITIONS 누락: #{k}"
      assert helpers.respond_to?("#{k}_path"), "route helper 없음: #{k}_path"
    end
  end
end
