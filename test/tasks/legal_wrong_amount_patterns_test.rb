# frozen_string_literal: true

require "test_helper"
require "rake"

# legal:ci_check 의 WRONG_AMOUNT_PATTERNS — 진짜 틀린 기준금액은 잡고, 교육용 예시·단위가 다른
# 금액은 잡지 않는다 (2026-10-05 · 법령 자동 검증 false positive 4건 수리).
class LegalWrongAmountPatternsTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def errors_for(content)
    results = { checked: [], passed: [], errors: [], warnings: [] }
    send(:validate_wrong_patterns, content, "sample.rb", results)
    results[:errors].map { |e| e[:message] }
  end

  test "틀린 수의계약 기준금액은 여전히 오류다(양성 대조)" do
    assert_not_empty errors_for("1인 견적 한도 = 22_000_000")
    assert_not_empty errors_for("2인 견적 물품 = 55,000,000원")
    assert_not_empty errors_for("1인 견적 수의계약은 2,200만원 이하")
    assert_not_empty errors_for("2인 견적 수의계약은 5,500만원 이하")
  end

  test "큰 금액 속 숫자·220만원 단위·면제 불가 예시는 오류가 아니다(음성 대조)" do
    assert_empty errors_for("- 최초 입찰가격: 155,000,000원")
    assert_empty errors_for("예시: 봉급기준액 2,200,000원 → 시간당 약 15,790원")
    assert_empty errors_for("- 계약금액 5,500만원 → 금액 기준으로는 면제 불가")
  end
end
