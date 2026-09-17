# frozen_string_literal: true

require "test_helper"

# 경기도교육청 감사사례집 재구성 사례 처분 절 정정 회귀 (2026-09-17 G-13).
class GoeCasebookDispositionsTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918000000_goe_casebook_dispositions.rb")
  SLUGS = MIGRATION.read.scan(/^  \[ "(goe-2021-[a-z0-9-]+)", "([^"]+)" \]/).to_h.freeze

  def detail(extra = "")
    "## 사건 개요\n\n2024년 10월, ○○학교 담당자가 절차를 어겼습니다.\n\n### 처분 결과\n\n- 행정실장: 견책\n- 형사 고발\n#{extra}\n## 사건이 주는 의미\n\n교훈."
  end

  setup do
    SLUGS.each_key do |slug|
      AuditCase.new(slug: slug, title: slug, detail: detail, issue: "지적", category: "회계", severity: "보통", sector: "edu").save!(validate: false)
    end
  end

  def target = AuditCase.find_by!(slug: "goe-2021-suspense-cash-embezzlement")

  test "NORMAL: 처분 절은 사례집 원문 처분만 남긴다" do
    capture_io { load MIGRATION }
    assert_equal "관련자 강등", SLUGS["goe-2021-suspense-cash-embezzlement"]
    assert_includes target.detail, "사례집 원문 처분: «관련자 강등»"
    assert_not_includes target.detail, "견책"
  end

  test "EDGE: 사건 개요의 창작 연도 머리를 지우고 다음 절은 보존" do
    capture_io { load MIGRATION }
    assert_not_includes target.detail, "2024년 10월"
    assert_includes target.detail, "○○학교 담당자가 절차를 어겼습니다."
    assert_includes target.detail, "## 사건이 주는 의미\n\n교훈."
  end

  test "LOWER_BOUND: 50건 대상, 일치율 낮은 사례는 대상에서 빠짐" do
    assert_equal 50, SLUGS.size
    assert_not_includes SLUGS.keys, "goe-2021-suspension-pay-deduction"
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: a case without a 처분 section aborts the whole run" do
    target.update_columns(detail: "## 사건 개요\n\n처분 절 없음")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes AuditCase.find_by!(slug: SLUGS.keys.first).detail, "견책", "부분 적용 금지"
  end
end
