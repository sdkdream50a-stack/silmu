# frozen_string_literal: true

require "test_helper"

# 2026-09-28 전 도구 감사 P0 — 지방계약법 시행령 §35(공고 시기)·§67①(대가 지급) 기간 계산.
class LegalPeriodBoundariesTest < ActiveSupport::TestCase
  def announce(date, amount: 500_000_000, urgent: false)
    LegalPeriodService.calculate(period_type: "announcement", estimated_amount: amount, announcement_date: date, urgent: urgent)[:result]
  end

  def pay(type, date)
    LegalPeriodService.calculate(period_type: "payment", payment_type: type, inspection_date: date)[:result]
  end

  test "§35 마감 전날부터 7일 전 — 2026-10-01(목) 공고의 가장 이른 마감은 10-09 가 아니라 한글날 뒤 10-12(월)" do
    # 공고일 + 7 + 1 = 10-09(금·한글날) → 다음 근무일 10-12
    assert_equal "2026-10-12", announce("2026-10-01")[:end_date]
  end

  test "공휴일이 끼지 않으면 공고일 + 8일" do
    assert_equal "2026-11-10", announce("2026-11-02")[:end_date] # 11-02(월) + 8 = 11-10(화)
  end

  test "긴급 5일도 같은 문언 — 공고일 + 6일" do
    assert_equal "2026-11-09", announce("2026-11-03", urgent: true)[:end_date] # 11-03(화) + 6 = 11-09(월)
  end

  test "지방 대가 지급 5일은 토·공휴일 제외 — 10-01(목) 청구 → 10-12(월)" do
    # 10-02(금) · [10-03 토 개천절, 10-04 일, 10-05 대체공휴일] · 10-06 · 10-07 · 10-08 · [10-09 한글날] · 10-12
    assert_equal "2026-10-12", pay("local", "2026-10-01")[:deadline]
  end

  test "음성 대조 — 국가 대가 지급은 §58① 에 제외 문구가 없어 달력일(주말이면 월요일)" do
    assert_equal "2026-10-06", pay("national", "2026-10-01")[:deadline] # 10-06(화)
  end

  test "2026 년 밖은 공휴일 미반영을 결과에 적는다" do
    assert_includes announce("2027-03-02")[:note], "공휴일은 반영하지 않았습니다"
    assert_not_includes announce("2026-11-02")[:note], "공휴일은 반영하지 않았습니다"
  end
end
