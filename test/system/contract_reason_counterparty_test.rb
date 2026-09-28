# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 — 수의계약 사유서 생성기 견적서 자동입력.
# 결함: 견적서에서 읽은 금액이 1억원 이하이면 상대방 유형(여성기업·장애인기업·사회적기업 등
# 특례 대상인지)과 무관하게 무조건 "소액수의"를 자동 선택했다. 그러나 지방계약법 시행령
# 제25조제1항제5호의 소액수의 추정가격 한도는 상대방 유형에 따라 다르다 —
# 일반 2천만원 / 청년창업기업 5천만원 / 소기업·소상공인·여성기업·장애인기업·사회적기업 등 1억원.
# 상대방 유형을 모르는 상태(기본값)에서는 일반 한도(2천만원)만 적용해야 하며,
# 3천만원처럼 일반 한도는 넘지만 특례 한도(5천만원) 이하인 금액을 "모름" 상태에서
# 소액수의로 자동 확정해서는 안 된다.
class ContractReasonCounterpartyTest < ApplicationSystemTestCase
  test "상대방 유형을 모르면 일반 한도(2천만원) 초과 금액은 소액수의를 자동 선택하지 않는다" do
    visit "/tools/contract-reason"

    # 견적서 자동입력 경로를 직접 호출한다 (실제 업로드는 서버 AI 추출에 의존하므로
    # 여기서는 자동입력이 호출하는 매핑 함수만 재현한다).
    page.execute_script(<<~JS)
      window.quMapFields_cr({ total_amount: '30000000' });
    JS

    small_amount_btn = find("[data-reason='small_amount']")
    assert_not small_amount_btn[:class].include?("selected"),
      "상대방 유형 미지정 상태에서 3천만원(일반 한도 2천만원 초과)이 소액수의로 자동 선택되었습니다"

    reason_state = page.evaluate_script("crState.reason")
    assert_nil reason_state, "crState.reason 이 자동으로 채워지지 않아야 합니다 (사용자가 직접 선택해야 함)"
  end

  test "상대방 유형이 소기업/소상공인 등 특례 대상으로 명시되면 1억원 이하는 소액수의 해당" do
    visit "/tools/contract-reason"

    find("[data-type='goods']").click
    find("[data-reason='urgent']").click # 세부 정보(cr-detail-section) 노출용 — 대상 사유는 아래에서 바꾼다
    fill_in "cr-budget", with: "80000000"
    page.execute_script("var s = document.getElementById('cr-counterparty-type'); s.value = 'woman_biz'; s.dispatchEvent(new Event('change'));")

    page.execute_script(<<~JS)
      window.quMapFields_cr({ total_amount: '80000000' });
    JS

    small_amount_btn = find("[data-reason='small_amount']")
    assert small_amount_btn[:class].include?("selected"),
      "여성기업 특례 한도(1억원) 이내 금액은 소액수의로 자동 선택되어야 합니다"
  end
end
