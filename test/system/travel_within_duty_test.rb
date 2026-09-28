# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P1 — 같은 시·군 안 출장은 근무지 내 국내 출장(공무원 여비 규정 제18조): 4시간 이상 2만원.
# 종전에는 서울→서울 당일에 식비·일비 50,000원을 계산했다.
class TravelWithinDutyTest < ApplicationSystemTestCase
  def trip(from, to)
    visit "/tools/travel-calculator"
    fill_in "departure", with: from
    fill_in "destination", with: to
    page.execute_script(<<~JS)
      const today = new Date().toISOString().slice(0, 10);
      document.querySelector('[data-travel-calculator-target="startDate"]').value = today;
      document.querySelector('[data-travel-calculator-target="endDate"]').value = today;
      document.querySelector('input[name="transport"][value="bus"]').checked = true;
    JS
    find("form[data-travel-calculator-target=\"form\"] button[type=\"submit\"]").click
    find('[data-travel-calculator-target="totalAmount"]').text
  end

  test "서울→서울 당일은 근무지 내 출장 2만원이다" do
    assert_equal "₩ 20,000", trip("서울", "서울")
  end

  test "음성 대조 — 서울→부산 당일은 식비·일비 5만원에 운임이 붙는다" do
    total = trip("서울", "부산").delete("^0-9").to_i
    assert_operator total, :>, 50_000
  end
end
