# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — 연금 계산기 회귀를 Rails 스위트에 묶는다.
class PensionCalculatorScriptTest < ActionDispatch::IntegrationTest
  test "pension_calculator 스크립트 계산 (node --test)" do
    path = Rails.root.join("test/javascript/pension_calculator.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end

  test "퇴직 연도 선택이 렌더되고 1.9% 일괄 안내가 없다" do
    get "/tools/pension-calculator"
    assert_response :success
    assert_includes response.body, 'id="retire-year"'
    assert_includes response.body, "2035년 이후"
    assert_not_includes response.body, "2015년 이전 임용자: 1.9%"
  end
end
