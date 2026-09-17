# frozen_string_literal: true

require "test_helper"

# 토픽 잔여 정정 회귀 (2026-09-17 G-44·G-38). 원문: 회계관계직원 등의 책임에 관한 법률, 감사원법 제36조, 복무규정 [별표 2].
class TopicResidualFixesTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918080000_topic_residual_fixes.rb")
  AUDITED = Rails.root.join("test/fixtures/files/accounting_officers_regulation_0917.txt").read

  setup do
    base = { category: "hr", sector: "common" }
    Topic.new(base.merge(slug: "accounting-officers", name: "회계관계공무원", regulation_content: AUDITED)).save!(validate: false)
    Topic.new(base.merge(slug: "travel-expense", name: "여비", regulation_content: "- 지방공무원: 「지방공무원 여비규정」 적용 (유사 구조)\n")).save!(validate: false)
    Topic.new(base.merge(slug: "special-leave", name: "특별휴가", interpretation_content: "**[질의]** 조부모 사망 특별휴가가 5일이라면, 외조부모(외할아버지·외할머니)도 동일하게 5일인지?\n")).save!(validate: false)
  end

  def field(slug, column) = Topic.find_by!(slug: slug).public_send(column)

  test "NORMAL: 없는 법령명이 실제 법령명으로, 원문 미확인 운영지침이 사라진다" do
    capture_io { load MIGRATION }
    text = field("accounting-officers", :regulation_content)
    assert_not_includes text, "회계관계공무원 등의 책임에 관한 법률"
    assert_not_includes text, "운영지침"
    assert_includes text, "「회계관계직원 등의 책임에 관한 법률」 제2조"
  end

  test "EDGE: 변상책임은 고의·중과실 요건, 불복은 재심의(«경과실 감면»·«심사청구» 아님)" do
    capture_io { load MIGRATION }
    text = field("accounting-officers", :regulation_content)
    assert_not_includes text, "경과실:"
    assert_not_includes text, "심사청구"
    assert_includes text, "재심의를 청구할 수 있다(「감사원법」 제36조제1항)"
  end

  test "LOWER_BOUND: 여비 탭의 없는 «지방공무원 여비규정»·특별휴가 질의 전제 «5일이라면»이 사라진다" do
    capture_io { load MIGRATION }
    assert_not_includes field("travel-expense", :regulation_content), "지방공무원 여비규정"
    assert_not_includes field("special-leave", :interpretation_content), "5일이라면"
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 한 곳이라도 감사 이후 바뀌었으면 전체 롤백, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=3/, out)
    ENV.delete("DRY_RUN")
    Topic.find_by!(slug: "special-leave").update_columns(interpretation_content: "운영자가 고친 질의")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal AUDITED, field("accounting-officers", :regulation_content), "부분 적용 금지"
  ensure
    ENV.delete("DRY_RUN")
  end
end
