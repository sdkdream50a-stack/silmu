# frozen_string_literal: true

require "application_system_test_case"

# P4 §17 — 새 면(사업계획·산출기초 검토)이 **390px 에서 가로로 넘치지 않는가**.
# 측정 방식은 기존 `review_lab_demo_test.rb` 와 같다 — 헤드리스 창은 500px 밑으로 줄지 않으므로
# CDP 기기 에뮬레이션으로 390 을 실제로 만들고, «정말 390 을 쟀는가» 를 먼저 단언한다.
class ReviewLabBudgetMobileTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  teardown do
    Warden.test_reset!
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1400, 1000)
  end

  def set_width(width, height = 900)
    page.driver.browser.manage.window.resize_to([ width, 500 ].max, [ height, 900 ].max)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
                                    width: width, height: height, deviceScaleFactor: 1, mobile: width < 500)
  end

  def assert_no_page_overflow(width)
    assert_equal width, page.evaluate_script("window.innerWidth"),
                 "측정 폭이 의도와 다르다 — #{width} 를 재지 않은 결과는 무효"
    over = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
    assert_operator over, :<=, 0, "페이지 전체가 가로로 넘친다(#{over}px)"
  end

  test "390px — 안내 화면이 넘치지 않고, 하지 않는 것이 업로드 전에 보인다" do
    set_width(390)
    visit review_lab_budget_path
    assert_text "이 검토가 하지 않는 것"
    assert_text "예산과목"
    assert_no_page_overflow(390)
  end

  test "390px — 가상 문서 검토 결과가 끝까지 열리고 넘치지 않는다" do
    set_width(390)
    login_as users(:one), scope: :user
    visit review_lab_path
    button = find_button("가상 사업계획·산출기초 검토", wait: 10)
    login_as users(:one), scope: :user
    button.click
    assert_text "빠진 것도, 더 나온 것도 없습니다"
    assert_no_page_overflow(390)
  end

  test "1400px 에서도 같은 측정식이 통과한다 — 측정이 폭에 관계없이 살아 있다" do  # 양성 대조
    set_width(1400, 1000)
    visit review_lab_budget_path
    assert_no_page_overflow(1400)
  end
end
