# frozen_string_literal: true

require "test_helper"

# 여비 규정 탭 직급별 일비·식비 표 정정 회귀 (2026-09-17 G-37). 근거: 공무원 여비 규정 별표 2(2026.6.30.).
class TravelTableGradeValuesTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917200000_travel_table_grade_values.rb")
  STALE = "| 일비 | 출장 1일당 정액 (직급별 상이) |\n| 식비 | 출장 1일당 정액 (직급별 상이) |\n| 숙박비 | 실비 (상한액 범위 내) |\n\n" \
          "#### 직급별 일비·식비 기준 (별표 2)\n\n| 직급 구분 | 일비 (1일) | 식비 (1일) |\n|---------|-----------|-----------|\n" \
          "| 1~3급 (고위공무원) | 20,000원 | 25,000원 |\n| 4~5급 | 20,000원 | 25,000원 |\n| 6~9급, 기능직 | 25,000원 | 20,000원 |"

  setup do
    @topic = Topic.new(slug: "domestic-travel-allowance", name: "국내출장 여비", category: "travel", sector: "common",
                       regulation_content: "머리말\n\n#{STALE}\n\n※ 실제 금액은 별표 2 확인")
    @topic.save!(validate: false)
  end

  test "NORMAL: one row for all grades at 25,000원" do
    capture_io { load MIGRATION }
    text = @topic.reload.regulation_content
    assert_includes text, "| 모든 직급 | 25,000원 | 25,000원 |"
    assert_not_includes text, "20,000원"
  end

  test "EDGE: lodging caps follow 별표 2" do
    capture_io { load MIGRATION }
    assert_includes @topic.reload.regulation_content, "서울 100,000원 · 광역시 80,000원 · 그 밖 70,000원"
  end

  test "LOWER_BOUND: surrounding text is kept" do
    capture_io { load MIGRATION }
    assert @topic.reload.regulation_content.start_with?("머리말")
    assert @topic.regulation_content.end_with?("※ 실제 금액은 별표 2 확인")
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: missing table aborts" do
    @topic.update_columns(regulation_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
  end
end
