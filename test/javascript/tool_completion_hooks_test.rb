# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — tool_analytics_calc_complete_test.rb 와
# 같은 이유로 calc_complete 신고 훅 존재 회귀만은 Rails 스위트에 묶는다.
class ToolCompletionHooksTest < ActiveSupport::TestCase
  test "17개 신규 계측 도구의 calc_complete 훅 존재 회귀 (node --test)" do
    path = Rails.root.join("test/javascript/tool_completion_hooks.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
