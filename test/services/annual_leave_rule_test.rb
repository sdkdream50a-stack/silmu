require "test_helper"

# 연가일수 — 국가공무원 복무규정 §15①(개정 2024.7.2)·§17② 회귀 (2026-09-17 전수감사 P0).
# 표: 1년 미만 11 · 1~3년 15 · 3~4년 16 · 4~5년 17 · 5~6년 20 · 6년 이상 21.
# 임용 연도: 11일 × 근무월수 ÷ 12, 15일 이상 = 1개월, 반올림.
class AnnualLeaveRuleTest < ActiveSupport::TestCase
  def granted(hire, year = 2026)
    PdfExportService.annual_leave_data(hire_date: hire, ref_year: year, used_leave: 0)[:granted]
  end

  test "NORMAL: service table matches the 2024-07-02 amendment" do
    assert_equal 11, granted("2025-06-01")   # 7개월
    assert_equal 15, granted("2024-01-01")   # 2년
    assert_equal 16, granted("2023-01-01")   # 3년
    assert_equal 17, granted("2022-01-01")   # 4년
    assert_equal 20, granted("2021-01-01")   # 5년
    assert_equal 21, granted("2010-01-01")
  end

  test "LOWER_BOUND: hired on January 1st of the reference year gets 11 days, not 0" do
    assert_equal 11, granted("2026-01-01")
  end

  test "EDGE: mid-year hire is prorated by months worked with the 15-day rule" do
    assert_equal 9, granted("2026-03-02")    # 9개월 30일 → 10개월 → 9.17 → 9
    assert_equal 6, granted("2026-07-01")    # 6개월 → 5.5 → 6
    assert_equal 1, granted("2026-12-17")    # 15일 → 1개월 → 0.92 → 1
    assert_equal 0, granted("2026-12-18")    # 14일 → 0개월
  end

  test "UPPER_BOUND: the 3-year boundary moves from 15 to 16 days" do
    assert_equal 15, granted("2023-01-02")   # 2년 11개월
    assert_equal 16, granted("2023-01-01")   # 3년
  end

  test "EXCEPTION: a hire date after the reference year gives no leave" do
    assert_equal 0, granted("2027-03-01")
  end
end
