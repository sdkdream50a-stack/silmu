# frozen_string_literal: true

require "test_helper"

# P0-2 (LECTURE_READINESS_AUDIT R1) — 적용기관 고지가 **화면에 실제로 렌더되는지**.
#
# 등록부에만 있고 화면에 안 붙으면 학교 사용자는 여전히 모른다.
# 그래서 이 테스트는 config 를 읽지 않고 응답 본문을 읽는다.
class JurisdictionNoticeTest < ActionDispatch::IntegrationTest
  NOTICED_TOOLS = {
    "budget-category-finder"  => :budget_category_finder_url,
    "budget-execution-rate"   => :budget_execution_rate_url,
    "budget-transfer-checker" => :budget_transfer_checker_url
  }.freeze

  test "지자체 기준 예산 도구 3종 화면에 적용 범위 4필드가 렌더된다" do
    NOTICED_TOOLS.each do |key, url_helper|
      get public_send(url_helper)
      assert_response :success

      body = response.body
      assert_includes body, "적용 범위",  "#{key}: 고지 블록 자체가 없다"
      assert_includes body, "적용대상",   "#{key}: 적용대상 없음"
      assert_includes body, "적용기관",   "#{key}: 적용기관 없음"
      assert_includes body, "근거 지침",  "#{key}: 근거 지침 없음"
      assert_includes body, "기준연도",   "#{key}: 기준연도 없음"
      assert_includes body, "지방자치단체", "#{key}: 어느 기관 기준인지 화면에 없다"
    end
  end

  test "학교 사용자에게 차이 고지와 학교회계 경로가 함께 렌더된다" do
    NOTICED_TOOLS.each do |key, url_helper|
      get public_send(url_helper)
      assert_response :success

      assert_match(/학교·교육행정 사용자라면/, response.body, "#{key}: 학교 고지 문구 없음")
      assert_match(%r{href="/topics/school-budget-compilation"}, response.body,
                   "#{key}: 경고만 하고 학교회계 대안 경로를 주지 않는다")
    end
  end

  test "기준연도 미확인은 «미표기» 로 정직하게 나가고 날짜를 만들어내지 않는다" do
    get budget_execution_rate_url
    assert_response :success
    assert_match(/미표기 — 소속 기관의 당해연도 지침 원문을 확인하세요/, response.body)
    assert_no_match(/기준연도<\/dt>\s*<dd[^>]*>\s*<span class="text-slate-800">UNVERIFIED/, response.body,
                    "UNVERIFIED 문자열이 기준연도로 그대로 노출된다")
  end

  test "집행률 도구에 회계연도 시작월 선택(1월·3월)이 있다" do
    get budget_execution_rate_url
    assert_response :success
    assert_match(/id="fiscal-start-month"/, response.body, "회계연도 시작월 선택이 없다")
    assert_match(/1월 — 지방자치단체·국가/, response.body)
    assert_match(/3월 — 학교회계/, response.body)
  end

  test "집행률 도구가 법령이 집행 목표율을 정한다고 말하지 않는다" do
    get budget_execution_rate_url
    assert_response :success
    assert_no_match(/달성해야 하며, 미달 시 다음 연도 예산 삭감/, response.body,
                    "법령 근거 없는 의무 단정이 화면에 있다")
    assert_match(/법령이 정한 분기·연도말 집행 목표율은 없습니다/, response.body)
    assert_match(/참고용 · 공식 목표 아님/, response.body, "참고선 라벨 강등 표시가 없다")
  end

  # 음성 대조 — 고지를 등록하지 않은 도구에는 고지 블록이 생기지 않는다.
  test "미등록 도구(계약방식)에는 적용 범위 블록이 렌더되지 않는다" do
    get contract_method_url
    assert_response :success
    assert_not_includes response.body, "학교·교육행정 사용자라면",
                        "등록하지 않은 도구에 고지가 생겼다"
  end
end
