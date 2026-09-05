# frozen_string_literal: true

require "test_helper"

# P1.55 §24·§25·§26 — Admin 검토 큐.
# 가장 중요한 검사: **이 화면이 게시 콘텐츠를 수정하지 않는다.**
class AdminAuthorityReviewsTest < ActionDispatch::IntegrationTest
  include AuthorityTestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin-ar-#{SecureRandom.hex(3)}@silmu.kr",
                          password: "Passw0rd!secure", admin: true)
    @document = create_document
    @case = AuditCase.create!(title: "검토 대상 사례", slug: "ar-#{SecureRandom.hex(3)}",
                              issue: "지적", detail: "상세", published: true,
                              legal_basis: "지방계약법 시행령 제25조")
    ContentAuthorityLink.create!(content_type: "AuditCase", content_id: @case.id,
                                 authority_document: @document, article_reference: "제25조",
                                 relationship_type: "EVIDENCED_BY", confidence: "HIGH")
    detector_with(build_success_result(body_extra: "제25조 (수의계약) 기존")).check(@document)
    @event = detector_with(build_success_result(revision_number: "99999",
                                                body_extra: "제25조 (수의계약) 개정"))
             .check(@document.reload).change_event
    @tasks = Authority::ImpactAnalyzer.new.analyze(@event)
    ContentFreshnessUpdater.apply_change_event(@event, @tasks)
    sign_in_admin
  end

  def sign_in_admin
    # config/initializers/warden_admin_hook.rb 가 after_set_user 에서
    # session[:admin_confirmed_at] 을 찍으므로 별도 재인증 POST 는 불필요하다.
    sign_in @admin
  end

  test "비로그인 사용자는 접근할 수 없다" do
    sign_out @admin
    get admin_authority_reviews_path
    assert_response :redirect
  end

  test "관리자가 아니면 접근할 수 없다" do
    plain = User.create!(email: "plain-#{SecureRandom.hex(3)}@silmu.kr", password: "Passw0rd!secure")
    sign_in plain
    get admin_authority_reviews_path
    assert_response :redirect
  end

  test "검토 큐에 변경·시행일·영향·근거가 한 화면에 나온다 (§24)" do
    get admin_authority_reviews_path
    assert_response :success
    assert_includes response.body, "법령 현행성 검토 큐"
    assert_includes response.body, @document.display_title      # 변경된 문서
    assert_includes response.body, "DIRECT"                     # 영향 등급
    assert_includes response.body, "제25조"                      # diff 근거
  end

  test "§25 결정 5종이 모두 제공된다" do
    get admin_authority_reviews_path
    AuthorityReviewTask::DECISIONS.each do |d|
      assert_includes response.body, d, "결정 버튼 누락: #{d}"
    end
  end

  test "NO_IMPACT 판정 시 검증 이벤트가 남고 freshness 가 전이된다" do
    task = @tasks.find { |t| t.affected_id == @case.id }
    assert_difference -> { AuthorityVerificationEvent.count }, 1 do
      post decide_admin_authority_review_path(task), params: { decision: "NO_IMPACT", note: "무관" }
    end
    assert_response :redirect
    assert_equal "NO_IMPACT", task.reload.status
    assert_equal "VERIFIED_AFTER_CHANGE", @case.reload.freshness_state
    assert_equal @admin.email, AuthorityVerificationEvent.recent_first.first.reviewer
  end

  test "§26 위험 전이 방지 — IMPACT_CONFIRMED 는 VERIFIED 로 가지 않는다" do
    task = @tasks.find { |t| t.affected_id == @case.id }
    post decide_admin_authority_review_path(task), params: { decision: "IMPACT_CONFIRMED" }
    assert_equal "REVIEW_REQUIRED", @case.reload.freshness_state,
                 "영향이 확인됐는데 검증 완료 상태가 됐다"
  end

  test "알 수 없는 결정은 거부한다" do
    task = @tasks.find { |t| t.affected_id == @case.id }
    post decide_admin_authority_review_path(task), params: { decision: "AUTO_FIX" }
    assert_response :redirect
    assert_equal "OPEN", task.reload.status
  end

  test "§27 Admin 판정이 게시 콘텐츠 본문을 수정하지 않는다" do
    body = [ @case.title, @case.issue, @case.detail, @case.legal_basis, @case.published ]
    task = @tasks.find { |t| t.affected_id == @case.id }
    post decide_admin_authority_review_path(task), params: { decision: "UPDATE_REQUIRED", note: "수정 필요" }
    @case.reload
    assert_equal body, [ @case.title, @case.issue, @case.detail, @case.legal_basis, @case.published ]
  end
end
