# frozen_string_literal: true

require "test_helper"

# 감사사례 신뢰 강등 회귀 (2026-09-17 전수감사 F-05·F-19·F-20).
# 원문 문서가 있어도 본문이 «가상 시나리오»를 밝히거나 강등 표식이 있으면 «실제 감사결과»로 올리지 않는다.
class AuditCaseTrustDowngradeTest < ActiveSupport::TestCase
  DOC = { "url" => "https://www.goe.go.kr/x.pdf", "publisher" => "경기도교육청 감사관실",
          "publication" => "감사사례집", "year" => 2021, "page" => 90 }.freeze
  MIGRATION = Rails.root.join("db/content_migrations/20260917120000_auditcase_trust_downgrade_actual_mixed.rb")

  def build_case(**attrs)
    AuditCase.new({ title: "테스트", slug: "t-#{SecureRandom.hex(4)}", source: DOC }.merge(attrs))
  end

  test "NORMAL (양성대조): 원문 문서만 있고 재구성 표시가 없으면 여전히 ACTUAL_AUDIT" do
    assert_equal "ACTUAL_AUDIT", AuditCaseProvenanceClassifier.plan_for(build_case(detail: "원문 발췌")).source_type
  end

  test "EDGE: 원문이 있어도 본문이 가상 시나리오를 밝히면 재구성으로 분류하고 원문 필드는 남긴다" do
    plan = AuditCaseProvenanceClassifier.plan_for(build_case(detail: "학습용으로 재구성한 가상 시나리오입니다."))
    assert_equal "SILMU_RECONSTRUCTED_CASE", plan.source_type
    assert_equal true, plan.is_reconstructed
    assert_nil plan.attributes_to_apply[:source_url], "원문 URL 을 nil 로 덮으면 참고 출처가 사라진다(compact 로 유지)"
  end

  test "LOWER_BOUND: 강등 표식이 있으면 분류기를 다시 돌려도 재승격하지 않고 표식을 유지한다" do
    marker = AuditCaseProvenanceClassifier::TRUST_DOWNGRADE_MARKER
    ac = build_case(detail: "원문 발췌", verification_note: "#{marker}: 강등",
                    verification_source: "Phase A batch 01 (commits eed3ceb)")
    plan = AuditCaseProvenanceClassifier.plan_for(ac)
    assert_equal "SILMU_RECONSTRUCTED_CASE", plan.source_type
    assert_includes plan.verification_note, marker
  end

  test "UPPER_BOUND: migration 은 목록의 ACTUAL 을 강등하고 두 번 돌려도 같은 결과" do
    ac = AuditCase.create!(title: "혼합", slug: "goe-2021-split-private-contracts", source: DOC,
                           source_type: "ACTUAL_AUDIT", is_reconstructed: false,
                           verification_status: "OFFICIAL_SOURCE_VERIFIED", category: "contract")
    2.times { capture_io { load MIGRATION } }
    ac.reload
    assert_equal "SILMU_RECONSTRUCTED_CASE", ac.source_type
    assert_equal "RECONSTRUCTED", ac.verification_status
    assert_equal 1, ac.verification_note.scan(AuditCaseProvenanceClassifier::TRUST_DOWNGRADE_MARKER).size
    assert_equal "https://www.goe.go.kr/x.pdf", ac.source["url"]
  end

  test "EXCEPTION: 목록 밖 ACTUAL(서울시교육청 원문 형식 처분)은 건드리지 않는다" do
    keep = AuditCase.create!(title: "유지", slug: "sen-2025-school-y-handover", source: DOC,
                             source_type: "ACTUAL_AUDIT", verification_status: "OFFICIAL_SOURCE_VERIFIED",
                             category: "contract")
    capture_io { load MIGRATION }
    assert_equal "ACTUAL_AUDIT", keep.reload.source_type
  end
end
