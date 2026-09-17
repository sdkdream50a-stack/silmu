require "test_helper"

# 낙찰하한율 안내 회귀 (2026-09-17 전수감사 P0).
# 종전: 공사 300억 미만 전 구간 89.745% 단일값 · 300억 이상에도 하한율 · 물품·용역 출처 없는 88/90%.
# 현행 참고: 10억 미만 89.745 / 10~50억 88.745 / 50~100억 87.495 / 100~300억 81.995,
# 300억 이상은 종합평가낙찰제(시행령 §42의3), 물품·용역은 공고문 확인.
class LowestBidRateTest < ActiveSupport::TestCase
  def rate_for(type, price)
    ContractMethodService.determine(contract_type: type, estimated_price: price)[:lowest_bid_rate]
  end

  test "NORMAL: 10억~50억 공사는 88.745% 참고값" do
    assert_equal "88.745%", rate_for("construction_general", 2_000_000_000)[:rate]
  end

  test "LOWER_BOUND: 10억원 정각은 10억 이상 구간" do
    assert_equal "88.745%", rate_for("construction_general", 1_000_000_000)[:rate]
    assert_equal "89.745%", rate_for("construction_general", 999_999_999)[:rate]
  end

  test "EDGE: 100억~300억 공사는 81.995%" do
    assert_equal "81.995%", rate_for("construction_general", 20_000_000_000)[:rate]
  end

  test "UPPER_BOUND: 300억 이상 공사는 적격심사 하한율 숫자를 내지 않는다" do
    result = rate_for("construction_general", 30_000_000_000)
    assert_equal "공고문 확인", result[:rate]
    assert_includes result[:detail], "종합평가낙찰제"
  end

  test "EXCEPTION: 물품·용역 입찰에는 출처 없는 단일 하한율을 주지 않는다" do
    result = rate_for("goods", 300_000_000)
    assert_equal "공고문 확인", result[:rate]
    warnings = ContractMethodService.determine(contract_type: "service", estimated_price: 300_000_000)[:warnings]
    floor = warnings.find { |w| w[:title].include?("낙찰하한율") }
    assert floor, "낙찰하한율 안내가 사라지면 안 된다"
    assert_no_match(/\d+\.\d+%/, floor[:title])
    assert_not_includes floor[:message], "88.0%"
  end
end
