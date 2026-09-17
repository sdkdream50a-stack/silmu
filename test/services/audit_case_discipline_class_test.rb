# frozen_string_literal: true

require "test_helper"

# 감봉·견책은 경징계다 — 「공무원 징계령」·「지방공무원 징계 및 소청 규정」 제1조의3 (2026-09-17 전수감사 G-13).
class AuditCaseDisciplineClassTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918100000_auditcase_discipline_class_errors.rb")

  def seed(slug, field, text)
    AuditCase.create!(title: slug, slug: slug, issue: "○○", category: "contract", field => text)
  end

  test "NORMAL: 감봉 (중징계) → (경징계)" do
    ac = seed("budget-misuse", :detail, "- 건설과장: 감봉 1개월 (중징계)\n- 부구청장: 견책")
    capture_io { load MIGRATION }
    assert_includes ac.reload.detail, "감봉 1개월 (경징계)"
    assert_not_includes ac.detail, "중징계"
  end

  test "EDGE: 근거 없는 징계부가금 1/4 줄은 삭제한다" do
    ac = seed("performance-guarantee-waiver-loss", :detail, "**L씨:**\n- 감봉 3개월 (중징계)\n- 징계부가금 부과 (감면액 4,000만원의 1/4, 1,000만원)\n\n**업체**")
    capture_io { load MIGRATION }
    assert_not_includes ac.reload.detail, "징계부가금"
    assert_includes ac.detail, "- 감봉 3개월 (경징계)\n\n**업체**"
  end

  test "LOWER_BOUND: 이미 정정된 행은 두 번째 실행에서 바꾸지 않는다" do
    seed("contract-wrong-party", :detail, "A씨는 감봉 처분(중징계)을 받았습니다.")
    out1, = capture_io { load MIGRATION }
    out2, = capture_io { load MIGRATION }
    assert_match(/changes=1/, out1)
    assert_match(/changes=0/, out2)
  end

  test "UPPER_BOUND: 교훈 절의 일반 서술도 중징계·경징계 구분을 바로잡는다" do
    ac = seed("private-contract-split", :lesson, "계약 취소와 함께 담당자는 감봉 이상의 중징계를 받으며, 업체도")
    ac.update_columns(action_taken: "계약 취소, 관련자 중징계(감봉), 재교육")
    capture_io { load MIGRATION }
    assert_includes ac.reload.lesson, "견책·감봉 등 경징계 또는 정직 이상 중징계"
    assert_includes ac.action_taken, "관련자 경징계(감봉)"
  end

  test "EXCEPTION: 원문 지문이 달라졌으면 전체 롤백한다" do
    ok = seed("budget-misuse", :detail, "- 건설과장: 감봉 1개월 (중징계)")
    seed("contract-wrong-party", :detail, "A씨는 정직 처분을 받았습니다.")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes ok.reload.detail, "(중징계)"
  end
end
