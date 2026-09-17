require "test_helper"

# 학교회계 토픽 근거 법령 표시 (2026-09-17 G-28 F-14). 종전: budget 기본값 «지방재정법»이 학교회계 토픽에 붙었다.
class SchoolTopicLawBasisTest < ActionView::TestCase
  include SeoHelper

  def topic(slug, category = "budget") = Topic.new(slug: slug, category: category, sector: "edu")

  test "NORMAL: school-budget-compilation cites 초ㆍ중등교육법, not 지방재정법" do
    names = topic_legal_basis(topic("school-budget-compilation")).map { |l| l["name"] }
    assert_includes names, "초ㆍ중등교육법"
    assert_not_includes names, "지방재정법"
  end

  test "LOWER_BOUND (양성대조): ordinary budget topic keeps 지방재정법" do
    names = topic_legal_basis(topic("budget-execution")).map { |l| l["name"] }
    assert_includes names, "지방재정법"
  end

  test "EDGE: law card labels point at 제30조의2·3" do
    assert_equal "초·중등교육법 제30조의2·3", topic_law_card_labels(topic("school-budget-compilation"))[:law]
  end

  test "UPPER_BOUND: legislation urls have no spaces" do
    topic_legal_basis(topic("school-budget-compilation")).each { |l| assert_not_includes l["url"], " " }
  end

  test "EXCEPTION: nil topic still returns contract default" do
    assert topic_legal_basis(nil).any?
  end
end
