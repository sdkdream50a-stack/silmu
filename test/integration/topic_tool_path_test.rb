# frozen_string_literal: true

require "test_helper"

# 2026-11-24 가이드 → 도구 경로: 여비 토픽은 여비계산기로, 도구 카드 클릭은 계측된다.
class TopicToolPathTest < ActionDispatch::IntegrationTest
  %w[domestic-travel-allowance vehicle-travel-allowance travel-expense].each do |slug|
    test "#{slug} 가이드는 여비계산기로 연결되고 클릭이 계측된다" do
      Topic.find_by(slug: slug)&.destroy
      Topic.create!(name: "여비 테스트", slug: slug, summary: "요약", category: "travel", published: true)
      get topic_path(slug)
      assert_response :success
      assert_select "[data-controller~='next-action'] a[href='#{travel_calculator_path}'][data-action='click->next-action#track'][data-next-action-slot-param='sidebar_tool']"
      assert_select "a[href='#{contract_method_path}'][data-next-action-slot-param='sidebar_tool']", false
    end
  end
end
