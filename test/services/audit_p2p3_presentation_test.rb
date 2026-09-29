# frozen_string_literal: true

require "test_helper"

# 감사사례 P2/P3 표시층 정정(조치내용·관련 토픽·출처 쪽수) 회귀 — 2026-09-29.
# 운영 모양 = 42건 모두 action_taken nil · 관련 토픽은 tenure·instructor 만 · 출처 쪽 3건 1쪽 차.
class AuditP2p3PresentationTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929130000_audit_p2p3_presentation.rb")
  SRC = MIGRATION.read
  ACTIONS = eval(SRC[/^actions = (\{.*?\}).freeze/m, 1]) # rubocop:disable Security/Eval
  TOPICS = eval(SRC[/^topics = (\{.*?\}).freeze/m, 1]) # rubocop:disable Security/Eval
  PAGES = eval(SRC[/^pages = (\{.*?\}).freeze/m, 1]) # rubocop:disable Security/Eval
  BODY = %w[title issue detail lesson legal_basis].freeze
  EXISTING_TOPIC = {
    "goe-2021-tenure-allowance-mispayment" => "edu-allowance-temp-teacher-tenure",
    "goe-2021-instructor-allowance-improper" => "instructor-allowance"
  }.freeze

  setup do
    (TOPICS.values | EXISTING_TOPIC.values).each do |slug|
      Topic.find_or_create_by!(slug: slug) { |t| t.name = "토픽 #{slug}"; t.published = true }
    end
    ACTIONS.each_key do |slug|
      AuditCase.create!(slug: slug, title: "제목 #{slug}", issue: "지적 #{slug}", detail: "상세 #{slug}\n\n처분: 원문",
                        lesson: "교훈 #{slug}", legal_basis: "근거 #{slug}", category: "기타", published: true,
                        view_count: 170, topic_slug: EXISTING_TOPIC[slug], source_page: PAGES.dig(slug, 0) || 10)
    end
    # 목록 밖 P0 사례(negative control) — 어떤 필드도 바뀌면 안 된다
    @outsider = AuditCase.create!(slug: "goe-2021-private-contract-s2b-mismatch", title: "P0", issue: "i", detail: "d",
                                  lesson: "l", legal_basis: "b", category: "기타", published: true, source_page: 91)
    @before = snapshot
  end

  def snapshot
    AuditCase.order(:slug).to_h { |a| [ a.slug, BODY.to_h { |f| [ f, a.read_attribute(f) ] }.merge("view_count" => a.view_count) ] }
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  test "옛 상태: 조치내용이 비어 있고 쪽수가 1쪽 어긋나 있다(구 상태 재현)" do
    assert AuditCase.where(slug: ACTIONS.keys).all? { |a| a.action_taken.blank? }
    PAGES.each { |slug, (old, _)| assert_equal old, AuditCase.find_by!(slug: slug).source_page }
  end

  test "NORMAL: 조치내용·토픽·쪽수만 바뀌고 본문·title·view_count 는 그대로" do
    out = migrate
    assert_includes out, "changes=64"
    ACTIONS.each { |slug, v| assert_equal v, AuditCase.find_by!(slug: slug).action_taken, slug }
    TOPICS.each { |slug, t| assert_equal t, AuditCase.find_by!(slug: slug).topic_slug, slug }
    EXISTING_TOPIC.each { |slug, t| assert_equal t, AuditCase.find_by!(slug: slug).topic_slug, slug }
    PAGES.each { |slug, (_, new)| assert_equal new, AuditCase.find_by!(slug: slug).source_page, slug }
    assert_equal @before, snapshot
  end

  test "목록 밖 P0 사례는 아무것도 바뀌지 않는다(negative control)" do
    migrate
    @outsider.reload
    assert_nil @outsider.action_taken
    assert_nil @outsider.topic_slug
    assert_equal 91, @outsider.source_page
  end

  test "재실행 changes=0" do
    migrate
    assert_includes migrate, "changes=0"
  end

  test "DRY_RUN 은 쓰지 않는다" do
    out = migrate("DRY_RUN" => "1")
    assert_includes out, "DRY_RUN changes=64"
    assert AuditCase.where(slug: ACTIONS.keys).all? { |a| a.action_taken.blank? }
  end

  test "기존 조치내용이 다른 값이면 전체 롤백" do
    AuditCase.find_by!(slug: "sen-2025-school-y-handover").update_columns(action_taken: "다른 처분")
    assert_raises(RuntimeError) { migrate }
    assert_nil AuditCase.find_by!(slug: "goe-2021-accounting-disorder-construction").action_taken
  end

  test "쪽수가 기대한 옛 값이 아니면 전체 롤백" do
    AuditCase.find_by!(slug: "goe-2021-tenure-allowance-mispayment").update_columns(source_page: 200)
    assert_raises(RuntimeError) { migrate }
    assert_nil AuditCase.find_by!(slug: "goe-2021-accounting-disorder-construction").action_taken
  end

  test "연결 토픽이 비공개면 전체 롤백(없는 토픽 링크 금지)" do
    Topic.find_by!(slug: "payment").update_columns(published: false)
    assert_raises(RuntimeError) { migrate }
  end

  test "서울 사립(국가계약법) 사례에는 법령 무관 토픽만 연결한다" do
    sen = TOPICS.select { |slug, _| slug.start_with?("sen-") }
    assert_equal({ "sen-2025-school-s-supply-direct-prod-cert" => "direct-production-confirm" }, sen)
  end
end

class AuditCaseImprovementSectionTest < ActionDispatch::IntegrationTest
  def build(action)
    AuditCase.create!(slug: "improvement-#{action ? 'on' : 'off'}", title: "조치 섹션 #{action.inspect}", issue: "지적",
                      lesson: "교훈", legal_basis: "근거", category: "기타", published: true, action_taken: action)
  end

  test "조치내용이 비어 있으면 섹션과 목차 링크를 렌더하지 않는다" do
    get audit_case_url(build(nil).slug)
    assert_response :success
    refute_includes response.body, 'id="section-improvement"'
    refute_includes response.body, 'href="#section-improvement"'
  end

  test "조치내용이 있으면 쉼표 항목으로 렌더한다" do
    get audit_case_url(build("관련자 주의, 과다지급액 회수").slug)
    assert_response :success
    assert_includes response.body, 'id="section-improvement"'
    assert_includes response.body, 'href="#section-improvement"'
    assert_includes response.body, "<span>관련자 주의</span>"
    assert_includes response.body, "<span>과다지급액 회수</span>"
  end
end
