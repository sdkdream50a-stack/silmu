# frozen_string_literal: true

require "test_helper"

# «질의·회신 예시» 개별 검증 3차 정정 회귀 (2026-09-17 G-38). 원문: 지방계약법 제34조, 시행규칙 [별표 2].
class InterpretationRepliesBatch3Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918070000_interpretation_replies_batch3.rb")
  STR = /"(?:[^"\\]|\\.)*"/
  EDITS = MIGRATION.read.scan(/^  \[ (#{STR}), (#{STR}), (#{STR}) \]/)
                   .map { |row| row.map { |s| JSON.parse(s) } }.freeze

  setup do
    body = EDITS.map { |_, old, _| "**[회신]** #{old}\n" }.join("\n")
    Topic.new(slug: "qualification-failure", name: "적격심사 탈락", category: "contract", sector: "common", interpretation_content: body).save!(validate: false)
  end

  def reply = Topic.find_by!(slug: "qualification-failure").interpretation_content

  test "NORMAL: 이의신청 기한은 불이익을 받은 날부터 20일·안 날부터 15일" do
    capture_io { load MIGRATION }
    assert_includes reply, "불이익을 받은 날부터 20일 이내 또는 불이익을 받았음을 안 날부터 15일 이내"
    assert_not_includes reply, "탈락 통보 수령일로부터 10일"
  end

  test "EDGE: 재심 기관은 지방계약심의조정위원회(없는 «지방계약분쟁조정위원회» 아님)" do
    capture_io { load MIGRATION }
    assert_includes reply, "지방계약심의조정위원회에 재심을 청구"
    assert_not_includes reply, "지방계약분쟁조정위원회"
  end

  test "LOWER_BOUND: 거짓 서류 낙찰 제한기간은 별표 2 제10호가목대로 11개월 이상 1년 1개월 미만" do
    capture_io { load MIGRATION }
    assert_includes reply, "11개월 이상 1년 1개월 미만"
    assert_not_includes reply, "1년 이상 2년 이하"
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 운영자가 고친 회신이면 전체 롤백, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=2/, out)
    ENV.delete("DRY_RUN")
    Topic.find_by!(slug: "qualification-failure").update_columns(interpretation_content: "운영자가 고친 회신")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal "운영자가 고친 회신", reply
  ensure
    ENV.delete("DRY_RUN")
  end
end
