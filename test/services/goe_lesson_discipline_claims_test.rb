# frozen_string_literal: true

require "test_helper"

# 사례집 재구성 사례 교훈 절 징계·변상 단정 정정 회귀 (2026-09-17 G-13).
# 근거: 회계관계직원 등의 책임에 관한 법률 제4조, 지방공무원법 제70조·제71조①.
class GoeLessonDisciplineClaimsTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918020000_goe_lesson_discipline_claims.rb")
  STR = /"(?:[^"\\]|\\.)*"/
  EDITS = MIGRATION.read.scan(/^  \[ (#{STR}), :(\w+), (#{STR}), (#{STR}) \]/)
                   .map { |slug, column, old, new| [ JSON.parse(slug), column.to_sym, JSON.parse(old), JSON.parse(new) ] }.freeze

  setup do
    EDITS.group_by(&:first).each do |slug, list|
      attrs = { detail: "## 처분 결과\n\n- 원문 처분\n", lesson: "## 교훈\n\n" }
      list.each { |_, column, old, _| attrs[column] = "#{attrs[column]}#{old}\n끝.\n" }
      AuditCase.new({ slug: slug, title: slug, issue: "지적", category: "회계", severity: "보통", sector: "edu" }.merge(attrs)).save!(validate: false)
    end
  end

  def case_text(slug) = AuditCase.find_by!(slug: slug).then { |c| "#{c.detail}\n#{c.lesson}" }

  test "NORMAL: 건수별 처분 등급표가 사라지고 공식 기준 미확인 문장이 들어간다" do
    capture_io { load MIGRATION }
    %w[goe-2021-contract-review-omission goe-2021-daily-audit-89-cases].each do |slug|
      text = case_text(slug)
      assert_not_includes text, "| 다발"
      assert_includes text, "위반 건수별 처분 등급을 정한 공식 기준은 확인되지 않았으며"
    end
    assert_not_includes case_text("goe-2021-daily-audit-89-cases"), "감독 의무 불이행 (견책)"
  end

  test "EDGE: 강등 효력은 지방공무원법 제71조① 원문대로 보수 전액 감액" do
    capture_io { load MIGRATION }
    text = case_text("goe-2021-suspense-cash-embezzlement")
    assert_includes text, "그 기간 중 보수는 전액을 감합니다"
    assert_not_includes text, "1/3"
    assert_not_includes text, "두 번째로 무거운"
    assert_includes text, "재발 방지를 위해 출납원 본인 보호의 핵심은"
  end

  test "LOWER_BOUND: 모든 단정형 «대상이 됩니다» 징계 문장이 가능성·요건형으로 바뀐다" do
    assert_operator EDITS.size, :>=, 25
    capture_io { load MIGRATION }
    EDITS.each do |slug, _, old, new|
      text = case_text(slug)
      assert_not_includes text, old, slug
      assert_includes text, new, slug
    end
    assert_no_match(/견책 이상 (?:처분|징계)[^.]*(?:대상이 됩니다|받게 됩니다)/, AuditCase.pluck(:lesson, :detail).flatten.join("\n"))
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 본문이 감사 이후 바뀐 사례를 만나면 전체 롤백, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=#{EDITS.size}/, out)
    ENV.delete("DRY_RUN")
    AuditCase.find_by!(slug: "goe-2021-payment-processing-improper").update_columns(lesson: "운영자가 고친 교훈")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes case_text("goe-2021-contract-review-omission"), "| 다발", "부분 적용 금지"
  ensure
    ENV.delete("DRY_RUN")
  end
end
