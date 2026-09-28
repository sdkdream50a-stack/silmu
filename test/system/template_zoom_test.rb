# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 감사 P3 — 양식 상세(/templates/:id) 확대/축소 버튼이 핸들러 없이 그려져
# 눌러도 "100%" 표시가 그대로였다(dead button, 26쪽 × 2버튼).
class TemplateZoomTest < ApplicationSystemTestCase
  test "확대 버튼을 누르면 표시 비율이 100%보다 커진다" do
    visit "/templates/1"
    find("#template-zoom-in").click
    assert_equal "110%", find("#template-zoom-label").text
  end

  test "축소 버튼을 누르면 표시 비율이 100%보다 작아진다" do
    visit "/templates/1"
    find("#template-zoom-out").click
    assert_equal "90%", find("#template-zoom-label").text
  end
end
