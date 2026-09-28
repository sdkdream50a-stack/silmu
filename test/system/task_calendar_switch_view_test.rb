# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P2 — 업무 할일 달력.
# "주간 뷰 →" 버튼의 onclick="switchView('upcoming')"이 IIFE 밖(전역 스코프)에서
# 실행되는데 switchView는 IIFE 안에서만 선언돼 있어 ReferenceError로 죽었다.
# (버튼 자체는 "오늘 마감 업무 없음 + 다가오는 업무 있음"일 때만 렌더돼 날짜에 따라
# 나타나지 않을 수 있어, 실행 컨텍스트를 직접 호출해 근본 원인을 검증한다.)
class TaskCalendarSwitchViewTest < ApplicationSystemTestCase
  test "전역 스코프에서 switchView를 호출해도 ReferenceError 없이 뷰가 전환된다" do
    visit "/tools/task-calendar"

    # 인라인 onclick과 동일하게 전역 스코프에서 호출한다 — 고치기 전에는
    # "switchView is not defined"로 여기서 바로 예외가 난다.
    page.execute_script("switchView('upcoming')")

    assert_no_selector "#view-upcoming.hidden", visible: :all
    assert_selector "#view-today.hidden", visible: :all
  end
end
