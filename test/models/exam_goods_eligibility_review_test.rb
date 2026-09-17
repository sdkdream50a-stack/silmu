# frozen_string_literal: true

require "test_helper"

# 물품 적격심사 적용 금액 서술 원문 대조 회귀 (2026-09-17 전수감사 exam D11).
# 원문: 조달청 물품구매적격심사 세부기준(조달청지침 제3373호, 2026. 5. 26. 시행) 제2조·제4조①·제6조.
class ExamGoodsEligibilityReviewTest < ActiveSupport::TestCase
  def curriculum = Rails.root.join("app/models/exam_curriculum/subject3.rb").read
  def question = ExamQuestions.find_by_id(22)

  test "NORMAL: 별표 1 원칙 적용 기준은 추정가격 10억원 이상 제조입찰" do
    assert_equal "추정가격 10억원 이상", question[:options][question[:correct]]
    assert_includes question[:explanation], "제4조제1항"
  end

  test "EDGE: 5억원은 5개 기관 수요물자 예외로만 설명한다" do
    assert_includes question[:explanation], "5개 기관 수요물자에 한해"
  end

  test "LOWER_BOUND: «2억원 미만 소액 물품» 적용 기준을 어디에도 싣지 않는다" do
    assert_not_includes curriculum, "2억원 미만 소액 물품"
    assert_not_includes question[:explanation], "2억원 미만 소액 물품 구매의 경우"
  end

  test "UPPER_BOUND: «2억원 이상 물품» 적격심사 기준도 싣지 않는다" do
    assert_not_includes curriculum, "추정가격 **2억원** 이상 물품"
  end

  test "EXCEPTION: 보기 수·id 는 유지된다(북마크·오답 id 보존)" do
    assert_equal 4, question[:options].size
    assert_equal 3, question[:subject_id]
  end
end
