# frozen_string_literal: true

require "test_helper"

# 하자담보책임기간 서술 원문 대조 회귀 (2026-09-17 전수감사 exam B7).
# 원문: 건설산업기본법 시행령 [별표 4](개정 2021. 8. 3.), 국가계약법 시행규칙 제70조①, 같은 법 시행령 제60조①·제62조②.
class ExamDefectLiabilityPeriodTest < ActiveSupport::TestCase
  def curriculum = Rails.root.join("app/models/exam_curriculum/subject3.rb").read
  def practical = ExamPracticalQuestions::QUESTIONS.map { |q| q[:model_answer].to_s }.join("\n")

  test "NORMAL: 10년은 대형공공성 건축물 기둥·내력벽이지 건물 전체가 아니다" do
    assert_not_includes curriculum, "건물 **10년**"
    assert_includes curriculum, "대형공공성 건축물 기둥·내력벽 **10년**"
  end

  test "EDGE: 별표 4에 없는 «철근콘크리트 5년»·«가설공사 1년» 예시를 싣지 않는다" do
    assert_not_includes curriculum, "철근콘크리트 **5년**"
    assert_not_includes ExamQuestions::QUESTIONS.map { |q| q[:explanation].to_s }.join, "가설공사 1년"
  end

  test "LOWER_BOUND: 교량 10년은 장대교량(50m·500m 기준)에 한정한다" do
    assert_includes practical, "장대교량(기둥 사이 50m 이상 또는 길이 500m 이상)"
    assert_not_includes practical, "교량·터널 등 철근콘크리트구조부"
  end

  test "UPPER_BOUND: 위임 경로는 시행령 제60조① → 시행규칙 제70조① → 별표 4" do
    assert_includes practical, "시행규칙 제70조①1호"
    assert_not_includes practical, "물품 제조·구매: 1년"
  end

  test "EXCEPTION: 하자보수보증금 납부 시기는 준공검사 후 대가 지급 전(제62조②)" do
    assert_includes practical, "준공검사 후 공사 대가를 지급하기 전까지(시행령 제62조②)"
  end
end
