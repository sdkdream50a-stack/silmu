# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — 성과상여금 계산기 회귀를 Rails 스위트에 묶는다.
class PerformanceBonusCalculatorScriptTest < ActionDispatch::IntegrationTest
  test "performance_bonus_calculator 스크립트 계산 (node --test)" do
    path = Rails.root.join("test/javascript/performance_bonus_calculator.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
