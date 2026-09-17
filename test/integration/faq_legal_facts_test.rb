require "test_helper"

# /faq 하드코딩 답변의 법령 사실 회귀 (2026-09-17 전수감사 P0).
# 원문 대조: 지방계약법 시행령 §67①(5일) · 지방자치법 §142(50일/40일) · 지방재정법 §50 ·
# 국가공무원 복무규정 §15①(2024.7.2)·별표2(2025.2.11 배우자 출산 20일) · 수당규정 §11의3.
class FaqLegalFactsTest < ActionDispatch::IntegrationTest
  STALE = [
    "지방자치단체: 14일 이내",
    "11월 30일까지",
    "지방재정법 제42조, 제43조",
    "1년 이상~2년 미만: 12일",
    "최초 3개월 80%, 이후 50%",
    "배우자 출산 특별휴가 10일",
    "출생일로부터 90일 이내"
  ].freeze

  test "faq answers carry the current legal facts and none of the stale ones" do
    host! "silmu.kr"
    get "/faq"
    assert_response :success
    body = response.body

    # 양성대조 — 같은 응답에 새 사실이 실제로 있다
    [ "청구를 받은 날부터 5일 이내", "지방자치법 제142조", "지방재정법 제50조",
      "1년 이상~3년 미만: 15일", "배우자 출산휴가는 20일", "제11조의3" ].each do |fact|
      assert_includes body, fact
    end
    STALE.each { |phrase| assert_not_includes body, phrase, "옛 사실 잔존: #{phrase}" }
  end
end
