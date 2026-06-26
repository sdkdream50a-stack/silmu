require "test_helper"

class GuidesControllerTest < ActionDispatch::IntegrationTest
  test "GET /guides 는 성공 응답을 반환" do
    get guides_url
    assert_response :success
  end

  test "GET /guides: @series_groups 에 시리즈 가이드가 그룹핑됨" do
    skip "시드 데이터 없는 환경에서는 건너뜀" if Guide.series_guides.count.zero?

    get guides_url
    assert_response :success

    series_groups = controller.instance_variable_get(:@series_groups)
    assert series_groups.present?, "@series_groups 가 비어있음"
    series_groups.each do |series_name, episodes|
      assert episodes.map(&:series_order) == episodes.map(&:series_order).sort,
             "#{series_name} 시리즈가 series_order 순서로 정렬되지 않음"
    end
  end

  test "GET /guides: 완전정복 시리즈 7개 모두 포함" do
    expected_series = %w[
      수의계약_완전정복
      지방보조금_완전정복
      예산편성_완전정복
      예산집행_완전정복
      출장여비_완전정복
      인사복무_완전정복
      공사계약_완전정복
    ]
    skip "시드 데이터 없는 환경에서는 건너뜀" unless expected_series.all? { |s| Guide.exists?(series: s) }

    get guides_url
    series_groups = controller.instance_variable_get(:@series_groups)
    expected_series.each do |s|
      assert series_groups.key?(s), "#{s} 시리즈가 @series_groups에 없음"
    end
  end

  test "GET /guides/:slug (시리즈 편): 성공 응답 반환" do
    guide = Guide.series_guides.first
    skip "시리즈 가이드 데이터 없음" if guide.nil?

    get guide_url(guide)
    assert_response :success
  end

  test "GET /start renders onboarding track links and red flags" do
    lesson_slugs_by_type = GuidesController::ONBOARDING_TRACK
      .flat_map { |step| step[:lessons] }
      .group_by { |lesson| lesson[:type] }

    Array(lesson_slugs_by_type[:topic]).each do |lesson|
      topic = Topic.find_or_initialize_by(slug: lesson[:slug])
      topic.update!(
        name: "온보딩 토픽 #{lesson[:slug]}",
        summary: "온보딩 테스트 토픽",
        published: true
      )
    end

    Array(lesson_slugs_by_type[:guide]).each do |lesson|
      guide = Guide.find_or_initialize_by(slug: lesson[:slug])
      guide.update!(
        title: "온보딩 가이드 #{lesson[:slug]}",
        category: "계약",
        category_color: "emerald",
        published: true
      )
    end

    GuidesController::ONBOARDING_TRACK.flat_map { |step| step[:red_flags] }.each do |slug|
      audit_case = AuditCase.find_or_initialize_by(slug: slug)
      audit_case.update!(
        title: "온보딩 감사사례 #{slug}",
        issue: "온보딩 테스트 감사사례",
        category: "계약",
        severity: "중대",
        published: true
      )
    end

    get onboarding_url
    assert_response :success

    assert_select "h1", text: /신규자 첫달 계약 실무 코스/
    assert_select "h3", text: "이렇게 하면 걸려요"
    assert_select "article#step-7[data-onboarding-step][data-step=?]", "7"

    Array(lesson_slugs_by_type[:topic]).each do |lesson|
      assert_select "a[href=?]", topic_path(lesson[:slug])
      assert_select "a[href=?][data-onboarding-link][data-step][data-slug=?][data-link-type=?]",
                    topic_path(lesson[:slug]), lesson[:slug], "lesson"
    end

    Array(lesson_slugs_by_type[:guide]).each do |lesson|
      assert_select "a[href=?]", guide_path(lesson[:slug])
      assert_select "a[href=?][data-onboarding-link][data-step][data-slug=?][data-link-type=?]",
                    guide_path(lesson[:slug]), lesson[:slug], "lesson"
    end

    assert_select "a[href=?]", contract_flow_path
    assert_select "a[href=?][data-onboarding-link][data-slug=?][data-link-type=?]",
                  contract_flow_path, "contract-flow", "lesson"
    assert_select "a[href=?]", pre_contract_checklist_path
    assert_select "a[href=?][data-onboarding-link][data-slug=?][data-link-type=?]",
                  pre_contract_checklist_path, "pre-contract-checklist", "lesson"

    GuidesController::ONBOARDING_TRACK.flat_map { |step| step[:red_flags] }.each do |slug|
      assert_select "a[href=?]", audit_case_path(slug)
      assert_select "a[href=?][data-onboarding-link][data-step][data-slug=?][data-link-type=?]",
                    audit_case_path(slug), slug, "red_flag"
      assert_match "온보딩 감사사례 #{slug}", response.body
    end

    assert_match "window.gtag('event', name, params || {})", response.body
    assert_match "trackEvent('onboarding_start')", response.body
    assert_match "trackEvent('onboarding_step_view', { step_index: stepIndex })", response.body
    assert_match "trackEvent('onboarding_lesson_click'", response.body
  end
end
