# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — 4대보험 엔진 회귀(76건, 10원 절사 포함)를 Rails 스위트에 묶는다.
# node 가 없으면 조용히 통과하지 않고 실패한다.
class InsuranceEngineScriptTest < ActiveSupport::TestCase
  test "insurance engine (node --test)" do
    path = Rails.root.join("test/javascript/insurance_engine.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
