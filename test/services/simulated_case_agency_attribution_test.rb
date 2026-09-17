# frozen_string_literal: true

require "test_helper"

# 가상 시나리오가 실재 기관(감사원)의 감사결과처럼 읽히지 않게 한다 (2026-09-17 전수감사 G-13).
class SimulatedCaseAgencyAttributionTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918140000_simulated_case_real_agency_attribution.rb")

  def seed(source_type, **fields)
    AuditCase.create!({ title: "t", slug: "t-#{SecureRandom.hex(4)}", issue: "○○", category: "contract", source_type: source_type }.merge(fields))
  end

  test "NORMAL: 가상 사례의 «감사원 감사에서 적발»은 «감사에서 적발»" do
    ac = seed("SILMU_SIMULATED_CASE", issue: "물품 수의계약을 체결하였다가 감사원 감사에서 적발되어 계약 취소")
    capture_io { load MIGRATION }
    assert_equal "물품 수의계약을 체결하였다가 감사에서 적발되어 계약 취소", ac.reload.issue
  end

  test "EDGE: «감사원 정기감사에서»·«감사원 특별감사에서» 변형도 바꾼다" do
    ac = seed("SILMU_SIMULATED_CASE", detail: "감사원 정기감사에서 확인. 감사원 특별감사에서 적발.")
    capture_io { load MIGRATION }
    assert_equal "감사에서 확인. 감사에서 적발.", ac.reload.detail
  end

  test "LOWER_BOUND: 일반 경고(«감사원 특별감사 대상»)는 그대로 둔다" do
    ac = seed("SILMU_SIMULATED_CASE", lesson: "수의계약 비율이 높으면 감사원 특별감사 대상이 될 수 있습니다.")
    capture_io { load MIGRATION }
    assert_includes ac.reload.lesson, "감사원 특별감사 대상"
  end

  test "UPPER_BOUND: 재실행은 0건" do
    seed("SILMU_SIMULATED_CASE", issue: "감사원 감사에서 지적")
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 실제 감사결과·원문 있는 재구성 사례는 바꾸지 않는다" do
    actual = seed("ACTUAL_AUDIT", issue: "감사원 감사에서 지적된 사항")
    rec = seed("SILMU_RECONSTRUCTED_CASE", issue: "감사원 감사에서 지적된 사항")
    capture_io { load MIGRATION }
    assert_includes actual.reload.issue, "감사원"
    assert_includes rec.reload.issue, "감사원"
  end
end
