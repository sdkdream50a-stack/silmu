# frozen_string_literal: true

require "test_helper"

# 선금 지급 서술 원문 대조 회귀 (2026-09-17 전수감사 exam E3).
# 원문: (계약예규) 정부 입찰ㆍ계약 집행기준 [시행 2026. 8. 25.] 제34조~제38조.
class ExamAdvancePaymentTest < ActiveSupport::TestCase
  def answer = ExamPracticalQuestions::QUESTIONS.find { |q| q[:id] == 16 }
  def model = answer[:model_answer]

  test "NORMAL: 의무 지급 비율은 규모별 30·40·50%" do
    assert_includes model, "공사 100억원 이상 30%·20억~100억원 40%·20억원 미만 50%"
    assert_includes model, "물품 제조·용역 10억원 이상 30%·3억~10억원 40%·3억원 미만 50%"
  end

  test "EDGE: 장기계속계약은 «30% 이내»가 아니라 연차계약금액 기준" do
    assert_not_includes model, "연간 계약금액의 30% 이내"
    assert_includes model, "장기계속계약은 각 연차계약금액 기준(제9항)"
  end

  test "LOWER_BOUND: «20% 이상» 하한 서술을 싣지 않는다" do
    assert_not_includes model, "계약금액의 20% 이상"
  end

  test "UPPER_BOUND: 상한은 100분의 70, «통상»이 아니다" do
    assert_includes model, "100분의 70을 넘지 않는 범위"
    assert_not_includes ExamQuestions.find_by_id(ExamQuestions::QUESTIONS.find { |q| q[:question].include?("선금(先金)") }[:id])[:explanation], "통상 70%"
  end

  test "EXCEPTION: 반환 사유는 원문 목록, 약정이자는 귀책사유일 때만" do
    assert_not_includes model, "계약 이행 포기"
    assert_includes model, "선금지급조건 위배"
    assert_includes model, "귀책사유로 반환하는 경우 약정이자상당액 가산"
    assert_not_includes model, "경비 (전력·용수 등)"
  end
end
