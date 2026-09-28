# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P2 — 4대보험 정산.
# ① 국민연금 기준일이 상·하한 고시 구간(2024-07-01~2027-06-30) 밖이면 engine.js가 RangeError를
#    던지는데 컨트롤러가 잡지 않아 화면이 무반응 상태로 멈추고 직전 결과가 그대로 남았다.
# ② 산재보험료율 입력칸에 0을 넣어도 `parseFloat(...) / 100 || 기본값`이 0을 falsy로 취급해
#    기본값(0.786%)으로 되돌아갔다.
class InsuranceCalculatorControllerTest < ApplicationSystemTestCase
  def fill_required(prefix)
    within_field = ->(name) { find("[data-insurance-calculator-target='#{name}#{prefix}']") }
    within_field.call("bonsuWol").set("1340000")
    within_field.call("bonsuTotal").set("12000000")
    within_field.call("geunMonths").set("12")
  end

  def set_ref_date(prefix, iso_date)
    field = find("[data-insurance-calculator-target='pensionRefDate#{prefix}']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1];", field.native, iso_date)
  end

  test "기준일이 고시 구간 밖이면 무반응 대신 알림을 띄우고 결과를 표시하지 않는다" do
    visit "/tools/insurance-calculator"
    set_ref_date("Yearend", "2024-01-01") # 2024-07-01 이전 → 고시 구간 밖
    fill_required("Yearend")

    accept_alert(/고시된 기간/) do
      find("button[data-action='click->insurance-calculator#calculate'][data-tab='yearend']").click
    end

    assert_selector "[data-insurance-calculator-target='resultYearend'].hidden", visible: :all
  end

  test "산재보험료율 0을 입력하면 기본값(0.786%)이 아니라 0으로 계산한다" do
    visit "/tools/insurance-calculator"
    fill_required("Yearend")
    find("[data-insurance-calculator-target='accidentRateYearend']").set("0")

    find("button[data-action='click->insurance-calculator#calculate'][data-tab='yearend']").click

    assert_text "산재보험 (기관)"
    row = find("tr", text: "산재보험 (기관)")
    # 월 보험료 열 — 0원이어야 한다(기본 0.786% 적용 시 10,530원대가 나온다)
    assert_match(/^0(원)?$/, row.all("td")[1].text.strip)
  end
end
