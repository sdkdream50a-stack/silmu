# frozen_string_literal: true

require "test_helper"

# «질의·회신 예시» 개별 검증 2차 정정 회귀 (2026-09-17 G-38).
class InterpretationRepliesBatch2Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918040000_interpretation_replies_batch2.rb")
  STR = /"(?:[^"\\]|\\.)*"/
  EDITS = MIGRATION.read.scan(/^  \[ (#{STR}), (#{STR}), (#{STR}) \]/)
                   .map { |row| row.map { |s| JSON.parse(s) } }.freeze

  setup do
    EDITS.group_by(&:first).each do |slug, list|
      body = list.map { |_, old, _| "#{old}\n" }.join("\n")
      Topic.new(slug: slug, name: slug, category: "contract", sector: "common", interpretation_content: "## 질의·회신\n\n#{body}").save!(validate: false)
    end
  end

  def reply(slug) = Topic.find_by!(slug: slug).interpretation_content

  test "NORMAL: 외조부모 사망 휴가는 별표 2대로 3일" do
    capture_io { load MIGRATION }
    assert_includes reply("special-leave"), "조부모·외조부모 사망 3일"
    assert_not_includes reply("special-leave"), "동일하게 5일"
    assert_not_includes reply("special-leave"), "형제자매 사망은 1일"
  end

  test "EDGE: 없는 제도 «범위형 낙찰하한율 추첨»을 복수예비가격 추첨으로 바로잡는다" do
    capture_io { load MIGRATION }
    text = reply("lowest-bid-rate")
    assert_not_includes text, "추첨형(범위형) 낙찰하한율"
    assert_includes text, "복수예비가격 중 4개를 추첨"
  end

  test "LOWER_BOUND: 일비 0.5일 계산 기준·유찰 수의계약 89.745% 기재 요구를 싣지 않는다" do
    capture_io { load MIGRATION }
    assert_not_includes reply("travel-expense"), "4시간 미만은 0.5일"
    assert_not_includes reply("private-contract-justification"), "89.745%"
    assert_includes reply("private-contract-justification"), "시행령 제26조제3항"
  end

  test "EDGE: 징계 출석통지는 개최일 3일 전 도달, 변상판정 재심의는 집행정지 효력이 없다" do
    capture_io { load MIGRATION }
    assert_includes reply("disciplinary-action"), "개최일 3일 전에 도달"
    assert_not_includes reply("disciplinary-action"), "출석일 5일 전까지"
    assert_includes reply("accounting-officers"), "집행정지의 효력이 없고(제36조제3항)"
    assert_not_includes reply("accounting-officers"), "집행정지 신청을 함께 하여야 합니다"
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 운영자가 고친 회신을 만나면 전체 롤백, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=#{EDITS.size}/, out)
    ENV.delete("DRY_RUN")
    Topic.find_by!(slug: "travel-expense").update_columns(interpretation_content: "운영자가 고친 회신")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes reply("special-leave"), "동일하게 5일", "부분 적용 금지"
  ensure
    ENV.delete("DRY_RUN")
  end
end
