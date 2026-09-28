# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P2 — 보조금 정산 체크리스트.
# ① 지방보조금을 선택해도 공통 섹션에 국고 조문("보조금법 제22조")·e나라도움이 그대로 나와
#    지방 담당자가 보탬e(지방보조금관리시스템) 대신 e나라도움에 제출하는 것으로 오인할 수 있다.
# ② 집행액이 교부액을 초과해도(잔액 음수) 경고가 없었다.
class SubsidySettlementCheckerTest < ApplicationSystemTestCase
  test "지방보조금을 선택하면 공통 문구도 지방 조문·보탬e로 바뀐다" do
    visit "/tools/subsidy-settlement-checker"
    select "지방보조금 (지방보조금 관리기준 적용)", from: "subsidy-type"

    within "#checklist-result" do
      assert_text "지방보조금법 제13조"
      assert_text "보탬e"
      assert_no_text "보조금법 제22조"
      assert_no_text "e나라도움"
    end
  end

  test "국고보조금을 선택하면 국고 조문·e나라도움 문구가 그대로 나온다" do
    visit "/tools/subsidy-settlement-checker"
    select "국고보조금 (보조금법 적용)", from: "subsidy-type"

    within "#checklist-result" do
      assert_text "보조금법 제22조"
      assert_text "e나라도움"
    end
  end

  test "집행액이 교부액을 초과하면 경고를 보여준다" do
    visit "/tools/subsidy-settlement-checker"
    select "국고보조금 (보조금법 적용)", from: "subsidy-type"
    fill_in "subsidy-amount", with: "5000"
    fill_in "executed-amount", with: "6000"

    within "#checklist-result" do
      assert_text "교부액 초과 집행"
      assert_text "교부액보다"
    end
  end
end
