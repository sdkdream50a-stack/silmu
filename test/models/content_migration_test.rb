# P6 ContentMigration Phase 1 안전망
require "test_helper"

class ContentMigrationTest < ActiveSupport::TestCase
  test "validates filename presence + uniqueness" do
    cm = ContentMigration.new(status: "pending")
    refute cm.valid?
    assert_includes cm.errors[:filename], "can't be blank"

    ContentMigration.create!(filename: "20260101_test.rb", status: "pending")
    dup = ContentMigration.new(filename: "20260101_test.rb", status: "pending")
    refute dup.valid?
  end

  test "validates status inclusion" do
    cm = ContentMigration.new(filename: "20260101_x.rb", status: "weird")
    refute cm.valid?
    assert_includes cm.errors[:status], "is not included in the list"
  end

  test "scope pending/applied/failed 분리" do
    ContentMigration.create!(filename: "a.rb", status: "pending")
    ContentMigration.create!(filename: "b.rb", status: "applied", applied_at: Time.current)
    ContentMigration.create!(filename: "c.rb", status: "failed", error_message: "boom")

    assert_equal 1, ContentMigration.pending.count
    assert_equal 1, ContentMigration.applied.count
    assert_equal 1, ContentMigration.failed.count
  end

  test "STATUSES 상수 노출" do
    assert_equal %w[pending applied failed], ContentMigration::STATUSES
  end
end
