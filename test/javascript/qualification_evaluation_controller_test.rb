# frozen_string_literal: true

require "test_helper"
require "open3"

# CI(bin/rails test)는 node:test 파일을 돌리지 않는다 — 적격심사 화면 컨트롤러 회귀(17건)를 Rails 스위트에 묶는다.
# node 가 없으면 조용히 통과하지 않고 실패한다.
class QualificationEvaluationControllerScriptTest < ActiveSupport::TestCase
  test "qualification evaluation controller (node --test)" do
    path = Rails.root.join("test/javascript/qualification_evaluation_controller.test.mjs").to_s
    out, status = Open3.capture2e("node", "--test", path)
    assert status.success?, out
  end
end
