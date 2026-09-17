# frozen_string_literal: true

require "test_helper"

# 조문 인용 문장 원문 불일치 정정 2차 회귀 (2026-09-17 G-37).
class CitationClaimFixesBatch2Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917210000_citation_claim_fixes_batch2.rb")
  JSONB = %i[faqs quick_stats sections].freeze

  def self.subs = eval(MIGRATION.read.split("# quick_stats 는")[0] + "\nsubs") # rubocop:disable Security/Eval

  setup do
    self.class.subs.group_by { |klass, slug, _, _| [ klass, slug ] }.each do |(klass, slug), entries|
      attrs = entries.to_h do |_, _, column, pairs|
        froms = pairs.map(&:first)
        [ column, JSONB.include?(column) ? froms.map { |f| { "answer" => f } } : froms.join("\n") ]
      end
      base = klass == Topic ? { name: slug, category: "budget", sector: "common" } : { title: slug }
      klass.new(base.merge(slug: slug).merge(attrs)).save!(validate: false)
    end
    Topic.find_by!(slug: "budget-settlement").update_columns(quick_stats: [
      { "label" => "출납 폐쇄", "note" => "지방재정법", "value" => "다음 연도 2월 10일" },
      { "label" => "의회 승인", "note" => "지방회계법 제14조", "value" => "다음 연도 8월 31일까지" },
      { "label" => "결산검사위원", "note" => "지방회계법 제14조", "value" => "지방의회 선임" }
    ])
  end

  def text(slug, column) = Topic.find_by!(slug: slug).public_send(column).to_json

  test "NORMAL: 일시차입은 의회 의결 필요(지방회계법 제24조), 부재 조문 인용 제거" do
    capture_io { load MIGRATION }
    assert_not_includes text("public-debt-management", :faqs), "제41조의3"
    assert_includes text("public-debt-management", :faqs), "지방회계법 제24조"
    assert_not_includes text("public-debt-management", :interpretation_content), "의결 없이 가능"
  end

  test "EDGE (병가): 병가 공제는 제17조 제5항 · 1/2 공제 없음" do
    capture_io { load MIGRATION }
    assert_not_includes text("sick-leave", :interpretation_content), "1/2"
    assert_includes text("sick-leave", :interpretation_content), "제17조 제5항"
  end

  test "LOWER_BOUND: 결산 quick_stats 는 label 로만 고치고 검사위원 항목은 그대로" do
    capture_io { load MIGRATION }
    stats = Topic.find_by!(slug: "budget-settlement").quick_stats
    assert_equal "지방자치법 제150조", stats.find { |i| i["label"] == "의회 승인" }["note"]
    assert_not_includes stats.to_json, "8월 31일"
    assert_equal "지방회계법 제14조", stats.find { |i| i["label"] == "결산검사위원" }["note"]
  end

  test "EDGE: 명절휴가비 기준일은 설날·추석날 현재 (전월 말일 아님)" do
    capture_io { load MIGRATION }
    %i[faqs practical_tips qa_content quick_stats].each { |c| assert_not_includes text("holiday-bonus", c), "전월 말일", c }
    assert_includes text("holiday-bonus", :faqs), "지급기준일"
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/substitutions=0/, out)
  end

  test "EXCEPTION: missing stale text aborts the whole run" do
    Topic.find_by!(slug: "sick-leave").update_columns(interpretation_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes text("public-debt-management", :faqs), "제41조의3", "부분 적용 금지"
  end
end
