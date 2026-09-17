# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — 시간외수당 계산식 회귀를 Rails 스위트에 묶는다.
# node 가 없으면 조용히 통과하지 않고 실패한다.
class OvertimeCalculatorScriptTest < ActiveSupport::TestCase
  test "overtime_calculator 스크립트 계산 (node --test)" do
    path = Rails.root.join("test/javascript/overtime_calculator.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
