require "test_helper"

# 2026-09-29 시리즈 랜딩이 목차(제목 + 한 줄 잘린 설명)뿐이라 어느 편부터 볼지 고를 근거가 없었다.
# 각 편이 이미 가진 학습 목표(sections.today_checklist)와 설명 전문을 랜딩에 보여준다 — 새 문구를 만들지 않는다.
class SeriesLandingLearningGoalsTest < ActionDispatch::IntegrationTest
  setup do
    @with_goals = Guide.create!(
      title: "공사계약 1편", slug: "series-goals-ep1", series: "공사계약_완전정복", series_order: 1,
      description: "물품·용역 계약과의 차이와 공사 계약의 특수성을 정리합니다.",
      sections: { "today_checklist" => [ "종합공사·전문공사 차이를 구분할 수 있다", "분할발주 금지 원칙을 이해했다" ] }
    )
    @without_goals = Guide.create!(
      title: "공사계약 2편", slug: "series-goals-ep2", series: "공사계약_완전정복", series_order: 2,
      description: "발주 전 준비사항을 정리합니다.", sections: {}
    )
  end

  test "landing lists each episode's own learning goals" do
    get series_url("construction-complete")
    assert_response :success
    assert_includes response.body, "종합공사·전문공사 차이를 구분할 수 있다"
    assert_includes response.body, "분할발주 금지 원칙을 이해했다"
  end

  test "episode without goals still renders with its description and no empty goal block" do
    get series_url("construction-complete")
    assert_response :success
    assert_includes response.body, "발주 전 준비사항을 정리합니다."
    assert_equal 1, response.body.scan("data-series-goals").size
  end

  test "description is shown in full, not clipped to one line" do
    get series_url("construction-complete")
    assert_no_match(/text-xs text-slate-500 mt-0\.5 truncate/, response.body)
  end
end
