require "test_helper"

# 토픽 «서식/양식» 탭 카테고리 분기 회귀 (2026-09-17 업무흐름 감사 13 W-05).
# 종전: 전용 패널이 없는 모든 토픽(급여·복무·예산 등)에 수의계약 사유서·견적서 서식이 붙었다.
class TopicFormsPanelTest < ActionDispatch::IntegrationTest
  def forms_tab(slug:, category:)
    Topic.create!(name: "서식 #{slug}", slug: slug, category: category, sector: "common",
                  summary: "요약", commentary: "본문", keywords: "검사", published: false)
    host! "silmu.kr"
    get "/topics/#{slug}"
    assert_response :success
    response.body[/<div class="tab-panel" data-tab="forms">(.*?)<!-- 실무자 해설/m, 1].to_s
  end

  test "NORMAL: salary topic forms tab has no contract forms" do
    tab = forms_tab(slug: "forms-salary-topic", category: "salary")
    assert_not_includes tab, "/forms/수의계약사유서.html"
    assert_not_includes tab, "수의계약 사유서 작성 가이드"
    assert_includes tab, 'data-forms-panel="neutral"'
  end

  test "LOWER_BOUND (양성대조): contract topic keeps the contract forms" do
    tab = forms_tab(slug: "forms-contract-topic", category: "contract")
    assert_includes tab, "/forms/수의계약사유서.html"
    assert_not_includes tab, 'data-forms-panel="neutral"'
  end

  test "EDGE: neutral panel links category tools and the template list" do
    tab = forms_tab(slug: "forms-duty-topic", category: "duty")
    assert_includes tab, "/tools/annual-leave-calculator"
    assert_includes tab, 'href="/templates"'
  end

  test "UPPER_BOUND: slug-specific panel (budget-carryover) is unchanged" do
    tab = forms_tab(slug: "budget-carryover", category: "budget")
    assert_not_includes tab, 'data-forms-panel="neutral"'
    assert_not_includes tab, "/forms/수의계약사유서.html"
  end

  test "EXCEPTION: unknown category still renders without contract forms" do
    tab = forms_tab(slug: "forms-other-topic", category: "other")
    assert_not_includes tab, "/forms/수의계약사유서.html"
  end
end
