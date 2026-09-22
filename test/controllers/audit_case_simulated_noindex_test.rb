require "test_helper"

# 2026-09-22 AdSense 불승인(「가치가 별로 없는 콘텐츠」) 대응 A안.
# 원문 출처가 없는 가상 예방 시나리오(SILMU_SIMULATED_CASE)는 페이지를 유지하되 검색 색인에서 뺀다 —
# 상세 noindex + sitemap 제외. 실제·재구성 사례는 그대로 색인한다.
class AuditCaseSimulatedNoindexTest < ActionDispatch::IntegrationTest
  setup do
    base = { category: "수의계약", severity: "보통", issue: "분할 수의계약 지적.",
             legal_basis: "지방계약법 시행령 제30조", lesson: "분할 금지.", sector: :common, published: true }
    @simulated = AuditCase.create!(base.merge(title: "가상 사례", slug: "sim-noindex-case", source_type: "SILMU_SIMULATED_CASE"))
    @reconstructed = AuditCase.create!(base.merge(title: "재구성 사례", slug: "recon-index-case", source_type: "SILMU_RECONSTRUCTED_CASE"))
    @actual = AuditCase.create!(base.merge(title: "실제 사례", slug: "actual-index-case", source_type: "ACTUAL_AUDIT"))
  end

  test "simulated case page stays reachable but is noindex" do
    get audit_case_url(@simulated.slug)
    assert_response :success
    assert_match(/<meta name="robots" content="noindex, follow"/, response.body)
  end

  test "reconstructed and actual cases stay indexable" do
    [ @reconstructed, @actual ].each do |ac|
      get audit_case_url(ac.slug)
      assert_response :success
      assert_no_match(/<meta name="robots" content="[^"]*noindex/, response.body, ac.slug)
    end
  end

  test "sitemap excludes simulated cases only" do
    host! "silmu.kr"
    get "/sitemap.xml"
    assert_response :success
    refute_includes response.body, "/audit-cases/#{@simulated.slug}</loc>"
    assert_includes response.body, "/audit-cases/#{@reconstructed.slug}</loc>"
    assert_includes response.body, "/audit-cases/#{@actual.slug}</loc>"
  end
end
