require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "SEASONAL_TOPICS에 정의된 모든 slug가 Topic 테이블에 존재해야 한다" do
    skip "Topic 데이터가 없는 환경에서는 건너뜁니다" if Topic.count == 0
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
