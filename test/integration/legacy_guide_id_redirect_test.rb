require "test_helper"

# 숫자 id 시절(2026-02 GuidesController::GUIDES 해시, 8782970^) 가이드 URL 회귀 (2026-09-28 감사 07 SO-14).
# 종전: /guides/1..10 전부 RecordNotFound → 302 /guides(목록). 옛 id 는 해시의 id→title 과
# 이관 시드(8782970 db/seeds/guides.rb)의 title→slug 로 1:1 확정된다. id 10 은 해시에 없었다.
class LegacyGuideIdRedirectTest < ActionDispatch::IntegrationTest
  LEGACY = {
    1 => "purchase-and-inspection", 2 => "inspection-report", 3 => "estimated-price",
    4 => "private-contract-guide", 5 => "travel-expense-guide", 6 => "annual-leave-guide",
    7 => "civil-complaint-guide", 8 => "budget-carryover-guide", 9 => "bidding-guide"
  }.freeze

  test "legacy numeric guide ids 301 to their canonical guide" do
    LEGACY.each do |id, slug|
      get "/guides/#{id}"
      assert_response :moved_permanently, "/guides/#{id}"
      assert_equal "http://www.example.com/guides/#{slug}", response.location
    end
  end

  test "unmapped numeric id keeps the list fallback (no guessing)" do
    get "/guides/10"
    assert_redirected_to "/guides"
  end
end
