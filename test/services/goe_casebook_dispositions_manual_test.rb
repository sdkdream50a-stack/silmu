# frozen_string_literal: true

require "test_helper"

# 사례집 자동 매칭 미달 12건 수기 대조 정정 회귀 (2026-09-17 G-13).
class GoeCasebookDispositionsManualTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918010000_goe_casebook_dispositions_manual.rb")
  AUTO = Rails.root.join("db/content_migrations/20260918000000_goe_casebook_dispositions.rb")
  SLUGS = MIGRATION.read.scan(/^  "(goe-2021-[a-z0-9-]+)" =>/).flatten.freeze

  setup do
    SLUGS.each do |slug|
      detail = "## 사건 개요\n\n2025년 3월, ○○학교에서 위반.\n\n### 처분 결과\n\n- 행정실장: 견책\n\n## 교훈\n\n내용."
      AuditCase.new(slug: slug, title: slug, detail: detail, issue: "지적", category: "회계", severity: "보통", sector: "edu").save!(validate: false)
    end
  end

  def detail(slug) = AuditCase.find_by!(slug: slug).detail

  test "NORMAL: 합본 사례는 항목별 원문 처분을 모두 적는다" do
    capture_io { load MIGRATION }
    text = detail("goe-2021-public-property-occupation-violation")
    assert_includes text, "관련자(행정실장) 경고, 업무담당자 및 학교장 주의, 변상금 세입조치"
    assert_not_includes text, "견책"
  end

  test "EDGE: 창작 연도 머리 삭제·다음 절 보존" do
    capture_io { load MIGRATION }
    text = detail("goe-2021-football-team-extension-contract")
    assert_not_includes text, "2025년 3월"
    assert_includes text, "«관련자 경고(요구)»"
    assert_includes text, "## 교훈\n\n내용."
  end

  test "LOWER_BOUND: 12건이고 자동 매칭 50건과 겹치지 않는다" do
    assert_equal 12, SLUGS.size
    auto = AUTO.read.scan(/^  \[ "(goe-2021-[a-z0-9-]+)"/).flatten
    assert_empty SLUGS & auto
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: missing section aborts" do
    AuditCase.find_by!(slug: SLUGS.first).update_columns(detail: "처분 절 없음")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
  end
end
