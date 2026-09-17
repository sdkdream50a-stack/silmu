# frozen_string_literal: true

require "test_helper"

# DB 콘텐츠 부처명 개편 migration 회귀 (2026-09-17 G-20).
class MinistryRenameContentMigrationTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917130000_ministry_rename_content.rb")

  def topic(slug, **attrs)
    Topic.new({ slug: slug, name: slug, category: "contract", sector: "common" }.merge(attrs)).tap { |t| t.save!(validate: false) }
  end

  test "NORMAL: contract context becomes 재정경제부" do
    t = topic("mof-contract", commentary: "공동계약운용요령(기획재정부 계약예규)에서 정함")
    capture_io { load MIGRATION }
    assert_includes t.reload.commentary, "(재정경제부 계약예규)"
  end

  test "EDGE: budget/subsidy context becomes 기획예산처, contract wins when both appear nearby" do
    t = topic("mof-budget", commentary: "보조금 관리 기준(기획재정부 예규, 집행 세부기준) 확인",
                            qa_content: "적격심사 기준 서류: 기재부 예규 vs 행안부 예규")
    capture_io { load MIGRATION }
    t.reload
    assert_includes t.commentary, "(기획예산처 예규"
    assert_includes t.qa_content, "재정경제부 예규"
  end

  test "LOWER_BOUND: travel/fuel context is left for review" do
    t = topic("mof-travel", rule_content: "실제 주행거리에 기획재정부가 고시하는 유류비 단가를 곱한다")
    capture_io { load MIGRATION }
    assert_includes t.reload.rule_content, "기획재정부가 고시하는 유류비"
  end

  test "UPPER_BOUND: jsonb guide sections are renamed and a second run changes nothing" do
    g = Guide.new(slug: "mof-guide", title: "t", sections: { "items" => [ "국가계약법(기재부)·지방계약법(행안부)" ] })
    g.save!(validate: false)
    capture_io { load MIGRATION }
    first = g.reload.sections.to_json
    assert_includes first, "재정경제부"
    out, = capture_io { load MIGRATION }
    assert_equal first, g.reload.sections.to_json
    assert_match(/재정경제부=0 기획예산처=0/, out)
  end

  test "EXCEPTION: DRY_RUN writes nothing" do
    t = topic("mof-dry", commentary: "기획재정부 계약예규")
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN 재정경제부=1/, out)
    assert_includes t.reload.commentary, "기획재정부"
  ensure
    ENV.delete("DRY_RUN")
  end
end
