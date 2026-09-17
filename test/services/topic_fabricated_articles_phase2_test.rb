# frozen_string_literal: true

require "test_helper"

# 토픽 가공 조문 정정 2차 회귀 (2026-09-17 G-36). 원문: law.go.kr.
class TopicFabricatedArticlesPhase2Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917160000_topic_fabricated_articles_phase2.rb")
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
    assert_operator TARGETS.size, :>=, 60
    capture_io { load MIGRATION }
    TARGETS.each do |slug, column, _|
      text = field(slug, column)
      assert text.start_with?("## 관련 조문 원문"), "#{slug}/#{column}"
      assert_includes text, "국가법령정보센터(law.go.kr)"
      assert_not_includes text, "① 가공 문구"
    end
  end

  test "EDGE: 계약보증금 면제는 원문 조문으로, 오인용 조문은 싣지 않는다" do
    capture_io { load MIGRATION }
    assert_includes field("performance-guarantee", :decree_content), "제53조(계약보증금 면제)"
    assert_not_includes field("vehicle-travel-allowance", :decree_content), "제46조(보수 결정의 원칙)"
    assert_includes field("contingency-fund", :decree_content), "제48조(예비비 사용의 제한)"
  end

  test "LOWER_BOUND: a field edited since the audit aborts the whole run" do
    Topic.find_by!(slug: "private-contract").update_columns(decree_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes field("performance-guarantee", :decree_content), "① 가공 문구", "부분 적용 금지"
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
    assert_includes field("performance-guarantee", :decree_content), "① 가공 문구"
  ensure
    ENV.delete("DRY_RUN")
  end
end
