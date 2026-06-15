require "test_helper"

class ChatbotControllerTest < ActionDispatch::IntegrationTest
  # turbo_frame 요청만 검색 결과를 렌더 (직접 접근은 리다이렉트)
  TURBO_HEADERS = { "Turbo-Frame" => "search-results" }.freeze

  test "검색 결과에 도구가 포함된다 ('여비' → 여비계산기)" do
    get silmu_search_search_path(q: "여비"), headers: TURBO_HEADERS
    assert_response :success
    assert_select "[data-search-result='tool']"
    assert_match "여비계산기", response.body
  end

  test "도구 검색 결과가 tool_count 로 로깅된다" do
    assert_difference -> { SearchLog.count }, 1 do
      get silmu_search_search_path(q: "여비"), headers: TURBO_HEADERS
    end
    log = SearchLog.order(:created_at).last
    assert_operator log.tool_count, :>=, 1
    assert_not log.zero_result
  end

  test "직접 접근은 silmu-search 인덱스로 리다이렉트" do
    get silmu_search_search_path(q: "여비")
    assert_response :moved_permanently
  end

  test "레지스트리 도구가 검색된다 ('가족수당' → 공무원 수당 계산기)" do
    get silmu_search_search_path(q: "가족수당"), headers: TURBO_HEADERS
    assert_response :success
    assert_match "공무원 수당 계산기", response.body
  end

  # 2026-06-11 a827467: 전수 감사 통과로 종전 unlisted 6개 도구를 /tools 카드 목록에 게재(NEW 배지).
  # 종전 테스트는 "노출 안 됨"을 단언했으나 의도적 게재 후 stale → 현재 의도(노출됨)로 정정.
  test "감사 통과 도구(예산 과목 분류 도우미)는 tools 인덱스 카드 목록에 노출된다" do
    get tools_path
    assert_response :success
    assert_match "예산 과목 분류 도우미", response.body
  end
end
