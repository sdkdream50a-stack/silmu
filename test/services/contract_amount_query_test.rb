# frozen_string_literal: true

require "test_helper"

# 검색 금액+유형 인식 회귀 (2026-09-17 업무흐름 감사 13 W-02).
class ContractAmountQueryTest < ActiveSupport::TestCase
  def parse(q) = SearchQueryParser.contract_amount_query(q)

  test "NORMAL: 만원 단위 물품 금액" do
    assert_equal({ category: "goods", price: 15_000_000 }, parse("물품 1500만원"))
    assert_equal({ category: "service", price: 20_000_000 }, parse("용역 2천만원 수의계약"))
  end

  test "EDGE: 억·천 복합 표기와 콤마 원화 표기" do
    assert_equal 150_000_000, parse("1억5천만원 공사")[:price]
    assert_equal 35_000_000, parse("3천500만원 물품")[:price]
    assert_equal 15_000_000, parse("물품 15,000,000원")[:price]
    assert_equal 250_000_000, parse("공사 2.5억")[:price]
  end

  test "LOWER_BOUND: 유형어가 없거나 금액 단위가 없으면 판정하지 않는다" do
    assert_nil parse("수의계약 1500만원")
    assert_nil parse("2026년 공사")
    assert_nil parse("물품 구매")
    assert_nil parse("물품 0원")
  end

  test "UPPER_BOUND: 유형어가 둘이면 어느 쪽인지 모르므로 판정하지 않는다" do
    assert_nil parse("공사 용역 1억")
  end

  test "EXCEPTION: 빈 질의" do
    assert_nil parse(nil)
    assert_nil parse("")
  end
end
