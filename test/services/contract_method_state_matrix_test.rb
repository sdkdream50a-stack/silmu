# frozen_string_literal: true

require "test_helper"

# 전수감사 G-51 — 결과 상태별로 요약·근거·서류·경고·팁이 서로 모순되지 않는다.
# 법적 결론(어느 조합이 수의계약인지)은 판정 규칙집이 소유한다. 여기서는 단언하지 않고
# 같은 응답 안의 판정 객체와 부가 안내가 일치하는지만 본다.
class ContractMethodStateMatrixTest < ActiveSupport::TestCase
  AGENCIES = [ nil, "LOCAL_GOVERNMENT", "EDUCATION_OFFICE" ].freeze
  COUNTERPARTIES = [ nil, "UNKNOWN", "GENERAL", "WOMEN", "DISABLED", "SOCIAL_ENTERPRISE", "SMALL_ENTERPRISE" ].freeze
  PRICES = [ 1_500_000, 15_000_000, 30_000_000, 50_000_000, 90_000_000, 150_000_000 ].freeze
  TYPES = %w[goods service construction].freeze

  def matrix
    @matrix ||= TYPES.product(PRICES, AGENCIES, COUNTERPARTIES).filter_map do |type, price, agency, cp|
      r = ContractMethodService.determine(contract_type: type, estimated_price: price, agency_scope: agency, counterparty_type: cp)
      r if r[:success]
    end
  end

  def category(r)
    state = r[:decision][:state]
    return :competitive if state == "COMPETITIVE_PROCEDURE_REQUIRED"
    return :needs_review unless ContractMethodService::CONCLUSIVE_STATES.include?(state)

    r[:decision].dig(:quotation, :requirement) == "SINGLE_ALLOWED" ? :single_quote : :two_quote
  end

  def private_contract_text?(r)
    r[:result][:documents].any? { |d| d.include?("수의계약") || d.include?("견적") } ||
      r[:warnings].any? { |w| (w[:title].include?("수의계약") && !w[:title].include?("유찰")) || w[:title].include?("전자견적") } ||
      r[:tips].any? { |t| t.include?("수의계약") && !t.include?("분할계약") && !t.include?("유찰") }
  end

  test "NORMAL (양성대조): 행렬이 네 범주를 모두 만든다" do
    cats = matrix.map { |r| category(r) }.tally
    %i[competitive single_quote two_quote needs_review].each { |c| assert_operator cats.fetch(c, 0), :>, 0, "범주 없음: #{c} #{cats}" }
  end

  test "EDGE: 확인 필요(판정 전) 결과에는 수의계약 서류·경고·팁·하한율이 없다" do
    matrix.select { |r| category(r) == :needs_review }.each do |r|
      assert_equal "확인 필요", r[:result][:method]
      assert_empty r[:result][:documents], r[:decision][:input].inspect
      assert_empty r[:tips]
      assert_nil r[:lowest_bid_rate]
      assert_nil r[:result][:note]
      assert_equal [ ContractMethodService::UNDETERMINED_WARNING ], r[:warnings]
    end
  end

  test "LOWER_BOUND: 1인 견적 허용 판정에는 «견적서(2인이상)»·견적비교표가 없다" do
    matrix.select { |r| category(r) == :single_quote }.each do |r|
      docs = r[:result][:documents]
      refute_includes docs, "견적서(2인이상)", r[:decision][:input].inspect
      refute_includes docs, "견적비교표"
    end
  end

  test "UPPER_BOUND: 2인 이상 견적 판정에는 1인 견적 서류 문구가 없고 경쟁입찰 판정에는 수의계약 안내가 없다" do
    matrix.select { |r| category(r) == :two_quote }.each do |r|
      refute_includes r[:result][:documents], "견적서(1인 견적 가능)", r[:decision][:input].inspect
      refute_includes r[:result][:documents], "견적서", "견적 인원이 빠진 서류명: #{r[:decision][:input].inspect}"
    end
    matrix.select { |r| category(r) == :competitive }.each do |r|
      assert_equal "입찰", r[:result][:method]
      refute private_contract_text?(r), r[:decision][:input].inspect
    end
  end

  test "EXCEPTION: 요약용 기관·상대방 라벨은 입력이 있을 때만, 규칙집 라벨 그대로 나온다" do
    r = ContractMethodService.determine(contract_type: "goods", estimated_price: 30_000_000,
                                        agency_scope: "EDUCATION_OFFICE", counterparty_type: "GENERAL")
    rules = ContractDecision::RuleSet.current
    assert_equal rules.agency_scope("EDUCATION_OFFICE")["label"], r[:result][:agency_scope_label]
    assert_equal rules.counterparty("GENERAL")["label"], r[:result][:counterparty_label]
    blank = ContractMethodService.determine(contract_type: "goods", estimated_price: 30_000_000)
    assert_nil blank[:result][:agency_scope_label]
  end
end
