# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P2 — 수의계약 사유서 생성기.
# 예시문의 "○○원" 자리표시자가 실제 소요예산으로 치환되지 않아, 사용자가 예시문을
# 그대로 두고 생성하면 "추정가격이 금 ○○원으로…"라는 문서가 그대로 나왔다.
class ContractReasonPlaceholderTest < ApplicationSystemTestCase
  test "예시문을 그대로 써도 생성 문서에는 실제 소요예산이 들어간다" do
    visit "/tools/contract-reason"

    find("[data-type='goods']").click
    find("[data-reason='small_amount']").click
    find("#cr-example-hint").click # 예시문 채우기 — "○○원" 그대로 남음
    fill_in "cr-contract-name", with: "사무실 LED 조명 교체"
    fill_in "cr-budget", with: "15000000"

    find("button", text: "사유서 생성", match: :first).click

    doc = find("#cr-doc-content")
    assert_no_match(/○○원/, doc.text)
    assert_match(/15,000,000원/, doc.text)
  end
end
