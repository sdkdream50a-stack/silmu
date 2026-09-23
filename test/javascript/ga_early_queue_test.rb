# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않으므로 Rails 스위트에 묶는다(tool_analytics_calc_complete_test 와 같은 방식).
class GaEarlyQueueTest < ActiveSupport::TestCase
  test "GA 로드 전 클릭 보존 (node --test)" do
    path = Rails.root.join("test/javascript/ga_early_queue.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
