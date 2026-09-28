# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 — 지방재정법 §49② 전용 금지 사유(의회 의결 취지와 다른 집행 등)를 체크 해제해도
# «추가 검토» 로만 나오던 판정을 고정한다. 법이 금지한 항목 하나라도 빠지면 «전용 불가».
class BudgetTransferCheckerVerdictTest < ApplicationSystemTestCase
  def check_all_except(*texts)
    visit "/tools/budget-transfer-checker"
    page.execute_script("switchTab('transfer')")
    page.execute_script(<<~JS, texts)
      const skip = arguments[0];
      document.querySelectorAll('input.transfer-chk').forEach(box => {
        const label = box.closest('label').innerText;
        box.checked = !skip.some(t => label.includes(t));
      });
      checkTransfer();
    JS
    find("#transfer-result").text
  end

  test "모든 요건을 충족하면 전용 가능" do
    assert_includes check_all_except, "전용 가능 요건 충족"
  end

  test "지방의회 의결 취지와 다른 집행이면 전용 불가 (§49②2)" do
    assert_includes check_all_except("지방의회가 의결한 취지"), "전용 불가"
  end

  test "예산에 계상되지 않은 사업이면 전용 불가 (§49②1)" do
    assert_includes check_all_except("예산에 계상된 사업"), "전용 불가"
  end

  test "음성 대조 — 사후 제출 절차만 남으면 불가가 아니라 추가 검토" do
    text = check_all_except("분기별 의회 제출")
    assert_includes text, "추가 검토"
    assert_not_includes text, "전용 불가"
  end
end
