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

  # 2026-09-17 TRUST REPAIR: 원문 문서 없이 재구성을 자인하면 «재구성»이 아니라 «가상 예방 시나리오»다.
  test "HIGH — 원문 없이 스스로 재구성이라 밝힌 콘텐츠는 가상 시나리오로 분류한다" do
    [
      build_case(source: "silmu-2026"),
      build_case(verification_source: "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님).")
    ].each do |ac|
      plan = AuditCaseProvenanceClassifier.plan_for(ac)
      assert_equal "HIGH", plan.confidence
      assert_equal "SILMU_SIMULATED_CASE", plan.source_type
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

  # 2026-09-28 P0-1: org_type=school 은 공·사립을 구분하지 못한다 — 사립 사례 24건이 «공립학교»로 표시됐다.
  test "HIGH — 사례가 스스로 사립학교라 밝히면 PUBLIC_SCHOOL 이 아니라 PRIVATE_SCHOOL 이다" do
    [
      build_case(sector: :edu, org_type: :school, issue: "해당 사립고는 2024학년도 기간제교원을 채용하면서"),
      build_case(sector: :edu, org_type: :school, issue: "해당 사립 특성화고는 예산을 사전 집행한 사실."),
      build_case(sector: :edu, org_type: :school, issue: "해당 학교법인은 감사를 실시하지 않은 사실."),
      build_case(sector: :edu, org_type: :school, source_title: "2024년 사립 학교법인 및 고등학교 종합감사 결과 공개문(S고)")
    ].each do |ac|
      plan = AgencyScopeClassifier.plan_for(ac)
      refute_includes Array(plan.target_agency), "PUBLIC_SCHOOL", "사립 사례를 공립학교로 표시함: #{ac.issue || ac.source_title}"
      assert_equal %w[PRIVATE_SCHOOL], plan.target_agency
      assert_equal "HIGH", plan.confidence
    end
  end

  test "LOW — 공·사립 사례가 한 건에 섞이면 어느 한쪽으로 단정하지 않는다" do
    ac = build_case(sector: :edu, org_type: :school,
                    issue: "○○고등학교는 학교법인 교비회계 전출금을 보관. ○○초등학교는 보관금 미편입.",
                    legal_basis: "지방재정법, 지방회계법, 사학기관 재무·회계 규칙, 경기도 공립학교회계 규칙")
    plan = AgencyScopeClassifier.plan_for(ac)
    refute plan.applicable?, "공·사립 혼재인데 한쪽으로 단정함(법령 신호로 새면 안 된다): #{plan.target_agency.inspect}"
    assert_empty Array(plan.target_agency)
  end

  test "HIGH — 사립 신호가 없는 학교 사례는 여전히 PUBLIC_SCHOOL 이다" do
    plan = AgencyScopeClassifier.plan_for(
      build_case(sector: :edu, org_type: :school, issue: "○○중학교는 여비를 초과 지급한 사실.",
                 legal_basis: "경기도 공립학교회계 규칙")
    )
    assert_equal %w[PUBLIC_SCHOOL], plan.target_agency
    assert_equal "HIGH", plan.confidence
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
