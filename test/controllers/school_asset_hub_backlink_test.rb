require "test_helper"

# 학교 자산 → 학교행정 허브 역링크 (2026-09-28 비도구 신뢰 감사 07 SO-20: 역링크 0).
# 토픽·감사사례가 공유하는 «근거 및 출처» 블록에서 학교 레코드만 허브로 잇는다.
class SchoolAssetHubBacklinkTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    base = { category: "계약", severity: "보통", issue: "지적", published: true,
             legal_basis: "지방계약법 시행령 제25조" }
    AuditCase.create!(base.merge(title: "학교 사례", slug: "hub-school-case", sector: :edu, org_type: :school))
    AuditCase.create!(base.merge(title: "지자체 사례", slug: "hub-local-case", sector: :local_gov))
    host! "silmu.kr"
  end

  test "school audit case links back to /school-office" do
    get "/audit-cases/hub-school-case"
    assert_response :success
    assert response.body.include?('href="/school-office"'), "학교 자산에 허브 역링크 없음"
  end

  test "school topic links back to /school-office" do
    Topic.create!(name: "학교 토픽", slug: "hub-school-topic", category: "contract", sector: "edu", org_type: "school",
                  summary: "요약", commentary: "본문", keywords: "검사", published: true,
                  target_agency: %w[PUBLIC_SCHOOL], agency_scope_confidence: "HIGH")
    get "/topics/hub-school-topic"
    assert_response :success
    assert response.body.include?('href="/school-office"'), "학교 자산에 허브 역링크 없음"
  end

  test "non-school audit case has no hub backlink" do
    get "/audit-cases/hub-local-case"
    assert_response :success
    refute response.body.include?('href="/school-office"'), "비학교 자산에 허브 링크"
  end
end
