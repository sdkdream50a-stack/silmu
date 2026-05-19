# P8 ROI 계측 안전망 — AnalyticsHelper
require "test_helper"

class AnalyticsHelperTest < ActionView::TestCase
  include AnalyticsHelper

  test "영향 슬러그면 gtag content_migration_view 스크립트 출력" do
    html = roi_content_migration_tag(content_type: "topic", slug: "bid-deposit")
    assert_match(/gtag\('event', 'content_migration_view'/, html)
    assert_match(/bid-deposit/, html)
  end

  test "영향권 외 슬러그면 빈 문자열" do
    assert_equal "", roi_content_migration_tag(content_type: "topic", slug: "random-slug")
    assert_equal "", roi_content_migration_tag(content_type: "unknown", slug: "bid-deposit")
  end

  test "AuditCase 슬러그도 인식" do
    html = roi_content_migration_tag(content_type: "audit_case", slug: "budget-misuse")
    assert_match(/audit_case/, html)
  end
end
