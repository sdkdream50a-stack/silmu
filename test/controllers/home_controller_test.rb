require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  # 전수감사 UX TOP#1 — 칩이 frame 전용 endpoint 로 가면 301 캐시 때문에 답 대신 기본 목록이 뜬다.
  # 검색 폼과 같은 페이지(/silmu-search)로 보내야 폼 입력과 같은 frame 요청이 난다.
  test "홈 예시 질문 칩은 검색 폼과 같은 URL 로 간다" do
    get root_url
    assert_select "a[href^='/silmu-search/search']", 0
    assert_select "a[href^=?][href*=?]", "/silmu-search?q=", "src=home_chip", count: 4
  end

  test "홈 검색창 돋보기 아이콘에 패딩 클래스가 직접 붙지 않는다" do
    get root_url
    assert_select "form[action='/silmu-search'] .material-symbols-outlined", text: "search", count: 1
    assert_select "form[action='/silmu-search'] .material-symbols-outlined.pl-3", 0
  end

  test "SEASONAL_TOPICS에 정의된 모든 slug가 Topic 테이블에 존재해야 한다" do
    all_slugs = HomeController::SEASONAL_TOPICS.values.flat_map(&:values).flatten.uniq
    skip "Topic 시드 데이터가 없는 환경에서는 건너뜁니다" if Topic.count < all_slugs.size / 2
    all_slugs = HomeController::SEASONAL_TOPICS.values.flat_map(&:values).flatten.uniq
    missing = all_slugs.reject { |slug| Topic.exists?(slug: slug) }
    assert missing.empty?,
      "SEASONAL_TOPICS에 누락된 Topic slug: #{missing.join(', ')}\n" \
      "Topic을 생성하거나 SEASONAL_TOPICS에서 해당 slug를 제거하세요."
  end

  test "SEASONAL_TOPICS는 모든 sector × 12개월을 커버해야 한다" do
    sectors = HomeController::SEASONAL_TOPICS.keys
    sectors.each do |sector|
      (1..12).each do |month|
        assert HomeController::SEASONAL_TOPICS[sector].key?(month),
          "SEASONAL_TOPICS[:#{sector}][#{month}]가 없습니다."
      end
    end
  end
end
