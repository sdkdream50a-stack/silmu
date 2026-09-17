# frozen_string_literal: true

require "test_helper"

# 전수감사 UX P0 TOP#2 — 판정은 "경쟁입찰"인데 근거·경고·서류·팁이 수의계약용으로 나오던 자기모순.
# 법적 값은 단언하지 않는다. 부가 안내가 **같은 응답의 판정 객체**와 맞는지만 본다.
class ContractMethodResultConsistencyTest < ActiveSupport::TestCase
  def determine(price, counterparty)
    ContractMethodService.determine(
      contract_type: "goods", estimated_price: price,
      agency_scope: "LOCAL_GOVERNMENT", counterparty_type: counterparty
    )
  end

  def cited_basis(result)
    result[:decision][:legal_basis].map { |b| "#{b[:short]} #{b[:locator]}" }.join(", ")
  end

  test "경쟁입찰 판정이면 근거·서류·경고·팁이 수의계약용이 아니다 (3천만원 물품·일반 업체)" do
    r = determine(30_000_000, "GENERAL")
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r[:decision][:state]
    assert_equal "입찰", r[:result][:method]

    assert_equal cited_basis(r), r[:result][:basis]
    assert_no_match(/제25조/, r[:result][:basis])
    refute r[:result][:documents].any? { |d| d.include?("수의계약") }, r[:result][:documents].inspect
    assert_includes r[:result][:documents], "입찰공고문"
    refute r[:warnings].any? { |w| w[:title].include?("수의계약 체결 제한") || w[:title].include?("전자견적") }
    refute r[:tips].any? { |t| t.start_with?("수의계약") }, r[:tips].inspect
    assert r[:tips].any? { |t| t.include?("입찰공고") }
    assert_nil r[:result][:note], "입찰 구간의 '1억원 초과' 부제가 3천만원 결과에 붙으면 안 된다"
    assert r[:result][:special_condition].to_s.exclude?("수의")
    assert_not_nil r[:lowest_bid_rate]
  end

  test "수의계약 판정이면 수의계약 안내가 유지된다 (1,500만원 물품·일반 업체)" do
    r = determine(15_000_000, "GENERAL")
    assert_includes %w[POSSIBLE POSSIBLE_WITH_CONDITIONS], r[:decision][:state]
    assert_equal "수의계약", r[:result][:method]
    assert_equal cited_basis(r), r[:result][:basis]
    assert r[:warnings].any? { |w| w[:title].include?("수의계약 체결 제한") }
    refute r[:tips].any? { |t| t.include?("입찰공고") }
    assert_nil r[:lowest_bid_rate]
  end

  test "특례 상대방 판정의 근거는 판정이 인용한 조항과 같다 (5천만원 물품·여성기업)" do
    r = determine(50_000_000, "WOMEN")
    decision_method = r[:decision][:state] == "COMPETITIVE_PROCEDURE_REQUIRED" ? "입찰" : r[:result][:method]
    assert_equal decision_method, r[:result][:method]
    assert_equal cited_basis(r), r[:result][:basis]
    if r[:result][:method] == "입찰"
      refute r[:result][:documents].any? { |d| d.include?("수의계약") }
    else
      refute r[:tips].any? { |t| t.include?("입찰공고") }
    end
  end
end
