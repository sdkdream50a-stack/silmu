# frozen_string_literal: true

require "test_helper"

# P1-1 §7 — 검증의 "범위"가 분리되는지, provenance 가 사용자에게 올바르게 표현되는지.
class AuditCaseAuthorityTest < ActiveSupport::TestCase
  def build_case(**attrs)
    AuditCase.new({ title: "테스트 사례", slug: "t-#{SecureRandom.hex(4)}" }.merge(attrs))
  end

  # ── provenance ──────────────────────────────────────────
  test "ACTUAL_AUDIT — 원문 URL 이 있으면 문서 기반으로 인정된다" do
    ac = build_case(
      source_type: "ACTUAL_AUDIT",
      source_agency: "경기도교육청 감사관실",
      source_title: "감사사례집",
      source_url: "https://www.goe.go.kr/sample.pdf",
      source_year: 2021, source_page: 114, is_reconstructed: false
    )
    assert_equal "실제 감사결과", ac.provenance_label
    assert ac.document_backed?, "원문 URL 이 있는데 document_backed? 가 false"
    refute ac.reconstructed_case?
  end

  test "ACTUAL_AUDIT — 원문 URL 이 없으면 문서 기반으로 승격하지 않는다 (§10)" do
    ac = build_case(source_type: "ACTUAL_AUDIT", source_agency: "○○교육청", source_url: nil)
    refute ac.document_backed?, "원문 미확인인데 ACTUAL_AUDIT 로 승격됨"
  end

  test "RECONSTRUCTED — 재구성 사례는 실제 사건이 아님을 명시한다" do
    ac = build_case(source_type: "SILMU_RECONSTRUCTED_CASE", is_reconstructed: true)
    assert ac.reconstructed_case?
    assert_equal "실무.kr 재구성 사례", ac.provenance_label
    assert_includes ac.provenance_note, "실제 감사결과 원문을 그대로 재현한 것이 아니라"
  end

  test "UNVERIFIED — 미분류는 조용히 검증된 것처럼 보이지 않는다" do
    ac = build_case(source_type: nil)
    assert_equal "UNVERIFIED", ac.effective_source_type
    assert_equal "출처 추가 검증 필요", ac.provenance_label
  end

  # ── 검증 범위 분리 (§7) ─────────────────────────────────
  test "검증 범위는 단일 boolean 이 아니라 상태로 구분된다" do
    official = build_case(verification_status: "OFFICIAL_SOURCE_VERIFIED")
    legal    = build_case(verification_status: "LEGAL_REFERENCE_VERIFIED")
    content  = build_case(verification_status: "CONTENT_CONSISTENCY_VERIFIED")

    assert_equal "공식 원문 확인", official.verification_label
    assert_equal "법령 근거 검증", legal.verification_label
    assert_equal "내용 정합성 검토", content.verification_label

    # 법령 근거 검증이 사례 사실관계 검증으로 읽히지 않도록 범위를 문장으로 밝힌다
    assert_includes legal.verification_scope_text, "사례의 사실관계 검증과는 다릅니다"
    refute_equal legal.verification_label, official.verification_label
  end

  test "verification_status 가 없어도 가장 보수적인 값으로 동작한다" do
    ac = build_case(verification_status: nil, last_verified_at: nil)
    assert_equal "UNVERIFIED", ac.effective_verification_status
  end

  # ── 신선도 (§20) ────────────────────────────────────────
  test "재검증 기한이 지나면 스스로 강등된다" do
    fresh = build_case(review_due_at: Date.current + 30)
    due   = build_case(review_due_at: Date.current - 10)
    stale = build_case(review_due_at: Date.current - 200)

    assert_equal "CURRENT", fresh.freshness_status
    assert_equal "REVIEW_DUE", due.freshness_status
    assert_equal "STALE_SUSPECTED", stale.freshness_status
    assert_equal "UNKNOWN", build_case.freshness_status
  end

  test "review_due_at 이 없으면 검토일로부터 유도한다" do
    ac = build_case(last_verified_at: 400.days.ago)
    assert_equal "STALE_SUSPECTED", ac.freshness_status,
                 "1년 넘게 미검증인데 신선하다고 판정됨"
  end

  # ── 적용 기관 (§23) ─────────────────────────────────────
  test "HIGH confidence 가 아니면 적용 대상을 표시하지 않는다" do
    high = build_case(target_agency: %w[LOCAL_GOVERNMENT], agency_scope_confidence: "HIGH")
    med  = build_case(target_agency: %w[LOCAL_GOVERNMENT], agency_scope_confidence: "MEDIUM")
    none = build_case(target_agency: [], agency_scope_confidence: "HIGH")

    assert high.show_agency_scope?
    refute med.show_agency_scope?, "MEDIUM confidence 인데 적용 대상이 표시됨"
    refute none.show_agency_scope?
    assert_equal [ "지방자치단체" ], high.target_agency_labels
  end
end
