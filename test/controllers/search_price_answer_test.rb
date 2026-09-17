require "test_helper"

# 검색 결과 위 금액 판정 카드 (2026-09-17 업무흐름 감사 13 W-02).
class SearchPriceAnswerTest < ActionDispatch::IntegrationTest
  TURBO = { "Turbo-Frame" => "search-results" }.freeze

  def search(q)
    get "/silmu-search/search", params: { q: q }, headers: TURBO
    assert_response :success
    response.body
  end

  test "NORMAL: 물품 1500만원 → 1인 견적 수의계약 카드" do
    body = search("물품 1500만원")
    assert_includes body, 'data-price-answer="private_1"'
    assert_includes body, "1인 견적 수의계약"
    assert_includes body, "/silmu-search/price?category=goods&amp;price=15000000"
  end

  test "EDGE: 물품 3억원은 경쟁입찰" do
    assert_includes search("물품 3억원"), 'data-price-answer="bidding"'
  end

  test "LOWER_BOUND (음성): 금액 없는 일반 질의에는 카드가 없다" do
    assert_not_includes search("수의계약 사유서"), "data-price-answer"
  end

  test "UPPER_BOUND: 공사 30억은 경쟁입찰" do
    assert_includes search("공사 30억"), 'data-price-answer="bidding"'
  end

  test "EXCEPTION: 유형 없는 금액 질의에는 카드가 없다" do
    assert_not_includes search("1500만원 계약"), "data-price-answer"
  end
end
