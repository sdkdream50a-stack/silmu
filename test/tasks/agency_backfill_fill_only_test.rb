# frozen_string_literal: true

require "test_helper"
require "rake"

# silmu:p1:agency_backfill 은 빈 칸만 채운다 — 원문 대조로 정정한 적용대상([] + LOW · 교육지원청 등)을
# 분류기(sector=edu + org_type=school → PUBLIC_SCHOOL)가 되돌리지 않아야 한다 (2026-09-29).
class AgencyBackfillFillOnlyTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["silmu:p1:agency_backfill"]
    @task.reenable
    base = { issue: "지적", lesson: "교훈", legal_basis: "근거", category: "기타", published: true,
             sector: :edu, org_type: :school }
    @mixed = AuditCase.create!(base.merge(slug: "bf-mixed", title: "혼재 사례", target_agency: [],
                                          agency_scope_confidence: "LOW"))
    @office = AuditCase.create!(base.merge(slug: "bf-office", title: "교육지원청 사례",
                                           target_agency: %w[EDUCATION_SUPPORT_OFFICE], agency_scope_confidence: "HIGH"))
    @blank = AuditCase.create!(base.merge(slug: "bf-blank", title: "빈 사례", target_agency: [],
                                          agency_scope_confidence: nil))
  end

  test "분류기는 세 행 모두에 PUBLIC_SCHOOL HIGH 를 제안한다(가드가 없으면 덮어쓴다 — 양성 대조)" do
    [ @mixed, @office, @blank ].each do |rec|
      plan = AgencyScopeClassifier.plan_for(rec)
      assert plan.applicable?, rec.slug
      assert_equal %w[PUBLIC_SCHOOL], plan.target_agency
    end
  end

  test "정정값은 보존하고 빈 칸만 채운다" do
    capture_io { @task.invoke }
    assert_equal [], @mixed.reload.target_agency
    assert_equal "LOW", @mixed.agency_scope_confidence
    assert_equal %w[EDUCATION_SUPPORT_OFFICE], @office.reload.target_agency
    assert_equal %w[PUBLIC_SCHOOL], @blank.reload.target_agency
  end
end
