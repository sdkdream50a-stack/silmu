# frozen_string_literal: true

require "test_helper"

# P1.5 §13·§14·§28·§47 — Impact Graph · 검토 큐 · 상태 전이
class Authority::ImpactAndReviewTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  ARTICLE_BODY_OLD = "제25조 (수의계약) 기존 본문\n제30조 (대상자 선정) 기존 본문"
  ARTICLE_BODY_NEW = "제25조 (수의계약) 개정된 본문\n제30조 (대상자 선정) 기존 본문"

  setup do
    @document = create_document
    @case_direct = AuditCase.create!(title: "제25조 근거 사례", slug: "t-direct-#{SecureRandom.hex(3)}",
                                     issue: "지적", detail: "상세", published: true,
                                     legal_basis: "지방계약법 시행령 제25조")
    @case_indirect = AuditCase.create!(title: "제30조 근거 사례", slug: "t-indirect-#{SecureRandom.hex(3)}",
                                       issue: "지적", detail: "상세", published: true,
                                       legal_basis: "지방계약법 시행령 제30조")
    ContentAuthorityLink.create!(content_type: "AuditCase", content_id: @case_direct.id,
                                 authority_document: @document, article_reference: "제25조",
                                 relationship_type: "EVIDENCED_BY", confidence: "HIGH")
    ContentAuthorityLink.create!(content_type: "AuditCase", content_id: @case_indirect.id,
                                 authority_document: @document, article_reference: "제30조",
                                 relationship_type: "EVIDENCED_BY", confidence: "HIGH")
    ContentAuthorityLink.create!(content_type: "Tool", content_key: "contract-method",
                                 authority_document: @document, article_reference: "제25조",
                                 relationship_type: "CALCULATES_WITH", confidence: "HIGH")

    detector_with(build_success_result(body_extra: ARTICLE_BODY_OLD)).check(@document)
    @event = detector_with(build_success_result(revision_number: "99999", body_extra: ARTICLE_BODY_NEW))
             .check(@document.reload).change_event
  end

  test "조문 단위 diff 로 DIRECT 와 INDIRECT 를 구분한다" do
    assert_equal [ "제25조" ], @event.machine_diff.dig("sections", "modified")

    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    by_target = tasks.index_by { |t| [ t.affected_type, t.affected_id || t.affected_key ] }

    assert_equal "DIRECT", by_target[[ "AuditCase", @case_direct.id ]].impact_class
    assert_equal "INDIRECT", by_target[[ "AuditCase", @case_indirect.id ]].impact_class
    assert_equal "DIRECT", by_target[[ "Tool", "contract-method" ]].impact_class
  end

  test "도구·서식은 우선순위를 높여 처리한다 (§34·§35)" do
    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    tool = tasks.find { |t| t.affected_type == "Tool" }
    audit = tasks.find { |t| t.affected_type == "AuditCase" && t.impact_class == "DIRECT" }
    assert tool.priority < audit.priority, "도구가 감사사례보다 우선되지 않았다"
    assert_equal 1, tool.priority, "도구 직접 영향은 최우선(1)이어야 한다"
  end

  test "연결된 콘텐츠가 없으면 NO_CONTENT_LINKED 로 표시한다" do
    ContentAuthorityLink.delete_all
    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    assert_empty tasks
    assert_equal "NO_CONTENT_LINKED", @event.reload.impact_status
  end

  test "재분석해도 태스크가 중복 생성되지 않는다 (idempotent)" do
    first = Authority::ImpactAnalyzer.new.analyze(@event)
    assert_no_difference -> { AuthorityReviewTask.count } do
      Authority::ImpactAnalyzer.new.analyze(@event)
    end
    assert_equal first.size, @event.authority_review_tasks.count
  end

  # ── §47 상태 전이 ───────────────────────────────────────
  test "CURRENT → CHANGE_DETECTED/REVIEW_REQUIRED → VERIFIED_AFTER_CHANGE" do
    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    ContentFreshnessUpdater.apply_change_event(@event, tasks)
    assert_equal "REVIEW_REQUIRED", @case_direct.reload.freshness_state

    task = tasks.find { |t| t.affected_id == @case_direct.id }
    task.decide!(decision: "NO_IMPACT", reviewer: "reviewer@silmu.kr", note: "영향 없음")
    assert_equal "VERIFIED_AFTER_CHANGE", @case_direct.reload.freshness_state
  end

  test "IMPACT_CONFIRMED 는 VERIFIED 로 가지 않는다 — 영향 있는 콘텐츠에 검증 배지 금지" do
    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    ContentFreshnessUpdater.apply_change_event(@event, tasks)
    task = tasks.find { |t| t.affected_id == @case_direct.id }

    task.decide!(decision: "IMPACT_CONFIRMED", reviewer: "reviewer@silmu.kr")
    assert_equal "REVIEW_REQUIRED", @case_direct.reload.freshness_state,
                 "영향이 확인됐는데 '검증 완료' 상태가 됐다"
  end

  test "검토 결정은 별도 검증 이벤트로 기록된다 (§29)" do
    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    task = tasks.find { |t| t.affected_id == @case_direct.id }

    assert_difference -> { AuthorityVerificationEvent.count }, 1 do
      task.decide!(decision: "NO_IMPACT", reviewer: "reviewer@silmu.kr", note: "확인함")
    end
    ev = AuthorityVerificationEvent.recent_first.first
    assert_equal "NO_IMPACT", ev.result
    assert_equal "reviewer@silmu.kr", ev.reviewer
    assert_equal @event.new_version_id, ev.authority_version_id, "어떤 버전을 보고 판정했는지 남지 않았다"
  end

  test "모든 태스크가 처리되면 변경 이벤트가 RESOLVED 로 닫힌다" do
    tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    tasks.each { |t| t.decide!(decision: "NO_IMPACT", reviewer: "r") }
    assert_equal "RESOLVED", @event.reload.review_status
  end

  test "알 수 없는 결정은 거부한다" do
    task = Authority::ImpactAnalyzer.new.analyze(@event).first
    assert_raises(ArgumentError) { task.decide!(decision: "APPROVED_SOMEHOW", reviewer: "r") }
  end

  test "출처 장애가 길어지면 콘텐츠는 SOURCE_UNAVAILABLE 로만 표시된다 (삭제 아님)" do
    ContentFreshnessUpdater.mark_source_unavailable(@document)
    assert_equal "SOURCE_UNAVAILABLE", @case_direct.reload.freshness_state
    assert AuditCase.exists?(@case_direct.id), "출처 장애로 콘텐츠가 사라졌다"
    assert @case_direct.published?, "출처 장애로 발행이 취소됐다"
  end
end
