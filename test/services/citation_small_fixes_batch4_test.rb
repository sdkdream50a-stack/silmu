# frozen_string_literal: true

require "test_helper"

# 조문 인용 소규모 정정 4차 회귀 (2026-09-17 G-37).
class CitationSmallFixesBatch4Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917233000_citation_small_fixes_batch4.rb")

  setup do
    topic("late-penalty", faqs: [ { "answer" => "지방계약법 시행규칙 제75조 기준: 공사 0.5/1,000, 물품 제조·구매 0.8/1,000, 용역(수리·가공 등) 1.3/1,000, 운송·보관 등 2.5/1,000, 임대차 1/1,000 (1일당). 최고한도는 계약금액의 30%입니다." } ])
    topic("supplementary-budget", decree_content: "| 구분 | 처리 기간 |\n| 임시회 소집 | 의장은 소집 요구일로부터 15일 이내 소집 (지방자치법 제56조) |")
    topic("budget-compilation", quick_stats: [ { "note" => "지방재정법 시행령 제37조", "label" => "행안부 편성기준", "value" => "매년 5월 31일까지 통보" },
                                              { "note" => "지방자치법 제142조", "label" => "예산안 제출", "value" => "시·도 50일 전" } ])
  end

  def topic(slug, **attrs) = Topic.new({ slug: slug, name: slug, category: "budget", sector: "common" }.merge(attrs)).tap { |t| t.save!(validate: false) }

  test "NORMAL: 지연배상금률에 원문 없는 임대차 요율이 없다" do
    capture_io { load MIGRATION }
    faqs = Topic.find_by!(slug: "late-penalty").faqs.to_json
    assert_not_includes faqs, "임대차"
    assert_includes faqs, "양곡가공 2.5/1,000"
  end

  test "EDGE: 임시회 소집 근거는 지방자치법 제54조 제3항" do
    capture_io { load MIGRATION }
    assert_includes Topic.find_by!(slug: "supplementary-budget").decree_content, "제54조 제3항"
  end

  test "LOWER_BOUND: 없는 시행령 제37조 인용과 미확인 날짜가 빠지고 다른 항목은 그대로" do
    capture_io { load MIGRATION }
    stats = Topic.find_by!(slug: "budget-compilation").quick_stats
    assert_not_includes stats.to_json, "시행령 제37조"
    assert_equal "시·도 50일 전", stats[1]["value"]
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: missing text aborts" do
    Topic.find_by!(slug: "late-penalty").update_columns(faqs: [ { "answer" => "고친 본문" } ])
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
  end
end
