# frozen_string_literal: true

require "test_helper"

# 시험 콘텐츠 계약 사실 회귀 (2026-09-17 04b 감사).
# 원문: 재정경제부 계약예규 「적격심사기준」(2026.1.30. 공고분 +2%p) · 행안부 예규 「낙찰자 결정기준」 ·
# 국가계약법 시행령 §37①(입찰보증금 = 입찰금액 5%) · §50①⑥(계약보증금 면제 = 계약금액 5천만원 이하) · §55①(검사 14일).
class ExamContractFactsTest < ActiveSupport::TestCase
  SOURCES = %w[
    app/models/exam_questions.rb app/models/exam_keyword_details.rb app/models/exam_practical_questions.rb
    app/models/exam_curriculum/subject2.rb app/models/exam_curriculum/subject3.rb app/views/exam/strategy/index.html.erb
  ].freeze

  def corpus = SOURCES.map { |p| Rails.root.join(p).read }.join("\n")

  test "NORMAL: no single-value '2억원 이상 공사 89.745%' statement remains" do
    text = corpus.gsub("**", "")
    assert_no_match(/2억원 이상 공사[^\n"]{0,20}89\.745/, text)
    assert_no_match(/2억원 이상 공사계약에서 적용되는 낙찰하한율/, text)
    assert_includes text, "10억~50억원 88.745%", "양성대조: 구간표가 실제로 들어갔다"
  end

  test "EDGE: question 15 and 657 still point at 89.745% after narrowing to the under-1B band" do
    q15 = ExamQuestions::QUESTIONS.find { |q| q[:id] == 15 }
    q657 = ExamQuestions::QUESTIONS.find { |q| q[:id] == 657 }
    assert_includes q15[:question], "10억원 미만"
    assert_equal "89.745%", q15[:options][q15[:correct]]
    assert_equal "89.745%", q657[:options][q657[:correct]]
  end

  test "LOWER_BOUND: 적격심사 합격선 95점 · 공사 적용 100억원 미만" do
    text = corpus
    assert_not_includes text, "합산점수 88점 이상"
    assert_includes text, "종합평점 95점 이상"
    assert_not_includes text, "**2억원** 이상 **적격심사**"
  end

  test "UPPER_BOUND: 종합심사낙찰제 대상은 100억원 이상" do
    assert_not_includes corpus, "대형 공사(추정가격 300억원 이상)에 대해"
  end

  test "EXCEPTION: 보증금·검사기간 기준 주체가 맞다" do
    text = corpus
    assert_includes text, "입찰금액의 **5%**"
    assert_includes text, "계약금액 5천만원 이하"
    assert_includes text, "이행완료 통지를 받은 날부터 14일 이내"
    assert_not_includes text, "물품 납품일로부터 5일 이내"
  end
end
