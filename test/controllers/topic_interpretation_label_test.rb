require "test_helper"

# 유권해석 탭: 문서번호 없는 [회신]을 공식 해석처럼 표시하던 회귀 (2026-09-17 G-38).
# 2026-10-05 F1 containment: 기본은 비공개(SILMU_INTERPRETATION_TAB != on). 아래 기존 라벨 테스트는 스위치를 켠 상태의 계약이다.
class TopicInterpretationLabelTest < ActionDispatch::IntegrationTest
  setup { @prev_tab_env = ENV["SILMU_INTERPRETATION_TAB"]; ENV["SILMU_INTERPRETATION_TAB"] = "on" }
  teardown { ENV["SILMU_INTERPRETATION_TAB"] = @prev_tab_env }

  def page(slug, interpretation)
    Rails.cache.clear
    Topic.create!(name: "해석 #{slug}", slug: slug, category: "budget", sector: "common", summary: "요약",
                  commentary: "본문", keywords: "검사", published: false, interpretation_content: interpretation)
    host! "silmu.kr"
    get "/topics/#{slug}"
    assert_response :success
    response.body
  end

  test "NORMAL: unsourced reply is labelled as an example with a notice" do
    body = page("interp-unsourced", "**[질의]** 가능한가요?\n\n**[회신]** 가능합니다(지방재정법 제45조).")
    assert_includes body, "질의·회신 예시"
    assert_includes body, 'data-interpretation-notice="unverified"'
  end

  test "LOWER_BOUND: a cited document number alone does not make it official (운영에서 번호 재사용 확인)" do
    body = page("interp-docno", "**[회신]** 행정안전부 계약제도과-2891 회신에 따르면 가능합니다.")
    assert_includes body, 'data-interpretation-notice="unverified"'
    assert_includes body, "질의·회신 예시"
  end

  test "EDGE: notice sits above the reply text" do
    body = page("interp-order", "**[회신]** 순서 확인용 회신")
    assert_operator body.index('data-interpretation-notice="unverified"'), :<, body.index("순서 확인용 회신")
  end

  test "UPPER_BOUND: article citations alone do not remove the notice" do
    body = page("interp-article", "**[회신]** 지방계약법 시행령 제25조 제1항 제5호에 따라 가능합니다. 2천만원 이하.")
    assert_includes body, 'data-interpretation-notice="unverified"'
  end

  test "EXCEPTION: empty interpretation keeps the placeholder and default label" do
    body = page("interp-empty", nil)
    assert_includes body, "유권해석 정보가 준비 중입니다."
    assert_not_includes body, "질의·회신 예시"
  end

  test "CONTAINMENT: switch off (default) renders neither the tab nor the reply text" do
    ENV.delete("SILMU_INTERPRETATION_TAB")
    body = page("interp-off", "**[회신]** 행정안전부 계약제도과-3102 회신에 따르면 증액 소송이 가능합니다.")
    assert_not_includes body, "계약제도과-3102"
    assert_not_includes body, 'data-tab="interpretation"'
    assert_not_includes body, "질의·회신 예시"
    assert_includes body, 'data-tab="regulation"' # 양성대조: 나머지 더보기 탭은 그대로 있다
  end
end
