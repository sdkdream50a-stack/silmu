require "test_helper"

# 유권해석 탭: 문서번호 없는 [회신]을 공식 해석처럼 표시하던 회귀 (2026-09-17 G-38).
class TopicInterpretationLabelTest < ActionDispatch::IntegrationTest
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
end
