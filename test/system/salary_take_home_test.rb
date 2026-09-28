# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P0 — 봉급 실수령액.
# ① 공무원보수규정 별표 3(개정 2026. 1. 2.) 3급은 27호봉(6,783,800원)까지 있다.
# ② 지방공무원 수당 등에 관한 규정 제6조제3항·별표 2 정근수당 가산금은 «5년 미만 30,000원» — 1년 미만도 받는다.
# ③ 소득세는 공제 없이 총급여에 세율을 씌우던 추정(9급 1호봉 월 59,450원)이 약 3배 과대였다.
class SalaryTakeHomeTest < ApplicationSystemTestCase
  def open_default
    visit "/tools/salary-calculator"
    page.execute_script("updateHobonOptions(); calculate();")
  end

  test "3급 27호봉이 별표 3 금액으로 선택된다" do
    open_default
    page.execute_script("selectGrade(3)")
    assert_selector "#hobon-select option[value='27']", text: "27호봉 — 6,783,800원", visible: :all
    assert_no_selector "#hobon-select option[value='28']", visible: :all
  end

  test "재직 5년 미만은 1년 미만을 포함해 가산금 30,000원이다" do
    open_default
    assert_equal "30000", find("#tenure-select option", match: :first, visible: :all).value
    assert_no_selector "#tenure-select option[value='0']", visible: :all
  end

  # 9급 1호봉 2,133,000 + 가산금 30,000 = 2,163,000 → 총급여 25,956,000
  # 근로소득공제 9,143,400 · 기본공제 1,500,000 · 연금 191,970×12
  # 표준세액공제 쪽: 과세표준 13,008,960 × 6% = 780,538 − 근로소득세액공제 429,296 − 130,000 = 221,242 → 월 18,437
  # 지방소득세 1,844 → 합계 20,281 (건강보험료 공제 쪽은 월 26,928 로 불리)
  test "9급 1호봉 소득세는 법정 공제를 반영한 연간 세액의 1/12 이다" do
    open_default
    assert_equal "-20,281원", find("#r-tax", visible: :all).text(:all)
  end

  test "부양가족 기본공제가 세액을 줄인다" do
    open_default
    single = find("#r-tax", visible: :all).text(:all).delete("^0-9").to_i
    page.execute_script("document.getElementById('allowance-spouse').checked = true; calculate();")
    assert_operator find("#r-tax", visible: :all).text(:all).delete("^0-9").to_i, :<, single
  end
end
