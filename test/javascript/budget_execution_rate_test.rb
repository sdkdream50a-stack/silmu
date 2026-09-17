# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — 집행률 참고선 회귀를 Rails 스위트에 묶는다.
# node 가 없으면 조용히 통과하지 않고 실패한다.
class BudgetExecutionRateScriptTest < ActiveSupport::TestCase
  test "budget_execution_rate 참고선 계산 (node --test)" do
    path = Rails.root.join("test/javascript/budget_execution_rate.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
