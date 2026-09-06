# frozen_string_literal: true

require "test_helper"

# 견적 요건(§30①)은 수의계약 가능 여부(§25)와 **다른 판단**이고, 각자 다른 금액을 쓴다.
# 이 스위트가 없었을 때 뮤테이션이 두 건 살아남았다 — §30 특례 임계를 5천만에서
# 1억으로 올려도, 조문에 열거되지 않은 소기업·소상공인을 1인 견적 목록에 넣어도
# 아무 테스트도 깨지지 않았다.
class ContractDecision::QuotationRequirementTest < ActiveSupport::TestCase
  Q = ContractDecision::QuotationRequirement

  def call(type:, price:, cp: "GENERAL", ratio: nil)
    Q.call(rules: ContractDecision::RuleSet.current, contract_type: type,
           price: price, counterparty: cp, vulnerable_ratio_met: ratio)
  end

  test "원칙은 2인 이상이다" do
    r = call(type: "goods", price: 30_000_000)
    assert_equal "TWO_OR_MORE", r.requirement
    assert r.legal_basis.any? { |b| b[:locator] == "제30조제1항 본문" }
  end

  test "2천만원 이하는 상대방과 무관하게 1인 견적" do
    assert_equal "SINGLE_ALLOWED", call(type: "goods", price: 20_000_000).requirement
    assert_equal "SINGLE_ALLOWED", call(type: "construction_general", price: 20_000_000).requirement
  end

  test "2천만원 1원을 넘으면 일반업체는 2인 이상" do
    assert_equal "TWO_OR_MORE", call(type: "goods", price: 20_000_001).requirement
  end

  # ── §30①2호가목: 5천만원. §25 의 1억원과 다른 숫자다 ──
  test "여성기업 1인 견적 특례 상한은 5천만원이다" do
    assert_equal "SINGLE_ALLOWED", call(type: "goods", price: 50_000_000, cp: "WOMEN").requirement
    assert_equal "TWO_OR_MORE", call(type: "goods", price: 50_000_001, cp: "WOMEN").requirement,
      "제25조제1항제5호바목의 1억원은 수의계약 가능 범위이지 1인 견적 상한이 아니다"
    assert_equal "TWO_OR_MORE", call(type: "goods", price: 80_000_000, cp: "WOMEN").requirement
  end

  test "청년창업기업·장애인기업도 5천만원까지 1인 견적" do
    %w[YOUTH_STARTUP DISABLED].each do |cp|
      assert_equal "SINGLE_ALLOWED", call(type: "service", price: 45_000_000, cp: cp).requirement
      assert_equal "TWO_OR_MORE", call(type: "service", price: 55_000_000, cp: cp).requirement
    end
  end

  # ── 조문에 열거되지 않은 상대방을 1인 견적 목록에 넣지 않는다 ──
  test "소기업·소상공인은 1인 견적 대상이 아니다" do
    assert_equal "TWO_OR_MORE", call(type: "goods", price: 40_000_000, cp: "SMALL_ENTERPRISE").requirement,
      "소기업·소상공인은 제25조제1항제5호라목으로 1억원까지 수의계약 사유가 되지만, " \
      "제30조제1항제2호 가·나목의 1인 견적 열거에는 없다. 두 조문을 같은 목록으로 보면 안 된다"
  end

  # ── §30①2호나목 단서 ──
  test "사회적기업은 취약계층 고용비율을 충족해야 1인 견적" do
    assert_equal "SINGLE_ALLOWED",
                 call(type: "goods", price: 45_000_000, cp: "SOCIAL_ENTERPRISE", ratio: true).requirement
    assert_equal "TWO_OR_MORE",
                 call(type: "goods", price: 45_000_000, cp: "SOCIAL_ENTERPRISE", ratio: false).requirement
  end

  # ── 시행규칙 §33: 견적서 생략은 200만원 "미만" 물품·용역만 ──
  test "200만원 미만 물품·용역에만 견적서 생략 안내가 붙는다" do
    assert call(type: "goods", price: 1_999_999).notes.any? { |n| n.include?("생략") }
    refute call(type: "goods", price: 2_000_000).notes.any? { |n| n.include?("생략") },
      "시행규칙 제33조제2호는 '200만원 미만'이다. 이하로 읽으면 경계에서 틀린다"
    refute call(type: "construction_general", price: 1_000_000).notes.any? { |n| n.include?("생략") },
      "제33조는 물품·용역만 열거한다. 공사는 대상이 아니다"
  end

  test "임대차도 200만원 미만이면 견적서 생략 대상이다" do
    assert call(type: "lease_etc", price: 1_500_000).notes.any? { |n| n.include?("생략") },
      "시행규칙 제33조제2호는 '물품의 제조ㆍ구매ㆍ임차 및 용역'을 열거한다 — 임차가 빠지면 조문보다 좁게 읽은 것이다"
  end

  test "공사도 특례기업이면 5천만원까지 1인 견적" do
    assert_equal "SINGLE_ALLOWED", call(type: "construction_general", price: 40_000_000, cp: "WOMEN").requirement,
      "제30조제1항제2호 본문은 '공사, 물품의 제조ㆍ구매 및 용역'을 열거하고, 단서는 금액만 바꿀 뿐 유형을 좁히지 않는다"
  end

  test "2인 이상일 때 지정정보처리장치 의무를 함께 안내한다" do
    r = call(type: "goods", price: 30_000_000)
    assert r.legal_basis.any? { |b| b[:locator] == "제30조제2항" }
    assert r.notes.any? { |n| n.include?("지정정보처리장치") }
  end
end
