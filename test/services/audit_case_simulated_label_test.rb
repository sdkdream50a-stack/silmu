# frozen_string_literal: true

require "test_helper"

# 감사사례 TRUST REPAIR (2026-09-17 전수감사 G-13) — 원문 출처 없는 창작 시나리오는 «가상 예방 시나리오».
class AuditCaseSimulatedLabelTest < ActiveSupport::TestCase
  DOC = { "url" => "https://www.goe.go.kr/x.pdf", "publisher" => "경기도교육청 감사관실",
          "publication" => "감사사례집", "year" => 2021, "page" => 90 }.freeze
  MIGRATION = Rails.root.join("db/content_migrations/20260918090000_auditcase_simulated_label.rb")
  MARKER = "SIMULATED_LABEL_2026_09_17"

  def build_case(**attrs)
    AuditCase.new({ title: "테스트", slug: "t-#{SecureRandom.hex(4)}", issue: "○○시 지적", category: "contract" }.merge(attrs))
  end

  test "NORMAL: 원문 없이 재구성을 자인한 사례는 가상 시나리오로 분류하고 법령 근거 검증 배지를 쓰지 않는다" do
    plan = AuditCaseProvenanceClassifier.plan_for(build_case(verification_source: "silmu 자체 시드 (특정 실사례 아님)", legal_basis: "지방계약법 제9조"))
    assert_equal "SILMU_SIMULATED_CASE", plan.source_type
    assert_equal "RECONSTRUCTED", plan.verification_status
    assert build_case(source_type: plan.source_type).reconstructed_case?
  end

  test "EDGE (양성대조): 원문 문서가 있는 재구성은 여전히 재구성 사례" do
    plan = AuditCaseProvenanceClassifier.plan_for(build_case(source: DOC, detail: "학습용으로 재구성한 가상 시나리오입니다."))
    assert_equal "SILMU_RECONSTRUCTED_CASE", plan.source_type
  end

  test "LOWER_BOUND: 가상 표식이 있으면 출처 문자열이 비어도 «출처 추가 검증 필요»로 되돌리지 않는다" do
    plan = AuditCaseProvenanceClassifier.plan_for(build_case(verification_note: "#{MARKER}: 가상"))
    assert_equal "SILMU_SIMULATED_CASE", plan.source_type
  end

  test "UPPER_BOUND: 검색 설명·제목은 유형을 밝히고 원문 근거 사례만 «사례»라 부른다" do
    sim = build_case(source_type: "SILMU_SIMULATED_CASE", detail: "## 사건 개요\n○○시 건설과는 2024년 9월 공사를 발주했습니다.")
    assert sim.seo_description.start_with?("[가상 예방 시나리오] ")
    assert_operator sim.seo_description.length, :<=, 200
    assert_equal "감사 지적 유형과 실무 대응 방법", sim.seo_title_suffix
    actual = build_case(source_type: "ACTUAL_AUDIT", source: DOC, detail: "원문 발췌")
    assert_not actual.seo_description.start_with?("[")
    assert_equal "감사 지적 사례와 실무 대응 방법", actual.seo_title_suffix
  end

  test "EXCEPTION: migration 은 목록의 사례만 바꾸고, 원문 URL 이 있으면 전체 롤백하며, 두 번 돌려도 같다" do
    sim = AuditCase.create!(title: "이중 청구", slug: "travel-expense-double-claim", issue: "○○도 H씨", category: "contract",
                            source_type: "UNVERIFIED", verification_status: "LEGAL_REFERENCE_VERIFIED")
    keep = AuditCase.create!(title: "실제", slug: "sen-2025-school-y-handover", issue: "원문", category: "contract",
                             source: DOC, source_type: "ACTUAL_AUDIT", verification_status: "OFFICIAL_SOURCE_VERIFIED")
    2.times { capture_io { load MIGRATION } }
    sim.reload
    assert_equal "SILMU_SIMULATED_CASE", sim.source_type
    assert_equal "RECONSTRUCTED", sim.verification_status
    assert_equal 1, sim.verification_note.scan(MARKER).size
    assert_equal "ACTUAL_AUDIT", keep.reload.source_type

    other = AuditCase.create!(title: "원문 생김", slug: "double-booking-budget", issue: "□□시", category: "contract",
                              source_type: "UNVERIFIED", source_url: "https://example.go.kr/a.pdf")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal "UNVERIFIED", other.reload.source_type
  end
end
