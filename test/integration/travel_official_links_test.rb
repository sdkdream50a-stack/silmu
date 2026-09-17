require "test_helper"

# 여비 토픽 공식 자료 카드 (2026-09-17): 법령정보센터에 없는 «지방공무원 여비 규정» 링크·국외여비 기획재정부 소관 표기 정정.
class TravelOfficialLinksTest < ActionDispatch::IntegrationTest
  test "travel-expense resources point at 공무원 여비 규정, not 기획재정부" do
    Rails.cache.clear
    Topic.create!(name: "출장비", slug: "travel-expense", category: "travel", sector: "common", summary: "요약",
                  commentary: "본문", keywords: "출장", published: false)
    host! "silmu.kr"
    get "/topics/travel-expense"
    assert_response :success
    assert_not_includes response.body, "moef.go.kr"
    assert_not_includes response.body, "지방공무원여비규정"
    assert_includes response.body, "별표 4(국외 여비 지급표)"
  end
end
