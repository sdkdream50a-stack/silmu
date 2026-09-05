# frozen_string_literal: true

require "test_helper"

# P1 §25~§27 — backfill 은 사실 구조화이지 출처 창작이 아니다. HIGH 만 자동 적용.
class AuthorityClassifierTest < ActiveSupport::TestCase
  def build_case(**attrs)
    AuditCase.new({ title: "테스트", slug: "t-#{SecureRandom.hex(4)}" }.merge(attrs))
  end

  # ── provenance 분류기 ───────────────────────────────────
  test "HIGH — source jsonb 에 원문이 완비되면 ACTUAL_AUDIT 로 승격한다" do
    ac = build_case(source: {
      "url" => "https://www.goe.go.kr/x.pdf", "publisher" => "경기도교육청 감사관실",
      "publication" => "감사사례집", "year" => 2021, "page" => 114
    })
    plan = AuditCaseProvenanceClassifier.plan_for(ac)
    assert_equal "HIGH", plan.confidence
    assert plan.applicable?
    assert_equal "ACTUAL_AUDIT", plan.source_type
    assert_equal "OFFICIAL_SOURCE_VERIFIED", plan.verification_status
    assert_equal "https://www.goe.go.kr/x.pdf", plan.source_url
    assert_equal false, plan.is_reconstructed
  end

  test "HIGH — 스스로 재구성이라 밝힌 콘텐츠는 재구성으로 분류한다" do
    [
      build_case(source: "silmu-2026"),
      build_case(verification_source: "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님).")
    ].each do |ac|
      plan = AuditCaseProvenanceClassifier.plan_for(ac)
      assert_equal "HIGH", plan.confidence
      assert_equal "SILMU_RECONSTRUCTED_CASE", plan.source_type
      assert_equal true, plan.is_reconstructed
    end
  end

  test "HIGH — 내부 로그뿐인 출처는 UNVERIFIED 로 두고 문자열은 note 로 이관한다" do
    raw = "Phase A~E batch 01~03 (commits eed3ceb..12dff5d)"
    plan = AuditCaseProvenanceClassifier.plan_for(build_case(verification_source: raw))
    assert_equal "UNVERIFIED", plan.source_type, "내부 로그를 출처로 승격하면 안 된다"
    assert_equal raw, plan.verification_note, "내부 문자열이 무손실 이관되지 않음"
    assert_equal "HIGH", plan.confidence
  end

  test "MEDIUM — 기관명은 있으나 원문 URL 이 없으면 자동 적용하지 않는다 (§10)" do
    plan = AuditCaseProvenanceClassifier.plan_for(
      build_case(verification_source: "○○광역시 2024년 종합감사 결과")
    )
    assert_equal "MEDIUM", plan.confidence
    refute plan.applicable?, "원문 미확인인데 자동 승격됨"
    assert plan.requires_review?
    assert_nil plan.source_type
  end

  # ── 적용 기관 분류기 ────────────────────────────────────
  test "HIGH — 기존 구조적 분류값(sector/org_type)만 사용한다" do
    plan = AgencyScopeClassifier.plan_for(build_case(sector: :local_gov))
    assert_equal "HIGH", plan.confidence
    assert_equal %w[LOCAL_GOVERNMENT], plan.target_agency
    assert_equal "LOCAL", plan.jurisdiction
  end

  test "LOW — sector=edu 인데 org_type 이 없으면 학교/교육청을 추측하지 않는다" do
    plan = AgencyScopeClassifier.plan_for(build_case(sector: :edu, org_type: nil))
    refute plan.applicable?, "구분 불가인데 기관을 추측함"
  end

  test "LOW — 국가·지방 법령이 함께 인용되면 판정을 보류한다 (P0 TR-06)" do
    ac = build_case(sector: :common,
                    legal_basis: "지방공무원법 제65조의3 / 국가공무원법 제73조의3")
    plan = AgencyScopeClassifier.plan_for(ac)
    refute plan.applicable?, "관할이 섞였는데 한쪽으로 단정함"
    assert_equal "LOW", plan.confidence
  end

  test "HIGH — 지방 전용 법령만 인용하면 지방으로 판정한다" do
    ac = build_case(sector: :common, legal_basis: "지방계약법 시행령 제25조")
    plan = AgencyScopeClassifier.plan_for(ac)
    assert_equal "HIGH", plan.confidence
    assert_equal %w[LOCAL_GOVERNMENT], plan.target_agency
  end

  test "LOW — 구조적 신호가 없으면 UNSPECIFIED 를 유지한다" do
    plan = AgencyScopeClassifier.plan_for(build_case(sector: :common, legal_basis: nil))
    refute plan.applicable?
    assert_empty Array(plan.target_agency)
  end
end
