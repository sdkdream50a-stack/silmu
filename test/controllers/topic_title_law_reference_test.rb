require "test_helper"

# <title> 근거 법령 라벨 회귀 (2026-09-17 전수감사 SEO P0).
# 운영 실측: /topics/local-tax-levy 제목이 "… — 지방계약법 근거…" 였다(지방세는 지방계약법과 무관).
class TopicTitleLawReferenceTest < ActionDispatch::IntegrationTest
  def title_for(category:, sector: nil, slug:)
    Topic.create!(name: "제목검사 #{slug}", slug: slug, category: category, sector: sector || "common",
                  summary: "요약", commentary: "본문", keywords: "검사", published: false)
    host! "silmu.kr"
    get "/topics/#{slug}"
    assert_response :success
    response.body[%r{<title>([^<]*)</title>}, 1]
  end

  test "NORMAL: contract topic keeps 지방계약법" do
    assert_includes title_for(category: "contract", slug: "title-contract"), "지방계약법"
  end

  test "EDGE: budget/expense topics are not labelled 지방계약법" do
    %w[budget expense].each do |cat|
      title = title_for(category: cat, slug: "title-#{cat}")
      assert_not_includes title, "지방계약법", cat
      assert_includes title, "지방재정 법령", cat
    end
  end

  test "LOWER_BOUND: education-sector contract topic still says 지방계약법" do
    assert_includes title_for(category: "contract", sector: "edu", slug: "title-edu-contract"), "지방계약법"
  end

  test "UPPER_BOUND: education-sector budget topic says 교육재정 법령" do
    assert_includes title_for(category: "budget", sector: "edu", slug: "title-edu-budget"), "교육재정 법령"
  end

  test "EXCEPTION: other category falls back to a neutral label" do
    title = title_for(category: "other", slug: "title-other")
    assert_not_includes title, "지방계약법"
    assert_includes title, "관계 법령"
  end
end
