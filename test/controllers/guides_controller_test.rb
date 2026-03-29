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
end
