require "test_helper"

class AuditCasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @audit_case = AuditCase.create!(
      title: "테스트 감사사례 — 수의계약 분할",
      slug: "test-audit-case-smoke",
      category: "수의계약",
      severity: "보통",
      issue: "동일 사업을 분할하여 수의계약으로 체결한 사례가 발견되었다.",
      legal_basis: "지방계약법 시행령 제7조",
      lesson: "분할 수의계약은 법령 위반 소지가 있는 것으로 지적된 사례가 있다.",
      sector: :common,
      published: true
    )
  end

  test "index returns 200" do
    get audit_cases_url
    assert_response :success
  end

  test "show returns 200" do
    get audit_case_url(@audit_case.slug)
    assert_response :success
  end

  test "show includes Speakable schema limited to section-finding only" do
    get audit_case_url(@audit_case.slug)
    assert_includes response.body, "SpeakableSpecification"
    assert_includes response.body, "#section-finding"
    # h1·section-lesson은 단정 낭독 리스크로 제외된 상태여야 한다
    refute_match(/"cssSelector":\s*\[\s*"h1"/, response.body)
    refute_match(/#section-lesson"/, response.body.scan(/"cssSelector":[^\]]+\]/).join)
  end
end
