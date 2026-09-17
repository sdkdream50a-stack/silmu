require "test_helper"

# 양식 상세 «관련 가이드» 회귀 (2026-09-17 업무흐름 감사 13 W-07).
# 종전: 모든 양식이 guide_path(1)("/guides/1")을 걸어 가이드 목록으로 302 착지했다.
class TemplateRelatedTopicTest < ActionDispatch::IntegrationTest
  def topic(slug, name)
    Topic.create!(name: name, slug: slug, category: "contract", sector: "common",
                  summary: "요약", commentary: "본문", keywords: "검사", published: true)
  end

  test "NORMAL: 수의계약 사유서 양식 links the justification topic" do
    topic("private-contract-justification", "수의계약 사유서 작성법")
    get "/templates/18"
    assert_response :success
    assert_includes response.body, 'href="/topics/private-contract-justification"'
    assert_not_includes response.body, 'href="/guides/1"'
  end

  test "LOWER_BOUND: budget carryover form links budget-carryover" do
    topic("budget-carryover", "예산이월")
    get "/templates/26"
    assert_includes response.body, 'href="/topics/budget-carryover"'
  end

  test "EDGE: unmapped form (회의록) renders without a related guide block" do
    get "/templates/23"
    assert_response :success
    assert_not_includes response.body, "관련 가이드</h3>"
  end

  test "UPPER_BOUND: mapped but unpublished topic is not linked (no 404 link)" do
    topic("dual-quote", "2인 이상 견적").update!(published: false)
    get "/templates/19"
    assert_not_includes response.body, 'href="/topics/dual-quote"'
  end

  test "EXCEPTION: every mapped id is a real template" do
    ids = TemplatesController::TEMPLATES.map { |t| t[:id] }
    assert_empty TemplatesController::RELATED_TOPIC_SLUGS.keys - ids
  end
end
