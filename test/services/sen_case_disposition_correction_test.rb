# frozen_string_literal: true

require "test_helper"

# 서울시교육청 공개문 처분 정정 회귀 (2026-09-17 G-13).
class SenCaseDispositionCorrectionTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917170000_sen_case_disposition_correction.rb")

  setup do
    @case = AuditCase.create!(category: "계약", severity: "보통", issue: "시설공사관리", published: true, sector: :edu,
      title: "시설공사관리 및 계약업무 집행 소홀", slug: "sen-2025-school-y-facility-multi-violation",
      detail: "### 위반 3: 분할수의\n\n## 처분\n학교법인 이사장 → 관련자 \"주의\" 처분.\n")
  end

  test "NORMAL: disposition follows the disclosure (경고)" do
    capture_io { load MIGRATION }
    assert_includes @case.reload.detail, "관련자 \"경고\" 처분."
    assert_not_includes @case.detail, "\"주의\""
  end

  test "EDGE: surrounding text is untouched" do
    capture_io { load MIGRATION }
    assert @case.reload.detail.start_with?("### 위반 3: 분할수의")
  end

  test "LOWER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "UPPER_BOUND: only the target case is modified" do
    other = AuditCase.create!(category: "계약", severity: "보통", issue: "x", published: true, sector: :edu,
      title: "다른 사례", slug: "sen-2025-school-s-disaster-prevention", detail: "## 처분\n학교법인 이사장 → 관련자 \"주의\" 처분.\n")
    capture_io { load MIGRATION }
    assert_includes other.reload.detail, "\"주의\""
  end

  test "EXCEPTION: unexpected text aborts" do
    @case.update_columns(detail: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
  end
end
