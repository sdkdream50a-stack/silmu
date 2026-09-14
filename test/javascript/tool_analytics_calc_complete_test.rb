# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다. 계측 무음 결함이 같은 repo 에서 두 번 났으므로
# calc_complete 회귀만은 Rails 스위트에 묶는다. node 가 없으면 조용히 통과하지 않고 실패한다.
class ToolAnalyticsCalcCompleteTest < ActiveSupport::TestCase
  test "tool_analytics / source_attribution 스크립트 동작 (node --test)" do
    path = Rails.root.join("test/javascript/tool_analytics_calc_complete.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
