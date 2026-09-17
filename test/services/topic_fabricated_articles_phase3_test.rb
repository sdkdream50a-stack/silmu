# frozen_string_literal: true

require "test_helper"

# 토픽 가공 조문 정정 3차 회귀 (2026-09-17 G-36). 원문: law.go.kr.
class TopicFabricatedArticlesPhase3Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917190000_topic_fabricated_articles_phase3.rb")
  TARGETS = MIGRATION.read.scan(/^  \[ "([a-z0-9-]+)", :(\w+), ("(?:[^"\\]|\\.)*"), <<~'MD' \]/)
                     .map { |slug, column, fp| [ slug, column.to_sym, JSON.parse(fp) ] }.freeze

  setup do
    TARGETS.group_by(&:first).each do |slug, entries|
      attrs = entries.to_h { |_, column, fp| [ column, "#{fp}\n① 가공 문구" ] }
      Topic.new({ slug: slug, name: slug, category: "contract", sector: "common" }.merge(attrs)).save!(validate: false)
    end
  end

  def field(slug, column) = Topic.find_by!(slug: slug).public_send(column)

  test "NORMAL: every target field becomes verbatim article text with a source line" do
    assert_equal 9, TARGETS.size
    capture_io { load MIGRATION }
    TARGETS.each do |slug, column, _|
      text = field(slug, column)
      assert text.start_with?("## 관련 조문 원문"), "#{slug}/#{column}"
      assert_includes text, "국가법령정보센터(law.go.kr)"
      assert_not_includes text, "① 가공 문구"
    end
  end

  test "EDGE: 명절휴가비는 원문 기준(지급기준일 월봉급액 60퍼센트), 원문 인용 필드 2건은 대상 아님" do
    capture_io { load MIGRATION }
    assert_includes field("holiday-bonus", :law_content), "월봉급액의 60퍼센트"
    assert_not_includes field("holiday-bonus", :law_content), "명절 전월 말일"
    slugs = TARGETS.map(&:first)
    assert_not_includes slugs, "mas-contract"
    assert_not_includes slugs, "fence-installation"
  end

  test "LOWER_BOUND: a field edited since the audit aborts the whole run" do
    Topic.find_by!(slug: "subcontract").update_columns(decree_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes field("holiday-bonus", :law_content), "① 가공 문구", "부분 적용 금지"
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: DRY_RUN writes nothing" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=#{TARGETS.size}/, out)
    assert_includes field("holiday-bonus", :law_content), "① 가공 문구"
  ensure
    ENV.delete("DRY_RUN")
  end
end
