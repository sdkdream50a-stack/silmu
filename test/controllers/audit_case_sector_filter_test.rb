require "test_helper"

# 감사사례 학교·교육청 필터 회귀 (2026-09-17 업무흐름 감사 13 W-04).
class AuditCaseSectorFilterTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    base = { category: "계약", severity: "보통", issue: "지적", published: true }
    @school = AuditCase.create!(base.merge(title: "학교 필터 사례", slug: "sector-school-case", sector: :edu, org_type: :school))
    @common = AuditCase.create!(base.merge(title: "공통 필터 사례", slug: "sector-common-case", sector: :common))
  end

  test "NORMAL: sector=edu shows only school/education-office cases" do
    get "/audit-cases", params: { sector: "edu" }
    assert_response :success
    assert_includes response.body, "학교 필터 사례"
    assert_not_includes response.body, "공통 필터 사례"
  end

  test "LOWER_BOUND (양성대조): without the filter both appear" do
    get "/audit-cases"
    assert_includes response.body, "학교 필터 사례"
    assert_includes response.body, "공통 필터 사례"
  end

  test "EDGE: the filter persists in category links" do
    get "/audit-cases", params: { sector: "edu" }
    assert_match(/href="\/audit-cases\?category=[^"]*sector=edu"/, response.body)
  end

  test "UPPER_BOUND: unknown sector value is ignored" do
    get "/audit-cases", params: { sector: "local_gov';--" }
    assert_includes response.body, "공통 필터 사례"
  end

  test "EXCEPTION: the filter chips are rendered" do
    get "/audit-cases"
    assert_includes response.body, "학교·교육청 사례"
  end
end
