# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P1 — 초과근무수당.
# · 지방 수당규정 제15조제5항: 월별 시간외근무시간은 1시간 미만을 버린다.
# · 제17조의2제2항·별표 12: 관리업무수당(4급 이상) 지급자에게는 시간외·야간·휴일근무수당을 지급하지 않는다.
class OvertimeRulesTest < ApplicationSystemTestCase
  def fill(grade, hours)
    page.execute_script(<<~JS)
      document.getElementById('grade-select').value = '#{grade}';
      document.getElementById('overtime-hours').value = '#{hours}';
      calculate();
    JS
  end

  test "월 시간외 10.5시간은 10시간으로 계산한다" do
    visit "/tools/overtime-calculator"
    fill(9, 10.5)
    assert_includes find("#overtime-detail", visible: :all).text(:all), "× 10시간"
    fill(9, 11)
    assert_includes find("#overtime-detail", visible: :all).text(:all), "× 11시간"
  end

  test "4급을 고르면 관리업무수당 지급자 비지급 안내가 보인다" do
    visit "/tools/overtime-calculator"
    fill(4, 20)
    assert_selector "#manager-allowance-warning", text: "제17조의2제2항"
    fill(5, 20)
    assert_no_selector "#manager-allowance-warning"
  end
end
