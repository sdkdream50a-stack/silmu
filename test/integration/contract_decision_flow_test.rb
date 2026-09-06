# frozen_string_literal: true

require "test_helper"

# §28 Before/After 과업 테스트 + 두 엔드포인트의 계약(contract).
# 숫자 예시의 정답을 미리 정해 놓지 않고, 조문 규칙이 실제로 무엇을 내는지 고정한다.
class ContractDecisionFlowTest < ActionDispatch::IntegrationTest
  def determine(params)
    post "/contract-methods/determine",
         params: { agency_scope: "LOCAL_GOVERNMENT" }.merge(params), as: :json
    JSON.parse(response.body)
  end

  def split(params)
    post "/tools/split-contract-checker/evaluate", params: params, as: :json
    JSON.parse(response.body)
  end

  # ── 과업 2: 3000만원 물품 수의계약 가능한가 ──
  test "3000만원 물품은 상대방을 물어보고, 일반업체면 경쟁입찰이라고 답한다" do
    unknown = determine(contract_type: "goods", estimated_price: 30_000_000)
    assert_equal "INSUFFICIENT_INFORMATION", unknown.dig("decision", "state")

    general = determine(contract_type: "goods", estimated_price: 30_000_000, counterparty_type: "GENERAL")
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", general.dig("decision", "state")
    assert_equal "입찰", general.dig("result", "method"),
      "판정과 레거시 결론 문구가 어긋나면 화면 큰 글씨와 작은 글씨가 반대로 적힌다"

    youth = determine(contract_type: "goods", estimated_price: 30_000_000, counterparty_type: "YOUTH_STARTUP")
    assert_equal "POSSIBLE", youth.dig("decision", "state")
  end

  # ── 과업 3: 5000만원 용역 수의계약 가능한가 ──
  test "5000만원 용역은 상대방 자격에 따라 결론이 갈린다" do
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED",
                 determine(contract_type: "service", estimated_price: 50_000_000,
                           counterparty_type: "GENERAL").dig("decision", "state")
    assert_equal "POSSIBLE",
                 determine(contract_type: "service", estimated_price: 50_000_000,
                           counterparty_type: "SMALL_ENTERPRISE").dig("decision", "state")
    assert_equal "POSSIBLE_WITH_CONDITIONS",
                 determine(contract_type: "service", estimated_price: 50_000_000,
                           counterparty_type: "SOCIAL_ENTERPRISE").dig("decision", "state")
  end

  # ── 과업 4: 공사를 나눠 계약해도 되나 ──
  test "공사 분할은 제77조로 판단하고 적법 분리 경로를 함께 낸다" do
    r = split(contract_type: "construction_general",
              factors: { single_project: "yes", scope_fixed: "yes" })
    assert_equal "HIGH_SPLIT_RISK", r["state"]
    assert r["lawful_separation_grounds"].size >= 4, "분리가 허용되는 사유를 보여주지 않으면 반대로 이끈다"

    ok = split(contract_type: "construction_general", separation_ground: "D77-1-1",
               factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "no" })
    assert_equal "LEGITIMATE_SEPARATION_POSSIBLE", ok["state"]
  end

  # ── 과업 5: 같은 물품을 여러 번 나눠 사도 되나 ──
  test "물품 반복 구매는 제7조제2호로 합산하고 제77조를 인용하지 않는다" do
    r = split(contract_type: "goods",
              factors: { same_purpose: "yes", within_window: "yes" },
              current_amount: 18_000_000, prior_amounts: [ 18_000_000, 15_000_000 ])
    assert_equal "HIGH_SPLIT_RISK", r["state"]
    assert_equal 51_000_000, r.dig("aggregation", "total")
    assert_equal 12, r.dig("aggregation", "window_months")
    assert r["legal_basis"].any? { |b| b["locator"] == "제7조제2호" }
    refute r["legal_basis"].any? { |b| b["locator"].to_s.include?("제77조") }
  end

  # ── 과업 6: 분리발주와 분할발주의 차이 ──
  test "적법한 분리와 금지되는 분할이 서로 다른 결과로 나온다" do
    lawful = split(contract_type: "construction_etc", separation_ground: "D77-1-1",
                   factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "no" })
    unlawful = split(contract_type: "construction_etc", separation_ground: "D77-1-1",
                     factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "yes" })
    refute_equal lawful["state"], unlawful["state"]
    assert_equal "LEGITIMATE_SEPARATION_POSSIBLE", lawful["state"]
    assert_equal "HIGH_SPLIT_RISK", unlawful["state"]
  end

  # ── 기관 범위가 화면 계약에 드러나는가 (§8) ──
  test "국가기관은 판단하지 않고 그 이유를 낸다" do
    r = determine(agency_scope: "CENTRAL_GOVERNMENT", contract_type: "goods", estimated_price: 10_000_000)
    assert_equal "OUT_OF_SCOPE", r.dig("decision", "state")
    assert_equal "확인 필요", r.dig("result", "method")
  end

  # ── 설명가능성 (§18) ──
  test "판정 응답은 근거와 미해결 요인을 함께 낸다" do
    d = determine(contract_type: "goods", estimated_price: 10_000_000).fetch("decision")
    %w[state headline matched_rule legal_basis unresolved_factors next_actions input].each do |k|
      assert d.key?(k), "#{k} 누락 — black-box 판정 금지"
    end
    assert d["legal_basis"].first["effective_from"].present?
  end

  # ── 두 도구가 서로를 가리키는가 (§14 · §23) ──
  test "계약방식 도구가 분할발주 도구로, 분할발주 도구가 계약방식 도구로 연결된다" do
    get "/tools/contract-method"
    assert_response :success
    assert_includes response.body, "/tools/split-contract-checker"

    get "/tools/split-contract-checker"
    assert_response :success
    assert_includes response.body, "/tools/contract-method"
  end

  # ── 화면이 적법을 확정하지 않는가 (§13) ──
  test "두 도구 모두 적법 확정이 아니라고 명시한다" do
    get "/tools/contract-method"
    assert_includes response.body, "적법 확정이 아닙니다"
    get "/tools/split-contract-checker"
    assert_includes response.body, "적법·위법 확정이 아닙니다"
  end

  # ── 조문에 없는 자격을 화면이 제시하지 않는가 ──
  test "일반 협동조합을 특례 상대방으로 제시하지 않는다" do
    get "/tools/contract-method"
    refute_includes response.body, 'data-cp="COOPERATIVE"'
  end

  test "구 special_enterprise=cooperative 로 들어와도 자격을 인정하지 않는다" do
    r = determine(contract_type: "service", estimated_price: 80_000_000, special_enterprise: "cooperative")
    assert_equal "INSUFFICIENT_INFORMATION", r.dig("decision", "state"),
      "조문 목록에 없는 상대방을 특례로 통과시키면 자격 없는 수의계약을 안내하게 된다"
  end

  test "구 special_enterprise=women 은 여성기업으로 계속 인식된다" do
    r = determine(contract_type: "goods", estimated_price: 80_000_000, special_enterprise: "women")
    assert_equal "POSSIBLE", r.dig("decision", "state")
    assert_equal "D25-1-5-바-1-2", r.dig("decision", "matched_rule", "rule_id")
  end
end
