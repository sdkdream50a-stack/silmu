# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — tool_analytics_calc_complete_test.rb 와 같은 이유로
# tool_complete 1회 규칙 회귀를 Rails 스위트에 묶는다. node 가 없으면 조용히 통과하지 않고 실패한다.
class ToolCompleteTest < ActiveSupport::TestCase
  test "tool_complete 1회 규칙 (node --test)" do
    path = Rails.root.join("test/javascript/tool_complete.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
