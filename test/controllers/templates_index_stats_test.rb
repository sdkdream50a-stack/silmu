require "test_helper"

# 양식 목록 hero 수치·필터 탭 회귀 (2026-09-28 비도구 신뢰 감사 05).
# 종전: hero 가 23 / 5 / 3 을 하드코딩(실제 26 / 4 / 4)하고, 양식 0건인 «품의서» 탭을 노출했다.
class TemplatesIndexStatsTest < ActionDispatch::IntegrationTest
  TEMPLATES = TemplatesController::TEMPLATES

  test "hero 수치는 TEMPLATES 데이터에서 계산된다" do
    get "/templates"
    assert_response :success
    stats = css_select(".text-2xl.font-bold").map { |n| n.text.strip }
    assert_equal [
      TEMPLATES.size.to_s,
      TEMPLATES.map { |t| t[:category] }.uniq.size.to_s,
      TEMPLATES.flat_map { |t| t[:formats] }.uniq.size.to_s
    ], stats.first(3)
    assert_select "#item-count", TEMPLATES.size.to_s
  end

  test "필터 탭은 양식이 있는 카테고리만 노출한다" do
    get "/templates"
    tabs = css_select("#category-tabs .tab-btn").map { |n| n["data-category"] } - [ "전체" ]
    categories = TEMPLATES.map { |t| t[:category] }.uniq
    assert_empty tabs - categories, "양식 0건 탭 노출: #{(tabs - categories).inspect}"
    assert_empty categories - tabs, "탭 누락: #{(categories - tabs).inspect}"
  end
end
