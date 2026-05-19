# P8 ROI 계측 안전망 — AnalyticsSnapshot 모델
require "test_helper"

class AnalyticsSnapshotTest < ActiveSupport::TestCase
  test "validates label/page_path/captured_at presence + days > 0" do
    snap = AnalyticsSnapshot.new
    refute snap.valid?
    assert_includes snap.errors[:label], "can't be blank"
    assert_includes snap.errors[:page_path], "can't be blank"
    assert_includes snap.errors[:captured_at], "can't be blank"

    snap.assign_attributes(label: "x", page_path: "/p", captured_at: Time.current, days: 0)
    refute snap.valid?
    assert_includes snap.errors[:days], "must be greater than 0"
  end

  test "metrics accessors coerce types" do
    snap = AnalyticsSnapshot.create!(
      label: "baseline", page_path: "/tools/ai-assistant",
      days: 7, captured_at: Time.current,
      metrics: { "pageviews" => "142", "users" => 96, "avg_duration" => "73.4", "bounce_rate" => 42.1 }
    )
    assert_equal 142, snap.pageviews
    assert_equal 96, snap.users
    assert_in_delta 73.4, snap.avg_duration, 0.01
    assert_in_delta 42.1, snap.bounce_rate, 0.01
  end

  test "for_label scope" do
    AnalyticsSnapshot.create!(label: "A", page_path: "/p1", days: 7, captured_at: Time.current, metrics: {})
    AnalyticsSnapshot.create!(label: "B", page_path: "/p1", days: 7, captured_at: Time.current, metrics: {})

    assert_equal 1, AnalyticsSnapshot.for_label("A").count
  end
end
