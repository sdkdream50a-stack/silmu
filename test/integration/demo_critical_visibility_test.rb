# frozen_string_literal: true

require "test_helper"

# PHASE E — «검사가 통과했다» 와 «사용자가 봤다» 를 구별한다.
#
# 2026-09-18 실브라우저 실측: 예산 집행률 도구의 가장 중요한 문장
# «법령이 정한 분기·연도말 집행 목표율은 없습니다» 가 **접힌 `<details>` 안**에만 있었다
# (getBoundingClientRect().width = 0). 스모크는 HTML 을 grep 하므로 PASS 였다.
# 이 도구에서 가장 비싼 오해가 «참고선 = 법정 목표» 인데, 그것을 막는 문장이 안 보였다.
#
# test 에는 렌더 엔진이 없어 «보인다» 를 직접 잴 수 없다. 대신 **접힘 요소 밖에도 있는가**
# 를 본다 — 그것이 test 층에서 가능한 가장 가까운 질문이다.
class DemoCriticalVisibilityTest < ActionDispatch::IntegrationTest
  # 접힌 <details> 블록을 통째로 지운 나머지 = «펼치지 않아도 읽히는 부분» 의 근사
  def body_outside_collapsed_details(html)
    html.gsub(/<details(?![^>]*\bopen\b)[^>]*>.*?<\/details>/m, "")
  end

  test "«법정 목표율 없음» 이 접힘 밖에서도 읽힌다" do
    get budget_execution_rate_url
    assert_response :success

    sentence = "법령이 정한 분기·연도말 집행 목표율은 없습니다"
    assert response.body.include?(sentence), "문장 자체가 사라졌다"

    visible = body_outside_collapsed_details(response.body)
    assert visible.include?(sentence),
           "그 문장이 접힌 details 안에만 있다 — 펼치지 않는 사람은 참고선을 법정 목표로 읽는다"
  end

  test "검사 방법 자체가 살아 있다" do  # 양성 대조
    # 접힘 제거 로직이 실제로 무언가를 지우는가. 아무것도 안 지우면 위 검사는 무의미하다.
    html = %(<p>보임</p><details><summary>s</summary><p>숨김</p></details>)
    out = body_outside_collapsed_details(html)
    assert out.include?("보임")
    assert_not out.include?("숨김"), "접힘 제거가 동작하지 않는다 — 위 검사가 허공을 본다"

    open_html = %(<details open><p>펼쳐짐</p></details>)
    assert body_outside_collapsed_details(open_html).include?("펼쳐짐"),
           "open 인 details 까지 지운다 — 과도하다"
  end

  test "참고용 배지도 접힘 밖에 있다" do
    get budget_execution_rate_url
    visible = body_outside_collapsed_details(response.body)
    assert visible.include?("참고용 · 공식 목표 아님"),
           "배지가 접힘 안에 있다"
  end
end
