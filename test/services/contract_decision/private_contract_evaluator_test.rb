# frozen_string_literal: true

require "test_helper"

# 이 스위트가 지키는 것: **금액만으로 수의계약 가능이라고 말하지 않는다.**
# 운영에서 실제로 그렇게 말하고 있었다 — 물품 3천만원·상대방 미지정에
# "수의계약 / 2인 이상 견적"이라는 확정 문구가 나왔고, 같은 응답의 작은 글씨는
# "일반 업체와의 계약은 2천만원 초과 시 경쟁입찰 대상"이라고 반대로 적혀 있었다.
class ContractDecision::PrivateContractEvaluatorTest < ActiveSupport::TestCase
  E = ContractDecision::PrivateContractEvaluator

  def call(**kw)
    E.call(**{ agency_scope: "LOCAL_GOVERNMENT" }.merge(kw))
  end

  # ── 양성대조: 조문이 그대로 적용되는 명확한 케이스부터 잡는지 ──
  test "물품 1천만원은 나목으로 수의계약 대상" do
    r = call(contract_type: "goods", estimated_price: 10_000_000, counterparty_type: "GENERAL")
    assert_equal "POSSIBLE", r.state
    assert_equal "D25-1-5-나", r.matched_rule["rule_id"]
    assert_equal "제25조제1항제5호나목", r.legal_basis.first[:locator]
  end

  test "종합공사 3억은 가목으로 수의계약 대상" do
    r = call(contract_type: "construction_general", estimated_price: 300_000_000)
    assert_equal "POSSIBLE", r.state
    assert_equal "D25-1-5-가-general", r.matched_rule["rule_id"]
  end

  test "전문공사 3억은 한도(2억) 초과로 경쟁입찰" do
    r = call(contract_type: "construction_special", estimated_price: 300_000_000)
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r.state
  end

  # ── 핵심 회귀: 금액만으로 단정하지 않는다 ──
  test "물품 3천만원 상대방 미상은 판단 보류" do
    r = call(contract_type: "goods", estimated_price: 30_000_000)
    assert_equal "INSUFFICIENT_INFORMATION", r.state,
      "2천만원 초과 물품에서 상대방 자격을 모르면 수의계약 가능/불가 어느 쪽도 단정할 수 없다"
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "COUNTERPARTY_TYPE"
  end

  test "물품 3천만원 일반업체는 경쟁입찰 — 수의계약이라고 말하지 않는다" do
    r = call(contract_type: "goods", estimated_price: 30_000_000, counterparty_type: "GENERAL")
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r.state
    refute_includes r.headline, "수의계약 대상에 해당합니다"
  end

  test "용역 5천만원 일반업체도 경쟁입찰" do
    r = call(contract_type: "service", estimated_price: 50_000_000, counterparty_type: "GENERAL")
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r.state
  end

  test "2천만원 이하는 상대방을 몰라도 판단할 수 있다" do
    r = call(contract_type: "goods", estimated_price: 20_000_000)
    assert_equal "POSSIBLE", r.state,
      "상대방 자격이 결론을 가르지 않는 구간에서까지 정보 부족이라고 하면 도구가 쓸모없어진다"
  end

  # ── 상대방 자격별 분기 (§25①5호 다·라·바) ──
  test "청년창업기업 4천만원 용역은 다목으로 가능" do
    r = call(contract_type: "service", estimated_price: 40_000_000, counterparty_type: "YOUTH_STARTUP")
    assert_equal "POSSIBLE", r.state
    assert_equal "D25-1-5-다", r.matched_rule["rule_id"]
  end

  test "청년창업기업 8천만원은 다목 상한(5천만) 초과로 경쟁입찰" do
    r = call(contract_type: "service", estimated_price: 80_000_000, counterparty_type: "YOUTH_STARTUP")
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r.state,
      "청년창업기업 상한은 5천만원이다. 다른 특례의 1억원을 끌어다 쓰면 안 된다"
  end

  test "소기업 8천만원은 라목으로 가능" do
    r = call(contract_type: "goods", estimated_price: 80_000_000, counterparty_type: "SMALL_ENTERPRISE")
    assert_equal "POSSIBLE", r.state
    assert_equal "D25-1-5-라", r.matched_rule["rule_id"]
  end

  test "여성기업 8천만원은 바목으로 가능" do
    r = call(contract_type: "goods", estimated_price: 80_000_000, counterparty_type: "WOMEN")
    assert_equal "POSSIBLE", r.state
    assert_equal "D25-1-5-바-1-2", r.matched_rule["rule_id"]
  end

  # ── 취약계층 고용비율 단서 (§25①5호바목 단서) ──
  test "사회적기업은 취약계층 고용비율 미확인이면 조건부" do
    r = call(contract_type: "goods", estimated_price: 80_000_000, counterparty_type: "SOCIAL_ENTERPRISE")
    assert_equal "POSSIBLE_WITH_CONDITIONS", r.state
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "VULNERABLE_EMPLOYMENT_RATIO"
  end

  test "사회적기업이 고용비율을 충족하지 못하면 이 사유를 쓸 수 없다" do
    r = call(contract_type: "goods", estimated_price: 80_000_000,
             counterparty_type: "SOCIAL_ENTERPRISE", vulnerable_ratio_met: false)
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r.state
  end

  test "취약계층 고용비율은 바목 단서에만 붙는다 — 나목·가목에는 요구하지 않는다" do
    r = call(contract_type: "goods", estimated_price: 10_000_000, counterparty_type: "SOCIAL_ENTERPRISE")
    assert_equal "POSSIBLE", r.state,
      "2천만원 이하(나목)는 상대방 자격을 조건 삼지 않는다. 단서를 여기까지 끌고 오면 없는 요건을 요구하게 된다"
    refute_includes r.unresolved_factors.map { |f| f[:factor] }, "VULNERABLE_EMPLOYMENT_RATIO"

    c = call(contract_type: "construction_general", estimated_price: 300_000_000, counterparty_type: "VILLAGE")
    assert_equal "POSSIBLE", c.state, "공사(가목)도 상대방 자격 조건이 없다"
    assert_empty c.conditions
  end

  test "마을기업은 행안부 기준 적합 조건이 함께 제시된다" do
    r = call(contract_type: "goods", estimated_price: 80_000_000,
             counterparty_type: "VILLAGE", vulnerable_ratio_met: true)
    assert r.conditions.any? { |c| c.include?("행정안전부장관") }
  end

  # ── 조문에 없는 상대방을 만들어내지 않는다 ──
  test "일반 협동조합은 특례 상대방 목록에 없다" do
    refute_includes ContractDecision::RuleSet.current.counterparty_types.keys, "COOPERATIVE",
      "시행령 제25조제1항제5호바목 4)는 협동조합 기본법 제2조제3호 '사회적협동조합'이다. " \
      "일반 협동조합을 특례로 넣으면 자격 없는 상대방과의 수의계약을 가능하다고 안내하게 된다"
  end

  # ── 독립검증(gemini) 지적 수리분 ──
  test "특수분야 계약은 상대방을 몰라도 판단할 수 있다" do
    r = call(contract_type: "service", estimated_price: 50_000_000, special_field: true)
    assert_equal "POSSIBLE_WITH_CONDITIONS", r.state,
      "마목은 상대방 자격을 조건 삼지 않는다(counterparties: any). 결론이 나는데 되물으면 도구가 답을 미루기만 한다"
    assert_equal "D25-1-5-마", r.matched_rule["rule_id"]
  end

  test "어떤 상대방 자격으로도 닿지 않는 금액이면 상대방을 묻지 않는다" do
    r = call(contract_type: "goods", estimated_price: 150_000_000)
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", r.state,
      "물품·용역 수의계약 한도는 모든 자격을 통틀어 1억원이다. 그 위는 상대방과 무관하게 확정된다"
  end

  test "취약계층 고용비율을 충족하면 조건이 해소되고 POSSIBLE 이 된다" do
    r = call(contract_type: "goods", estimated_price: 30_000_000,
             counterparty_type: "SOCIAL_ENTERPRISE", vulnerable_ratio_met: true)
    assert_equal "POSSIBLE", r.state,
      "요건을 갖췄다고 답한 사용자에게 계속 '조건을 충족할 때에만'이라고 하면 모순된 안내다"
    assert_empty r.conditions
  end

  test "마을기업은 고용비율을 충족해도 행안부 기준 조건이 남는다" do
    r = call(contract_type: "goods", estimated_price: 30_000_000,
             counterparty_type: "VILLAGE", vulnerable_ratio_met: true)
    assert_equal "POSSIBLE_WITH_CONDITIONS", r.state
    assert r.conditions.any? { |c| c.include?("행정안전부장관") }
  end

  # ── 기관 범위 (§8) ──
  test "국가기관은 판단하지 않고 범위 밖이라고 말한다" do
    r = call(agency_scope: "CENTRAL_GOVERNMENT", contract_type: "goods", estimated_price: 10_000_000)
    assert_equal "OUT_OF_SCOPE", r.state
    assert_includes r.unresolved_factors.first[:detail], "국가계약법"
  end

  test "기관을 선택하지 않으면 판단하지 않는다" do
    r = E.call(agency_scope: nil, contract_type: "goods", estimated_price: 10_000_000)
    assert_equal "INSUFFICIENT_INFORMATION", r.state
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "AGENCY_SCOPE"
  end

  test "교육청과 국공립학교는 범위 안" do
    %w[EDUCATION_OFFICE PUBLIC_SCHOOL].each do |scope|
      r = call(agency_scope: scope, contract_type: "goods", estimated_price: 10_000_000)
      assert_equal "POSSIBLE", r.state, "#{scope} 가 범위 밖으로 떨어졌다"
    end
  end

  # ── 경계값 ──
  test "나목 경계 2천만원은 이하이므로 포함, 2천만원 1원은 제외" do
    assert_equal "POSSIBLE", call(contract_type: "goods", estimated_price: 20_000_000).state
    assert_equal "INSUFFICIENT_INFORMATION", call(contract_type: "goods", estimated_price: 20_000_001).state
  end

  test "종합공사 4억 경계" do
    assert_equal "POSSIBLE", call(contract_type: "construction_general", estimated_price: 400_000_000).state
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED",
                 call(contract_type: "construction_general", estimated_price: 400_000_001).state
  end

  test "금액이나 유형이 없으면 판단 보류" do
    assert_equal "INSUFFICIENT_INFORMATION", call(contract_type: "goods", estimated_price: 0).state
    assert_equal "INSUFFICIENT_INFORMATION", call(contract_type: nil, estimated_price: 10_000_000).state
  end

  # ── 설명가능성 (§18) ──
  test "결과는 언제나 왜 그런지를 함께 낸다" do
    r = call(contract_type: "goods", estimated_price: 10_000_000)
    h = r.to_h
    %i[input matched_rule legal_basis unresolved_factors].each { |k| assert h.key?(k), "#{k} 누락" }
    assert r.legal_basis.first[:effective_from].present?, "근거에 시행일이 없으면 현행성을 알 수 없다"
  end

  test "점수를 출력하지 않는다" do
    r = call(contract_type: "goods", estimated_price: 10_000_000)
    refute r.to_h.to_s.match?(/\b\d{1,3}점\b/), "근거 없는 AI score 금지"
  end

  # ── 금액 외 사유를 감추지 않는다 ──
  test "경쟁입찰 결론에도 금액 외 수의계약 사유를 안내한다" do
    r = call(contract_type: "goods", estimated_price: 30_000_000, counterparty_type: "GENERAL")
    assert r.other_grounds.any? { |g| g["locator"].include?("제25조제1항제1호") }
  end
end
