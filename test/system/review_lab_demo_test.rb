# frozen_string_literal: true

require "application_system_test_case"

# 실무 검증실 — 연수 시연 경로를 실제 브라우저로 끝까지 누른다.
#
# 세션 쿠키 도메인이 .silmu.kr 이라 테스트 서버(127.0.0.1)에서는 쿠키가 남지 않는다.
# 그래서 Warden 의 login_as(«다음 요청 1회» 로그인)를 요청 직전마다 건다.
class ReviewLabDemoTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  # CDP 기기 에뮬레이션과 창 크기는 브라우저 세션에 남는다 — 해제·복구하지 않으면 같은 브라우저를 쓰는
  # 다음 system test(topic_more_tabs 의 더보기 클리핑 측정)가 이 테스트의 폭으로 돈다(CI seed 39241 로 재현).
  teardown do
    Warden.test_reset!
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1400, 1000) # ApplicationSystemTestCase 기본 크기
  end

  # 헤드리스 Chrome 창은 폭 500px 밑으로 줄지 않는다 — 390 을 390 으로 재려면 기기 에뮬레이션을 쓴다.
  def set_width(width, height = 900)
    page.driver.browser.manage.window.resize_to([ width, 500 ].max, [ height, 900 ].max)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
                                    width: width, height: height, deviceScaleFactor: 1, mobile: width < 500)
  end

  def open_demo(kind_label, width:)
    @width = width
    set_width(width)
    login_as users(:one), scope: :user
    visit review_lab_path
    # 에뮬레이션 전환 직후 레이아웃이 다시 잡히는 동안 누르면 «Node … does not belong to the document» 가 난다(CI 실측).
    # 버튼이 실제로 보일 때까지 기다린 뒤 그 노드를 누른다.
    button = find_button(kind_label, wait: 10)
    login_as users(:one), scope: :user
    button.click
  end

  def assert_no_page_overflow
    assert_equal @width, page.evaluate_script("window.innerWidth"), "측정 폭이 의도와 다르다 — 390 을 재지 않은 결과는 무효"
    over = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
    assert_operator over, :<=, 0, "페이지 전체가 가로로 넘친다(#{over}px) — 표는 자기 안에서만 스크롤해야 한다"
  end

  # 사람 눈 확인용(SAVE_SHOTS=1 일 때만) — 창 높이를 문서 높이로 늘려 한 장에 담는다.
  def shot(name, width)
    return unless ENV["SAVE_SHOTS"]

    set_width(width, page.evaluate_script("document.documentElement.scrollHeight"))
    page.save_screenshot(Rails.root.join("tmp/screenshots/#{name}.png").to_s)
  end

  test "모바일 390 — 공고 패키지 demo 가 끝까지 열리고 가로로 넘치지 않는다" do
    open_demo("가상 공고 패키지 검토", width: 390)
    assert_text "가상 예시 문서입니다"
    assert_text "빠진 것도, 더 나온 것도 없습니다"
    assert_text "문서 간 상호대조"
    assert_selector "[data-code='X-CONFLICT'][data-severity='BLOCK']", count: 3
    assert_no_page_overflow
    shot("review_lab_package_390", 390)
  end

  test "데스크톱 1280 — 견적서 demo 의 확정 오류·계약방식 연결·가격 근거가 보인다" do
    open_demo("가상 견적서 검토", width: 1280)
    assert_text "가상 예시 문서입니다"
    assert_selector "[data-code='Q-ROW'][data-severity='BLOCK']"
    assert_text "계약방식·견적 요건"
    assert_text "가격 근거 (적정성 판정 아님)"
    assert_no_page_overflow
    shot("review_lab_quote_1280", 1280)
  end
end
