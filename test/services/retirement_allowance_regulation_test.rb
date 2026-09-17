# frozen_string_literal: true

require "test_helper"

# 퇴직수당 토픽 예규 탭 정정 회귀 (2026-09-17). 원문: 공무원연금법 제25조·제26조·제62조·제65조.
class RetirementAllowanceRegulationTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918050000_retirement_allowance_regulation.rb")
  AUDITED = Rails.root.join("test/fixtures/files/retirement_allowance_regulation_0917.txt").read

  setup do
    Topic.new(slug: "retirement-allowance", name: "퇴직수당", category: "hr", sector: "common", regulation_content: AUDITED).save!(validate: false)
  end

  def text = Topic.find_by!(slug: "retirement-allowance").regulation_content

  test "NORMAL: 없는 법령명과 원문 미확인 예규가 사라지고 공무원연금법 요지가 들어간다" do
    capture_io { load MIGRATION }
    assert_not_includes text, "공무원 퇴직급여법"
    assert_not_includes text, "퇴직수당 업무처리 지침"
    assert_includes text, "「공무원연금법」 제62조제1항"
  end

  test "EDGE: 파면은 «지급 제외»가 아니라 일부 감액(제65조)" do
    capture_io { load MIGRATION }
    assert_not_includes text, "지급 제외 대상"
    assert_includes text, "일부를 줄여 지급한다(제65조제1항)"
  end

  test "LOWER_BOUND: 합산 반납은 이자 가산, 합산기간은 퇴직수당에 불산입" do
    capture_io { load MIGRATION }
    assert_not_includes text, "이자는 가산하지 않는"
    assert_includes text, "퇴직수당을 지급할 때에는 재직기간에 합산하지 않는다(제25조제4항)"
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 감사 이후 운영자가 고친 본문은 덮어쓰지 않고 중단, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=1/, out)
    assert_equal AUDITED, text
    ENV.delete("DRY_RUN")
    Topic.find_by!(slug: "retirement-allowance").update_columns(regulation_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal "운영자가 고친 본문", text
  ensure
    ENV.delete("DRY_RUN")
  end
end
