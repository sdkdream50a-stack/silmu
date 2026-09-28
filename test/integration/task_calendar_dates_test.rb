# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P2 — 업무 할일 달력 날짜 오류.
# ① 재산세(건축물) 납기는 지방세법 §115①1 7/16~7/31인데 7/10으로 표시됐다.
# ② 재산세(토지) 납기는 §115①3 9/16~9/30인데 9/15로 표시됐다.
# ③ 고용·산재보험 보수총액신고는 매년 3/15인데 3/25로 표시됐다.
# ④ 건강보험 보수총액 신고는 매년 3/10인데 2월 15일로(달 자체가 틀림) 표시됐다.
# ⑤ 등록면허세(면허분) 납기는 지방세법 §35② 1/16~1/31인데 4/25로(달 자체가 틀림) 표시됐다.
#
# 화면은 원본 날짜가 주말·공휴일이면 직전 평일로 당겨 표시한다(months_tasks_raw → months_tasks
# 변환, prev_workday). 이 파일의 공휴일표는 2026년 전용이라(감사에서 이미 별도 결함으로 기록)
# year를 2026으로 고정해 그 변환 결과까지 결정적으로 검증한다.
class TaskCalendarDatesTest < ActionDispatch::IntegrationTest
  def task_push(month:, day:, cat:, title:)
    /allTasks\.push\(\{\s*month:\s*#{month},\s*day:\s*#{day},\s*cat:\s*"#{Regexp.escape(cat)}",\s*title:\s*"#{Regexp.escape(title)}"\s*\}\)/
  end

  test "재산세(건축물)는 7/31로 표시된다(2026-07-31은 금요일이라 보정 없음)" do
    travel_to Date.new(2026, 1, 1) do
      get "/tools/task-calendar"
      assert_response :success
      assert_match task_push(month: 7, day: 31, cat: "세무", title: "재산세 납부(건축물)"), response.body
    end
  end

  test "재산세(토지)는 9/30으로 표시된다(2026-09-30은 수요일이라 보정 없음)" do
    travel_to Date.new(2026, 1, 1) do
      get "/tools/task-calendar"
      assert_match task_push(month: 9, day: 30, cat: "세무", title: "재산세 납부(토지)"), response.body
    end
  end

  test "고용·산재보험 보수총액신고는 3/15 기준(2026-03-15는 일요일이라 직전 평일 3/13 금요일로 보정)" do
    travel_to Date.new(2026, 1, 1) do
      get "/tools/task-calendar"
      assert_match task_push(month: 3, day: 13, cat: "보험", title: "고용·산재보험 보수총액 신고"), response.body
    end
  end

  test "건강보험 보수총액 신고는 3월 10일로 표시된다(2026-03-10은 화요일이라 보정 없음, 2월이 아니다)" do
    travel_to Date.new(2026, 1, 1) do
      get "/tools/task-calendar"
      assert_match task_push(month: 3, day: 10, cat: "보험", title: "건강보험 정산(보수총액 신고)"), response.body
    end
  end

  test "등록면허세(면허분)는 1월 31일 기준(2026-01-31은 토요일이라 직전 평일 1/30 금요일로 보정, 4월이 아니다)" do
    travel_to Date.new(2026, 1, 1) do
      get "/tools/task-calendar"
      assert_match task_push(month: 1, day: 30, cat: "세무", title: "지방세 납부(등록면허세·면허분)"), response.body
      assert_no_match(/title:\s*"지방세 납부\(면허세 등\)"/, response.body)
    end
  end
end
