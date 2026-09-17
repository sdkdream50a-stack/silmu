# frozen_string_literal: true

require "test_helper"

# «질의·회신 예시» 개별 검증 1차 정정 회귀 (2026-09-17 G-38). 원문: law.go.kr 법령·행정규칙.
class InterpretationRepliesBatch1Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918030000_interpretation_replies_batch1.rb")
  STR = /"(?:[^"\\]|\\.)*"/
  EDITS = MIGRATION.read.scan(/^  \[ (#{STR}), (#{STR}), (#{STR}) \]/)
                   .map { |row| row.map { |s| JSON.parse(s) } }.freeze

  setup do
    EDITS.group_by(&:first).each do |slug, list|
      body = list.map { |_, old, _| "**[회신]** #{old}\n(예시)\n" }.join("\n")
      Topic.new(slug: slug, name: slug, category: "contract", sector: "common", interpretation_content: "## 질의·회신\n\n#{body}").save!(validate: false)
    end
  end

  def reply(slug) = Topic.find_by!(slug: slug).interpretation_content

  test "NORMAL: 질병휴직 봉급은 1년 초과 2년 이하 50%, «이후 무급»이 아니다" do
    capture_io { load MIGRATION }
    assert_includes reply("sick-leave"), "1년 초과 2년 이하 50%"
    assert_not_includes reply("sick-leave"), "이후는 무급"
  end

  test "EDGE: 존재하지 않는 «공무원 퇴직급여법»이 사라지고 합산 재직기간의 퇴직수당 제외(제25조④)를 적는다" do
    capture_io { load MIGRATION }
    text = reply("retirement-allowance")
    assert_not_includes text, "공무원 퇴직급여법"
    assert_not_includes text, "이자는 가산하지 않습니다"
    assert_includes text, "퇴직수당을 지급할 때에는 재직기간에 합산하지 않습니다(제25조제4항)"
  end

  test "LOWER_BOUND: 모든 편집이 적용되고 원문에 없는 수치(연 8.5%·연 5%·30일·물품·용역 50%)가 남지 않는다" do
    assert_operator EDITS.size, :>=, 13
    capture_io { load MIGRATION }
    EDITS.each do |slug, old, new|
      assert_includes reply(slug), new, slug
      assert_not_includes reply(slug), old, slug
    end
    all = Topic.pluck(:interpretation_content).join("\n")
    [ "연 8.5%", "연 5%", "통지일로부터 30일", "물품·용역은 50% 이내", "시행령 제91조 요건" ].each { |s| assert_not_includes all, s }
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
    Topic.find_by!(slug: "budget-execution").update_columns(interpretation_content: "운영자가 고친 회신")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes reply("sick-leave"), "이후는 무급", "부분 적용 금지"
  ensure
    ENV.delete("DRY_RUN")
  end
end
