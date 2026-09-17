# frozen_string_literal: true

require "test_helper"

# 명절휴가비 지급기준일 잔존 정정 회귀 (2026-09-17 G-37). 원문: 공무원수당 등에 관한 규정 제18조의3.
class HolidayBonusBasisDateTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917220000_holiday_bonus_basis_date.rb")

  setup do
    @topic = Topic.new(slug: "holiday-bonus", name: "명절 휴가비", category: "salary", sector: "common",
                       decree_content: "| 상황 | 처리 |\n| 기준일(전월 말일) 재직 중인 경우 | 전액 지급 |\n| 기준일 전에 퇴직한 경우 | 지급 제외 |",
                       rule_content: "봉급이 변경된 경우\n- 기준일(전월 말일) 현재의 봉급월액 적용\n- 기타")
    @topic.save!(validate: false)
  end

  test "NORMAL: both tabs use 설날·추석날 as the basis date" do
    capture_io { load MIGRATION }
    @topic.reload
    assert_not_includes @topic.decree_content, "전월 말일"
    assert_not_includes @topic.rule_content, "전월 말일"
    assert_includes @topic.rule_content, "제18조의3 제2항"
  end

  test "EDGE: neighbouring table rows are untouched" do
    capture_io { load MIGRATION }
    assert_includes @topic.reload.decree_content, "| 기준일 전에 퇴직한 경우 | 지급 제외 |"
  end

  test "LOWER_BOUND: DRY_RUN writes nothing" do
    ENV["DRY_RUN"] = "1"
    capture_io { load MIGRATION }
    assert_includes @topic.reload.rule_content, "전월 말일"
  ensure
    ENV.delete("DRY_RUN")
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: unexpected text aborts" do
    @topic.update_columns(rule_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
  end
end
