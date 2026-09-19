# frozen_string_literal: true

require "test_helper"

class ReviewLab::FieldExtractorTest < ActiveSupport::TestCase
  FE = ReviewLab::FieldExtractor

  def doc(*blocks) = ReviewLab::TextExtractor.call(bytes: ReviewLab::FixtureBuilder.docx(blocks), role: "notice", label: "공고문")
  def fields(*blocks) = FE.extract(doc(*blocks), FE::PACKAGE_FIELDS)

  test "금액 표기 여러 형태를 원 단위로 읽는다" do
    assert_equal 45_000_000, FE.parse_amount("45,000,000원 (부가세 별도)")
    assert_equal 45_000_000, FE.parse_amount("금 45,000,000원")
    assert_equal 45_000_000, FE.parse_amount("4,500만원")
    assert_equal 120_000_000, FE.parse_amount("1억 2,000만원")
    assert_equal 3_000, FE.parse_amount("3천원")
  end

  test "한글 수사 금액은 틀리게 읽지 않고 모른다(nil)" do
    assert_nil FE.parse_amount("금사천오백만원")
    assert_nil FE.parse_amount("별도 협의")
  end

  test "날짜·일시·기간" do
    assert_equal Date.new(2026, 10, 5), FE.parse_date("2026. 10. 5.(월)")
    assert_equal Date.new(2026, 10, 5), FE.parse_date("2026년 10월 5일")
    assert_equal({ date: Date.new(2026, 10, 10), time: "18:00" }, FE.parse_datetime("2026. 10. 10.(토) 18:00"))
    assert_equal({ date: Date.new(2026, 10, 10), time: nil }, FE.parse_datetime("2026-10-10"), "시각이 없으면 00:00 으로 채우지 않는다")
    assert_equal({ days: 30, base: "계약일" }, FE.parse_days("계약일로부터 30일"))
    assert_nil FE.parse_date("2026. 13. 40.")
  end

  test "라벨은 항목 머리일 때만 — 설명문 속 낱말은 값으로 읽지 않는다" do
    f = fields("추정가격이 2천만원 이하인 경우 1인 견적이 가능합니다.", "1. 추정가격: 45,000,000원")
    assert_equal [ 45_000_000 ], f[:estimated_price].map(&:value)
  end

  test "텍스트형은 구분자가 있어야 한다 — «계약기간 중 …» 문장을 계약방법 값으로 오인하지 않는다" do
    f = fields("계약방법 변경은 협의한다", "계약방법: 제한경쟁입찰")
    assert_equal [ "제한경쟁입찰" ], f[:contract_method].map(&:value)
  end

  test "표 칸 라벨이면 같은 행의 다음 칸이 값이다" do
    f = fields([ "수량", "", "12대" ])
    assert_equal 12, f[:quantity].first.value[:qty]
  end

  test "숫자형 라벨을 찾았어도 값이 해석되지 않으면 채택하지 않는다(UNKNOWN)" do
    f = fields("추정가격: 별도 공지")
    assert_empty f[:estimated_price]
  end
end
