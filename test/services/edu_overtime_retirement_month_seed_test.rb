# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P2 — "시간외수당 퇴직월 특례" 토픽(edu-overtime-retirement-month, org_type=school).
# 교원(국가직)만 맞는 근거(공무원수당규정 §15·별표12·인사혁신처 지침)를 학교 전체(교육행정직 포함)
# 대상으로 인용했다 — 교육행정직(지방직)은 지방공무원 수당 등에 관한 규정 §15·별표11·
# 행정안전부장관 지침이 근거라 대상 분기 안내를 추가한다.
class EduOvertimeRetirementMonthSeedTest < ActiveSupport::TestCase
  SEED = Rails.root.join("db/seeds/edu_overtime_retirement_month.rb")

  def run_seed
    capture_io { load SEED }
    Topic.find_by!(slug: "edu-overtime-retirement-month")
  end

  test "교원과 교육행정직의 근거 조문이 다르다는 안내가 들어간다" do
    topic = run_seed
    assert_includes topic.law_content, "지방공무원 신분인 교육행정직"
    assert_includes topic.law_content, "별표11"
    assert_includes topic.law_content, "행정안전부장관"
    assert_includes topic.summary, "지방공무원 수당 등에 관한 규정"
  end

  test "교원 대상 국가 규정 인용은 그대로 유지된다" do
    topic = run_seed
    assert_includes topic.law_content, "공무원수당 등에 관한 규정"
    assert_includes topic.rule_content, "인사혁신처"
  end
end
