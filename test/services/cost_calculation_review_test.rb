# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P1 — 원가계산서 검토 판정 기준.
# · 엔지니어링(설계·감리): 제경비 = 직접인건비의 110~120% (엔지니어링사업대가의 기준 제9조),
#   기술료 = (직접인건비+제경비)의 20~40%, 이윤 포함 (제10조).
# · 학술연구용역: 인건비·경비·일반관리비·이윤 (예정가격 작성기준 제24조·제28조) — 이윤 상한 10% (지방계약법 시행규칙 제8조제2항제4호).
# · 일반용역: 법정 제경비율 없음 — 종전 범위 10~20% 로 110% 를 «부적정» 판정했다.
class CostCalculationReviewTest < ActiveSupport::TestCase
  def review(type, **amounts)
    r = CostCalculationReviewService.review({ service_type: type }.merge(amounts))
    r[:result][:reviews].to_h { |row| [ row[:name], row[:status] ] }.merge("summary" => r[:result][:summary][:status])
  end

  test "일반용역 제경비 110% 를 부적정으로 판정하지 않는다" do
    rows = review("general", direct_labor: 10_000_000, overhead: 11_000_000)
    assert_equal "ok", rows["제경비(간접노무비+기타경비)"]
    assert_not_equal "error", rows["summary"]
  end

  test "설계용역 기술료는 (직접인건비+제경비) 기준 20~40% 로 판정한다" do
    # 직접인건비 1,000만 + 제경비 1,100만 = 2,100만 → 기술료 630만 = 30% (직접경비 500만은 기준에 넣지 않는다)
    rows = review("design", direct_labor: 10_000_000, overhead: 11_000_000, direct_expense: 5_000_000, profit_or_tech: 6_300_000)
    assert_equal "ok", rows["제경비"]
    assert_equal "ok", rows["기술료"]
    assert_nil rows["이윤"]
    # 음성 대조: 45% 는 상한 초과
    assert_equal "error", review("supervision", direct_labor: 10_000_000, overhead: 11_000_000, profit_or_tech: 9_450_000)["기술료"]
  end

  test "학술연구용역은 기술료가 아니라 이윤 10% 상한으로 판정한다" do
    rows = review("research", direct_labor: 10_000_000, direct_expense: 2_000_000, general_admin: 600_000, profit_or_tech: 1_260_000)
    assert_equal "ok", rows["이윤"]
    assert_nil rows["기술료"]
    assert_equal "error", review("research", direct_labor: 10_000_000, profit_or_tech: 1_500_000)["이윤"]
    assert_equal "warning", review("research", direct_labor: 10_000_000, overhead: 5_000_000)["제경비"]
  end
end
