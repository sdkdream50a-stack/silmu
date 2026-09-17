# frozen_string_literal: true

require "application_system_test_case"

# P0-3 — 실제 브라우저로 서식 상세를 열고 «눌러 보는» 테스트.
#
# 막는 것: 화면에 다운로드 버튼이 보이는데 클릭해도 아무 일이 없는 상태.
#   파일이 repo 에 0개인 동안은 «버튼이 없어야» 맞다. 파일을 확보하면
#   이 테스트를 «클릭 → 파일이 내려온다» 로 바꾼다.
class TemplateDownloadClickTest < ApplicationSystemTestCase
  test "서식 상세에 클릭 가능한 다운로드 버튼이 보이지 않는다" do
    visit template_path(1)
    assert_text "물품구매 표준계약서"

    # 눌릴 수 있는 «다운로드» 컨트롤(버튼·링크)이 화면에 없어야 한다.
    clickable = all("button, a").select { |el| el.text.include?("다운로드") }
    assert_empty clickable.map(&:text),
                 "누를 수 있는 다운로드 컨트롤이 보인다 — 파일이 없는데 누르게 하고 있다"
  end

  test "제공하지 못한다는 안내와 인쇄 버튼이 화면에 보인다" do
    visit template_path(1)
    assert_text "다운로드는 준비 중입니다"
    assert_selector "button", text: "미리보기 인쇄"
  end

  test "인쇄 버튼을 실제로 눌러도 페이지가 깨지지 않는다" do
    visit template_path(3)
    assert_text "물품 검사검수조서"

    # window.print 는 헤드리스에서 모달을 띄우지 않지만 호출 자체를 기록해 확인한다.
    page.execute_script("window.__printed = 0; window.print = function () { window.__printed += 1; };")
    find("button", text: "미리보기 인쇄").click
    assert_equal 1, page.evaluate_script("window.__printed"),
                 "인쇄 버튼을 눌렀는데 window.print 가 호출되지 않았다"

    # 클릭 후에도 미리보기 내용이 그대로 있어야 한다(폼 제출·이동이 일어나지 않았다).
    assert_text "물품 검사검수조서"
  end

  test "모바일 폭에서도 안내와 인쇄 버튼이 보인다" do
    Capybara.current_session.current_window.resize_to(390, 844)
    visit template_path(26)
    assert_text "다운로드는 준비 중입니다"
    assert_selector "button", text: "미리보기 인쇄"
  ensure
    Capybara.current_session.current_window.resize_to(1400, 1000)
  end
end
