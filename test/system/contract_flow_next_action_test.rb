# frozen_string_literal: true

require "application_system_test_case"

# P2 (2026-09-20 · CONNECTED_WORKFLOW) — 실제 브라우저로 «업무 하나 끝까지» 를 눌러 본다.
#
# 왜 system test 인가: 단계 상세 패널은 Stimulus 가 클라이언트에서 만든다. 통합 테스트는
# 응답 HTML 만 보므로 «결속 페이로드는 실렸는데 화면에는 안 나온다» 를 재현하지 못한다.
# P2 의 성공 기준이 «메뉴로 돌아가지 않고 이어갈 수 있다» 이므로, 이어지는지를 눌러서 잰다.
class ContractFlowNextActionTest < ApplicationSystemTestCase
  test "단계를 열면 그 단계에서 쓸 도구가 보이고 실제로 눌린다" do
    visit contract_flow_path
    find('.flow-step[data-step="goods-3"]').click

    assert_text "다음 행동"
    assert_text "이 단계에서 쓸 도구"
    link = find("a", text: "계약방식 결정 도우미")
    assert_equal "/tools/contract-method", URI.parse(link[:href]).path

    link.click
    assert_current_path "/tools/contract-method"
  end

  test "«다음 단계» 를 누르면 메뉴로 돌아가지 않고 다음 단계가 열린다" do
    visit contract_flow_path
    find('.flow-step[data-step="goods-3"]').click
    assert_text "계약방법 결정"

    find(".flow-next-step-btn").click

    # 4단계 상세가 열렸는가 — 4단계에만 있는 결속으로 판정한다(제목은 카드에도 있어 약하다).
    assert_text "견적서 검토 도구"
    assert_selector '.flow-step[data-step="goods-4"].selected'
    assert_equal contract_flow_path, URI.parse(page.current_url).path,
                 "다음 단계로 가면서 페이지를 떠났다 — 메뉴로 돌아가게 만들고 있다"
  end

  test "마지막 단계에는 «다음 단계» 버튼 대신 끝이라고 적는다" do
    visit contract_flow_path
    find('.flow-step[data-step="goods-8"]').click

    assert_text "이 흐름의 마지막 단계입니다"
    assert_no_selector ".flow-next-step-btn"
  end

  test "결속이 계측을 달고 나온다" do  # §14 — 새 이벤트 없이 next_action_click 재사용
    visit contract_flow_path
    find('.flow-step[data-step="goods-3"]').click

    link = find("a", text: "계약방식 결정 도우미")
    assert_equal "goods-3:/tools/contract-method", link["data-next-action-slot-param"]
    assert_includes link["data-action"].to_s, "next-action#track"
  end

  test "결속이 없는 단계는 빈 «다음 행동» 상자를 그리지 않는다" do
    # 양성 대조 — 상자가 «항상» 그려지면 위 검사들은 아무것도 재지 않는다.
    # 현재 24단계 전부에 결속이 있으므로, 한 단계의 결속을 **실제로 비워** 같은 경로를 태운다.
    visit contract_flow_path
    find('.flow-step[data-step="goods-3"]').click
    assert_selector ".flow-bindings", text: "계약방식 결정 도우미"

    page.execute_script(<<~JS)
      const el = document.querySelector('.flow-page')
      const data = JSON.parse(el.dataset.contractFlowBindingsValue)
      delete data['goods-3']
      el.dataset.contractFlowBindingsValue = JSON.stringify(data)
    JS

    find('.flow-step[data-step="goods-3"]').click  # 닫고
    find('.flow-step[data-step="goods-3"]').click  # 다시 연다
    assert_text "계약방법 결정"
    # 결속을 비웠는데도 상자가 그려지면 그 상자는 데이터와 무관하다는 뜻이다.
    assert_no_selector ".flow-bindings"
  end

  # ── 모바일 390px ──────────────────────────────────────────────────────
  test "390px 에서 결속 링크가 가로 스크롤 없이 눌린다" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit contract_flow_path
    find('.flow-step[data-step="goods-3"]').click

    assert_text "계약방식 결정 도우미"
    overflow = page.evaluate_script(
      "document.documentElement.scrollWidth - document.documentElement.clientWidth"
    )
    assert_operator overflow, :<=, 0, "390px 에서 가로 스크롤이 생긴다 (#{overflow}px)"

    link = find("a", text: "계약방식 결정 도우미")
    height = page.evaluate_script(
      "arguments[0].getBoundingClientRect().height", link.native
    )
    assert_operator height, :>=, 24, "손가락으로 누르기에 너무 얇다 (#{height}px)"
  end
end
