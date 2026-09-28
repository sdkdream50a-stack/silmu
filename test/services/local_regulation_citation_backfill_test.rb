# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P3 — 병가·육아휴직수당 토픽에 지방 조문 병기.
# 두 토픽 모두 수치·본문은 이미 정확했지만(VALID_BY_REFERENCE), 지방공무원 신분
# 독자가 확인할 구체 조문(지방공무원 복무규정 §7조의5·지방공무원 수당 등에 관한
# 규정 제11조의2)이 빠져 있었다.
class LocalRegulationCitationBackfillTest < ActiveSupport::TestCase
  def run_seed(path)
    capture_io { load Rails.root.join(path) }
  end

  test "병가 토픽에 지방공무원 복무규정 제7조의5가 병기된다" do
    run_seed("db/seeds/topics/sick_leave.rb")
    topic = Topic.find_by!(slug: "sick-leave")
    assert_includes topic.law_content, "지방공무원 복무규정"
    assert_includes topic.law_content, "제7조의5"
  end

  test "육아휴직수당 토픽에 지방공무원 수당 등에 관한 규정 제11조의2가 병기된다" do
    run_seed("db/seeds/edu_childcare_allowance_cap.rb")
    topic = Topic.find_by!(slug: "edu-childcare-allowance-cap")
    assert_includes topic.law_content, "지방공무원 수당 등에 관한 규정"
    assert_includes topic.law_content, "제11조의2"
    assert_includes topic.summary, "지방공무원 수당 등에 관한 규정"
  end
end
