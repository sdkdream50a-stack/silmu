# frozen_string_literal: true

require "test_helper"

# 인사 토픽 «관련 예규·지침» 탭 정정 회귀 (2026-09-17 G-44). 픽스처 = 감사 시점 운영 본문.
class HrRegulationTabsTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918060000_hr_regulation_tabs.rb")
  SLUGS = %w[sick-leave annual-leave holiday-bonus parental-leave secondment].freeze

  def audited(slug) = Rails.root.join("test/fixtures/files/g44_#{slug}.txt").read

  setup do
    SLUGS.each do |slug|
      Topic.new(slug: slug, name: slug, category: "hr", sector: "common", regulation_content: audited(slug)).save!(validate: false)
    end
  end

  def text(slug) = Topic.find_by!(slug: slug).regulation_content

  test "NORMAL: 원문 미확인 예규 블록이 모두 사라지고 법령 출처 줄이 들어간다" do
    capture_io { load MIGRATION }
    SLUGS.each do |slug|
      assert_not_includes text(slug), "예규 제", slug
      assert_not_includes text(slug), "업무처리 지침**", slug
      assert_includes text(slug), "국가법령정보센터(law.go.kr)", slug
    end
  end

  test "EDGE: 병가 진단서는 연간 6일 초과, «7일 이내 진단서 불요»·«60일 초과 70%»를 싣지 않는다" do
    capture_io { load MIGRATION }
    assert_includes text("sick-leave"), "연간 6일을 초과하는 경우에는 의사의 진단서"
    assert_not_includes text("sick-leave"), "7일 이내의 단기 병가"
    assert_not_includes text("sick-leave"), "봉급의 70%를 지급하고 30%는 공제"
  end

  test "LOWER_BOUND: 명절휴가비는 지급기준일 전후 15일, 육아휴직수당 상한은 제11조의3①대로" do
    capture_io { load MIGRATION }
    assert_includes text("holiday-bonus"), "지급기준일 전후 15일 이내"
    assert_not_includes text("holiday-bonus"), "제14조의3"
    assert_includes text("parental-leave"), "7개월째 이후 160만원"
    assert_not_includes text("parental-leave"), "상한 150만 원"
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 한 토픽이라도 감사 이후 바뀌었으면 전체 롤백, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=5/, out)
    ENV.delete("DRY_RUN")
    Topic.find_by!(slug: "secondment").update_columns(regulation_content: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal audited("sick-leave"), text("sick-leave"), "부분 적용 금지"
  ensure
    ENV.delete("DRY_RUN")
  end
end
