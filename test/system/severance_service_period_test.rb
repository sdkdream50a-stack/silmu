# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P0 — 공무원연금법 §25① 월 단위 재직기간. 종전 ÷365·÷30 계산은 5년 경계에서 비율 등급을 뒤집었다.
class SeverancePeriodTest < ApplicationSystemTestCase
  CASES = {
    %w[2020-03-31 2025-03-01] => 60, # 2020.3 ~ 2025.2 = 5년 (종전 4년 11개월 → 6.5% 로 오산)
    %w[2025-01-15 2026-01-14] => 13, # 2025.1 ~ 2026.1 = 1년 1개월
    %w[2024-02-29 2028-02-29] => 49, # 윤년 — 2024.2 ~ 2028.2 = 4년 1개월
    %w[2025-01-01 2025-02-01] => 1   # 음성 대조 — 2025.1 한 달
  }.freeze

  test "재직기간은 임명 달부터 퇴직 전날 달까지의 월수다" do
    visit "/tools/severance-calculator"
    CASES.each do |(hire, retire), months|
      assert_equal months, page.evaluate_script("serviceMonths('#{hire}', '#{retire}')"), "#{hire}~#{retire}"
    end
  end

  test "날짜 입력 모드가 5년을 22.75% 구간으로 넣는다" do
    visit "/tools/severance-calculator"
    page.execute_script(<<~JS)
      document.getElementById('hire-date').value = '2020-03-31';
      document.getElementById('retire-date').value = '2025-03-01';
      calculateFromDates();
    JS
    assert_equal "5", find("#service-years", visible: :all).value
    assert_equal "0", find("#service-months", visible: :all).value
  end
end
