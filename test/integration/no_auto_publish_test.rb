# frozen_string_literal: true

require "test_helper"

# P1.5 §48 — **가장 중요한 회귀 테스트.**
#
# 구 LegalComplianceJob 은 RegulationVerifier#apply_corrections 를 통해
# AI 출력으로 `topic.update!` 를 실행, 게시 콘텐츠를 직접 수정할 수 있었다.
# Freshness Engine 은 그 경로를 절대 갖지 않는다. 이 테스트가 그것을 강제한다.
class NoAutoPublishTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  # 엔진이 건드려도 되는 유일한 컬럼들
  ALLOWED = ContentFreshnessUpdater::WRITABLE_COLUMNS

  # 절대 바뀌면 안 되는 본문 컬럼
  BODY_COLUMNS = {
    Topic     => %w[name summary law_content decree_content rule_content interpretation_content
                    commentary practical_tips qa_content audit_cases keywords published],
    Guide     => %w[title summary description sections published],
    AuditCase => %w[title issue detail lesson action_taken legal_basis checkpoints published]
  }.freeze

  setup do
    @document = create_document
    @topic = Topic.create!(name: "테스트 토픽", slug: "t-nap-#{SecureRandom.hex(3)}",
                           law_content: "원본 법률 본문", decree_content: "원본 시행령 본문",
                           commentary: "원본 해설", published: true)
    @guide = Guide.create!(title: "테스트 가이드", slug: "g-nap-#{SecureRandom.hex(3)}",
                           summary: "원본 요약", published: true)
    @case = AuditCase.create!(title: "테스트 사례", slug: "a-nap-#{SecureRandom.hex(3)}",
                              issue: "원본 지적", detail: "원본 상세",
                              legal_basis: "지방계약법 시행령 제25조", published: true)
    [ @topic, @guide, @case ].each do |rec|
      ContentAuthorityLink.create!(content_type: rec.class.name, content_id: rec.id,
                                   authority_document: @document, article_reference: "제25조",
                                   relationship_type: "GOVERNED_BY", confidence: "HIGH")
    end
  end

  def body_snapshot
    BODY_COLUMNS.to_h { |klass, cols| [ klass.name, klass.order(:id).pluck(:id, *cols) ] }
  end

  test "POSITIVE CONTROL — 스냅샷이 실제 본문 변경을 잡아낸다" do
    before = body_snapshot
    @topic.update_columns(law_content: "누군가 본문을 바꿨다")
    refute_equal before, body_snapshot,
                 "스냅샷이 본문 변경을 감지하지 못한다 — 아래 무변경 검증들이 무의미해진다"
  end

  test "변경 감지 전체 사이클이 게시 본문을 수정하지 않는다" do
    detector = ->(extra) { detector_with(build_success_result(revision_number: extra, body_extra: "제25조 (수의계약) #{extra}")) }
    detector.call("36338").check(@document)

    before = body_snapshot
    out = detector.call("99999").check(@document.reload)
    tasks = Authority::ImpactAnalyzer.new.analyze(out.change_event)
    ContentFreshnessUpdater.apply_change_event(out.change_event, tasks)
    tasks.each { |t| t.decide!(decision: "IMPACT_CONFIRMED", reviewer: "r") }

    assert out.changed?, "변경이 감지되지 않아 이 테스트가 아무것도 증명하지 못한다"
    assert tasks.any?, "검토 태스크가 없어 이 테스트가 아무것도 증명하지 못한다"
    assert_equal before, body_snapshot, "엔진이 게시 본문을 수정했다"
  end

  test "잡 실행이 게시 본문을 수정하지 않는다" do
    before = body_snapshot
    AuthorityFreshnessCheckJob.new.perform(document_ids: [ @document.id ])
    assert_equal before, body_snapshot
  end

  test "freshness 갱신은 화이트리스트 3개 컬럼만 건드린다" do
    assert_equal %w[freshness_state freshness_state_at last_change_event_id].sort, ALLOWED.sort

    before = @case.attributes.except(*ALLOWED, "updated_at")
    ContentFreshnessUpdater.mark_source_unavailable(@document)
    after = @case.reload.attributes.except(*ALLOWED, "updated_at")
    assert_equal before, after, "허용되지 않은 컬럼이 변경됐다"
    assert_equal "SOURCE_UNAVAILABLE", @case.freshness_state
  end

  test "알 수 없는 freshness 상태는 거부한다" do
    assert_raises(ArgumentError) do
      ContentFreshnessUpdater.send(:write, @case, "AUTO_FIXED", nil)
    end
  end

  test "엔진 코드에 게시 콘텐츠 쓰기 경로가 없다" do
    engine_files = Dir[Rails.root.join("app/services/authority/**/*.rb")] +
                   [ Rails.root.join("app/jobs/authority_freshness_check_job.rb").to_s ]
    offenders = engine_files.select do |f|
      src = File.read(f)
      src.match?(/\b(Topic|Guide|AuditCase)\b[^\n]*\.(update!?|update_columns|update_attribute|destroy|delete)\b/)
    end
    assert_empty offenders,
                 "엔진 파일에서 게시 콘텐츠 직접 쓰기 호출이 발견됐다: #{offenders.join(', ')}"
  end
end
