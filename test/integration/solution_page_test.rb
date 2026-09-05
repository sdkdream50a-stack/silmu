# frozen_string_literal: true

require "test_helper"

# P1.6 §28·§29·§30·§32 — Solution Page 첫 화면.
# 핵심 불변식: **거짓 CURRENT 금지** · 없는 섹션은 그리지 않음 · 판정은 presenter 경유.
class SolutionPageTest < ActionDispatch::IntegrationTest
  def create_topic!(slug:, **attrs)
    Topic.create!({ name: "테스트 토픽", slug: slug, summary: "요약", category: "contract",
                    published: true }.merge(attrs))
  end

  test "현행성 상태를 첫 화면에 presenter 문구 그대로 보여준다" do
    t = create_topic!(slug: "test-sol-current", last_verified_at: Time.current,
                      review_due_at: Date.current + 30)
    get topic_path(t.slug)
    assert_response :success
    assert_equal "CURRENT", AuthorityPresenter.new(t.reload).freshness_status
    assert_match "현재 기준 확인", response.body
  end

  test "CURRENT 가 아니면 '현재 기준 확인' 을 쓰지 않는다 (거짓 CURRENT 금지)" do
    t = create_topic!(slug: "test-sol-stale", last_verified_at: 3.years.ago,
                      review_due_at: Date.current - 400)
    presenter = AuthorityPresenter.new(t.reload)
    assert_not_equal "CURRENT", presenter.freshness_status

    get topic_path(t.slug)
    assert_response :success
    assert_no_match "현재 기준 확인", response.body
    assert_match presenter.freshness_label, response.body
  end

  test "확인 주기가 없으면 상태를 지어내지 않는다" do
    t = create_topic!(slug: "test-sol-unknown")
    assert_equal "UNKNOWN", AuthorityPresenter.new(t.reload).freshness_status

    get topic_path(t.slug)
    assert_response :success
    assert_no_match "현재 기준 확인", response.body
  end

  test "적용 대상은 HIGH confidence 일 때만 나온다" do
    low = create_topic!(slug: "test-sol-low", target_agency: [ "LOCAL_GOVERNMENT" ],
                        agency_scope_confidence: "LOW")
    get topic_path(low.slug)
    assert_response :success
    assert_no_match "적용 대상: 지방자치단체", response.body

    high = create_topic!(slug: "test-sol-high", target_agency: [ "LOCAL_GOVERNMENT" ],
                         agency_scope_confidence: "HIGH")
    get topic_path(high.slug)
    assert_response :success
    assert_match "적용 대상: 지방자치단체", response.body
  end

  test "지금 해야 할 일은 howto_steps 가 있을 때만 그린다 (빈 박스 금지)" do
    without = create_topic!(slug: "test-sol-nosteps")
    get topic_path(without.slug)
    assert_response :success
    assert_select "#next-actions-heading", false

    with = create_topic!(slug: "test-sol-steps", howto_steps: [
      { "name" => "1. 예정가격 작성", "text" => "추정가격을 먼저 확정한다" },
      { "name" => "2. 견적서 징구",   "text" => "2인 이상 견적을 받는다" }
    ])
    get topic_path(with.slug)
    assert_response :success
    assert_select "#next-actions-heading"
    assert_match "예정가격 작성", response.body
    assert_match "2인 이상 견적을 받는다", response.body
  end

  test "깨진 howto_steps 원소는 렌더하지 않는다 (빈 번호 항목 금지)" do
    # howto_steps 는 jsonb 이고 내부 API 로도 쓰인다 → 원소 모양을 신뢰할 수 없다.
    # "죽지 않는다"만 확인하면 부족하다. 이름 없는 단계가 번호만 달고 나오면 그것도 결함이다.
    t = create_topic!(slug: "test-sol-badsteps", howto_steps: [
      "깨진 문자열", { "text" => "이름 없는 단계" }, { "name" => "정상 단계" }
    ])
    get topic_path(t.slug)
    assert_response :success
    # 단언은 **보이는 섹션**으로 한정한다. 문서 전체로 보면 기존 HowTo JSON-LD 가
    # 같은 문자열을 내보내서(그건 P1.6 이전부터 있던 별개 결함) 이 단언의 대상이 흐려진다.
    assert_select "#next-actions-heading ~ ol" do
      assert_select "li", 1
      assert_select "li", text: /이름 없는 단계/, count: 0
      assert_select "li", text: /정상 단계/, count: 1
    end
  end

  test "내부 메타데이터를 공개 화면에 노출하지 않는다" do
    t = create_topic!(slug: "test-sol-leak", last_verified_at: Time.current,
                      review_due_at: Date.current + 30)
    get topic_path(t.slug)
    assert_response :success
    # P1.6 이 새로 그린 상태 줄이 내부 스키마 용어를 흘리지 않는지 확인
    %w[AuthorityVersion AuthorityChangeEvent ContentAuthorityLink
       freshness_state last_change_event_id impact_class].each do |internal|
      assert_no_match internal, response.body, "내부 메타데이터 #{internal} 노출"
    end
  end
end
