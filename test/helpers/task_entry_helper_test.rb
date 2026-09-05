# frozen_string_literal: true

require "test_helper"

# P1.6 §24 — 업무 진입점의 **런타임 count 게이트**를 고정한다.
# 개발 DB 에서 센 수치를 코드에 박으면 운영(Topics 114 vs dev 92)에서 틀린다.
class TaskEntryHelperTest < ActionView::TestCase
  include TaskEntryHelper

  test "커버리지가 MIN_COVERAGE 이상인 업무만 노출한다" do
    keys = task_entries.map { |e| e[:key] }
    counts = task_entry_counts

    assert keys.any?, "노출 가능한 업무가 최소 하나는 있어야 함"
    keys.each do |key|
      assert_operator counts[key], :>=, TaskEntryHelper::MIN_COVERAGE,
        "노출된 업무 #{key} 의 커버리지가 임계 미만"
    end
  end

  test "커버리지가 얇은 업무는 노출하지 않는다 (빈 칸 전시 금지)" do
    counts = task_entry_counts
    thin = counts.select { |_, n| n < TaskEntryHelper::MIN_COVERAGE }.keys

    assert thin.any?, "이 픽스처에서는 얇은 업무가 있어야 게이트를 검증할 수 있다"
    keys = task_entries.map { |e| e[:key] }
    thin.each { |key| assert_not_includes keys, key, "커버리지 미달 업무 #{key} 가 노출됨" }
  end

  test "콘텐츠가 생기면 업무가 자동으로 나타난다 (하드코딩이 아니다)" do
    assert_not_includes task_entries.map { |e| e[:key] }, "duty"

    TaskEntryHelper::MIN_COVERAGE.times do |i|
      Topic.create!(name: "복무 토픽 #{i}", slug: "test-duty-#{i}", category: "duty", published: true)
    end

    assert_includes task_entries.map { |e| e[:key] }, "duty"
  end

  test "노출 업무는 전부 실제 경로를 가진다" do
    task_entries.each do |entry|
      assert entry[:path_helper].present?, "#{entry[:key]} 에 경로가 없음"
      assert entry[:label].present?
      assert entry[:icon_class].present?, "Tailwind 리터럴 클래스가 있어야 함"
    end
  end
end
