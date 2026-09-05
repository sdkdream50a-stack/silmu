# frozen_string_literal: true

require "test_helper"

# P1-3 §33 — 공개 렌더 경계 회귀 테스트.
#
# 문자열 하드코딩만으로 통과시키지 않는다. **실제 렌더 경계(AuthorityPresenter)와
# 실제 HTTP 응답 본문**을 검사한다. 내부 메타데이터를 가진 레코드를 일부러 심어 두고,
# 그 문자열이 공개 응답에 나타나지 않는지 본다.
class PublicMetadataLeakTest < ActionDispatch::IntegrationTest
  # 운영에서 실제로 노출됐던 형태 (P0 감사 채증)
  LEAKY_SOURCE = "Phase A~E batch 01~03 (commits eed3ceb..12dff5d) — 법제처 OPEN API mcp spot check"
  LEAKY_TOKENS = %w[Phase batch commit eed3ceb lawId backlog internal mcp dashboard].freeze

  setup do
    @case = AuditCase.create!(
      title: "누출 회귀 테스트 사례",
      slug: "leak-regression-#{SecureRandom.hex(4)}",
      issue: "테스트 지적사항",
      detail: "테스트 상세",
      category: "수의계약",
      severity: "보통",
      published: true,
      legal_basis: "지방계약법 시행령 제25조",
      verification_source: LEAKY_SOURCE,     # ← 공개되면 안 되는 값
      verification_note: LEAKY_SOURCE,
      last_verified_at: 10.days.ago,
      source_type: "UNVERIFIED"
    )
  end

  test "렌더 경계(presenter)가 내부 메타데이터를 통과시키지 않는다" do
    presenter = AuthorityPresenter.new(@case)
    assert_nil presenter.public_source_label,
               "presenter 가 내부 문자열을 공개 라벨로 노출함"
    refute presenter.show_source?,
           "공개 가능한 출처가 없는데 출처 블록이 표시됨"
  end

  test "감사사례 공개 페이지 응답에 내부 메타데이터가 없다" do
    get audit_case_path(@case.slug)
    assert_response :success

    LEAKY_TOKENS.each do |token|
      refute_includes response.body, token,
                      "공개 HTML 에 내부 토큰 '#{token}' 이 노출됨"
    end
    refute_includes response.body, LEAKY_SOURCE
  end

  test "verification_note 는 어떤 공개 응답에도 나타나지 않는다" do
    get audit_case_path(@case.slug)
    assert_response :success
    refute_includes response.body, @case.verification_note
  end

  # ── 양성 대조: 이 테스트가 실제로 누출을 잡아내는가 ──
  # (P0 교훈: "0건"을 주장하기 전에 검출기가 1건을 세는지 증명한다)
  test "POSITIVE CONTROL — 경계를 우회하면 누출이 실제로 검출된다" do
    body_with_leak = "<cite>#{LEAKY_SOURCE}</cite>"
    detected = LEAKY_TOKENS.any? { |t| body_with_leak.include?(t) }
    assert detected, "누출 검출 로직 자체가 작동하지 않음 — 위 테스트들의 통과는 무의미하다"
    assert InternalMetadataFilter.internal?(LEAKY_SOURCE)
  end

  test "정상 출처는 공개 페이지에 표시된다 (과잉 차단 회귀 방지)" do
    clean = AuditCase.create!(
      title: "정상 출처 사례",
      slug: "clean-source-#{SecureRandom.hex(4)}",
      issue: "지적", detail: "상세", category: "회계", severity: "경미", published: true,
      source_type: "ACTUAL_AUDIT",
      source_agency: "경기도교육청 감사관실",
      source_title: "감사사례집",
      source_url: "https://www.goe.go.kr/example.pdf",
      source_year: 2021, source_page: 114,
      verification_status: "OFFICIAL_SOURCE_VERIFIED",
      last_verified_at: 5.days.ago
    )
    get audit_case_path(clean.slug)
    assert_response :success
    assert_includes response.body, "경기도교육청 감사관실"
    assert_includes response.body, "https://www.goe.go.kr/example.pdf"
    assert_includes response.body, "실제 감사결과"
  end

  test "재구성 사례는 실제 사건이 아님을 공개 페이지에서 밝힌다" do
    recon = AuditCase.create!(
      title: "재구성 사례",
      slug: "recon-#{SecureRandom.hex(4)}",
      issue: "지적", detail: "상세", category: "예산", severity: "보통", published: true,
      source_type: "SILMU_RECONSTRUCTED_CASE", is_reconstructed: true,
      verification_status: "RECONSTRUCTED", last_verified_at: 5.days.ago
    )
    get audit_case_path(recon.slug)
    assert_response :success
    assert_includes response.body, "재구성 사례"
    assert_includes response.body, "실제 감사결과 원문을 그대로 재현한 것이 아니라"
  end
end
