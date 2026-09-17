# frozen_string_literal: true

require "test_helper"

# 시험 콘텐츠 수의계약 사실 회귀 (2026-09-17 04b D6·D9, 원문: 국가계약법 시행령 제26조 제1항·제30조 제1항).
class ExamPrivateContractFactsTest < ActiveSupport::TestCase
  def q821 = ExamQuestions::QUESTIONS.find { |q| q[:id] == 821 }
  def practical20 = ExamPracticalQuestions::QUESTIONS.find { |q| q[:id] == 20 }

  test "NORMAL: 2인 견적은 1인 견적 예외가 아닌 수의계약 전반의 원칙" do
    assert_includes q821[:options][q821[:correct]], "2,000만원을 초과하는 수의계약"
    assert_includes q821[:explanation], "제30조 제1항"
  end

  test "EDGE: 5천만원 초과 원칙 경쟁 서술이 없다" do
    assert_not_includes q821[:explanation], "5,000만원을 초과하는 경우에는 원칙적으로 경쟁입찰"
    assert_includes q821[:explanation], "1억원 이하"
  end

  test "LOWER_BOUND: 오답 보기 3개는 그대로" do
    assert_equal 4, q821[:options].size
    assert_includes q821[:options], "금액과 관계없이 체결되는 모든 수의계약에 일률적으로 적용되는 경우"
  end

  test "UPPER_BOUND: 우수조달물품 수의계약에 5천만원 한도가 없다" do
    assert_not_includes practical20[:model_answer], "5천만원 이하 수의계약"
    assert_includes practical20[:model_answer], "제26조 제1항 제3호 바목"
  end

  test "EXCEPTION: correct index still points at an existing option" do
    assert q821[:options][q821[:correct]].present?
  end
end
