# frozen_string_literal: true

require "test_helper"

# 이 스위트가 지키는 것: 공사(§77)와 물품·용역(§7제2호)의 **근거를 섞지 않는다.**
# 운영 도구는 물품·용역 분할의 근거로 §77(공사의 분할계약 금지)을 인용하고 있었고,
# 합산 기간을 "최근 3개월"로 잡고 있었다 — 조문은 12개월/회계연도다.
class ContractDecision::SplitProcurementEvaluatorTest < ActiveSupport::TestCase
  E = ContractDecision::SplitProcurementEvaluator

  # ── 근거 조문이 트랙별로 갈리는가 ──
  test "공사 트랙은 제77조를 근거로 든다" do
    r = E.call(contract_type: "construction_general",
               factors: { single_project: "yes", scope_fixed: "yes" })
    assert_equal "CONSTRUCTION", r.track
    assert r.legal_basis.any? { |b| b[:locator].start_with?("제77조") }
  end

  test "물품·용역 트랙은 제7조제2호를 근거로 들고 제77조를 인용하지 않는다" do
    r = E.call(contract_type: "goods",
               factors: { same_purpose: "yes", within_window: "yes" })
    assert_equal "GOODS_SERVICE", r.track
    assert r.legal_basis.any? { |b| b[:locator] == "제7조제2호" }
    refute r.legal_basis.any? { |b| b[:locator].to_s.include?("제77조") },
      "제77조는 표제·본문 모두 '공사'다. 물품·용역에 근거로 대면 조문 오인용이다"
  end

  # ── 합산 기간은 조문값이어야 한다 ──
  test "합산 기간은 12개월이다" do
    r = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" },
               current_amount: 18_000_000, prior_amounts: [ 18_000_000 ])
    assert_equal 12, r.aggregation[:window_months],
      "조문에 없는 3개월 같은 기간을 쓰면 임의 기준을 만든 것이다"
  end

  test "합산 임계는 제30조제1항제2호 본문의 2천만원이며 조문 위치를 함께 낸다" do
    r = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" },
               current_amount: 18_000_000, prior_amounts: [ 18_000_000, 15_000_000 ])
    assert_equal 20_000_000, r.aggregation[:single_quote_threshold]
    assert_equal "제30조제1항제2호 본문", r.aggregation[:threshold_locator]
    assert_equal 51_000_000, r.aggregation[:total]
    assert r.aggregation[:exceeds_single_quote_threshold]
    assert_equal "HIGH_SPLIT_RISK", r.state
  end

  test "합산액이 기준 이하면 위험 확정이 아니라 검토 필요" do
    r = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" },
               current_amount: 5_000_000, prior_amounts: [ 5_000_000 ])
    assert_equal "REVIEW_NEEDED", r.state
    refute r.aggregation[:exceeds_single_quote_threshold]
  end

  # ── 적법한 분리 (§77①1~3호) ──
  test "다른 법령에 따른 분리발주는 위법이 아니라 적법 가능으로 나온다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-1",
               factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "no" })
    assert_equal "LEGITIMATE_SEPARATION_POSSIBLE", r.state,
      "전기·정보통신·소방 등 법령상 분리발주까지 위험으로 표시하면 실무를 반대로 이끈다"
  end

  test "적법 분리 사유가 있어도 회피 목적이면 제77조제3항이 덮는다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-1",
               factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "yes" })
    assert_equal "HIGH_SPLIT_RISK", r.state
    assert r.legal_basis.any? { |b| b[:locator] == "제77조제3항" }
  end

  # §77③ 은 "제1항 각 호의 공사"에 붙는 조항이다. 적용 범위를 넘겨 인용하지 않는다.
  test "사실관계가 미상인데 회피 목적만 있으면 §77③을 인용하지 않는다" do
    r = E.call(contract_type: "construction_general", factors: { avoidance_intent: "yes" })
    assert_equal "REVIEW_NEEDED", r.state,
      "사실관계가 성립하지 않은 상태에서 회피 목적 답변만으로 위험을 확정하면 조문 적용범위를 넘는다"
    refute r.legal_basis.any? { |b| b[:locator] == "제77조제3항" }
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "AVOIDANCE_SCOPE"
  end

  test "제77조제1항 요건이 성립하거나 각 호 사유를 주장하면 회피 목적에 §77③이 붙는다" do
    shape = E.call(contract_type: "construction_general",
                   factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "yes" })
    ground = E.call(contract_type: "construction_general", separation_ground: "D77-1-1",
                    factors: { single_project: "yes", scope_fixed: "unknown", avoidance_intent: "yes" })
    [ shape, ground ].each do |r|
      assert_equal "HIGH_SPLIT_RISK", r.state
      assert r.legal_basis.any? { |b| b[:locator] == "제77조제3항" }
    end
  end

  test "적법 분리 주장에도 회피 목적 미확인은 미해결 요인으로 남는다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-1",
               factors: { single_project: "yes", scope_fixed: "yes" })
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "AVOIDANCE_INTENT"
  end

  test "공구 분할(제2호)에는 보고 의무가 따라붙는다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-2",
               factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "no" })
    assert r.duties.any? { |d| d[:kind] == "REPORTING" && d[:source_locator] == "제77조제4항" }
    assert r.next_actions.any? { |a| a.include?("보고") }
  end

  test "계획 단계 검토 의무를 항상 안내한다" do
    r = E.call(contract_type: "construction_general", factors: { single_project: "yes", scope_fixed: "yes" })
    assert r.duties.any? { |d| d[:kind] == "PLANNING" && d[:source_locator] == "제77조제2항" }
  end

  # ── 정보 부족 (§29) ──
  test "공사에서 사실관계를 모르면 판단하지 않는다" do
    r = E.call(contract_type: "construction_general", factors: {})
    assert_equal "INSUFFICIENT_INFORMATION", r.state
  end

  test "물품·용역에서 동일성 여부를 모르면 판단하지 않는다" do
    r = E.call(contract_type: "goods", factors: { within_window: "yes" })
    assert_equal "INSUFFICIENT_INFORMATION", r.state
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "SAME_PURPOSE"
  end

  test "계약 유형이 없으면 어느 조문을 쓸지 정할 수 없다" do
    r = E.call(contract_type: nil, factors: { same_purpose: "yes" })
    assert_equal "INSUFFICIENT_INFORMATION", r.state
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "CONTRACT_TYPE"
  end

  # ── 금지 요건 미충족 ──
  test "단일공사가 아니면 제77조제1항 금지 요건을 충족하지 않는다" do
    r = E.call(contract_type: "construction_general",
               factors: { single_project: "no", scope_fixed: "yes" })
    assert_equal "LOW_RISK", r.state
    assert r.unresolved_factors.any? { |f| f[:factor] == "SELF_REPORTED" },
      "입력을 그대로 받은 판정이라는 사실을 숨기면 안 된다"
  end

  test "동일 조달 요구가 아니면 합산 대상이 아니다" do
    r = E.call(contract_type: "service", factors: { same_purpose: "no" })
    assert_equal "LOW_RISK", r.state
  end

  # ── 독립검증(gemini) 지적 수리분 ──
  test "금지 요건이 확정 미충족이면 분리 사유를 주장할 필요가 없다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-1",
               factors: { single_project: "no", scope_fixed: "no", avoidance_intent: "no" })
    assert_equal "LOW_RISK", r.state,
      "§77①이 적용되지 않는 계약에 예외 사유를 입증하게 하면 없는 책임을 지운다"
    refute_includes r.headline, "분리 발주가 가능합니다"
  end

  test "별개 사업인데 회피 목적이라는 답은 모순으로 짚는다" do
    r = E.call(contract_type: "construction_general",
               factors: { single_project: "no", scope_fixed: "no", avoidance_intent: "yes" })
    assert_equal "REVIEW_NEEDED", r.state
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "INCONSISTENT_INPUT"
    refute r.legal_basis.any? { |b| b[:locator] == "제77조제3항" },
      "§77 이 적용되지 않는 계약에 §77③ 위반이라고 할 수는 없다"
  end

  test "분리 사유의 근거 출처는 규칙집에서 온다 — 코드에 하드코딩하지 않는다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-2",
               factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "no" })
    cite = r.legal_basis.find { |b| b[:locator] == "제77조제1항제2호" }
    assert cite, "분리 사유가 근거로 인용되지 않았다"
    assert_equal "LOCAL_CONTRACT_DECREE", cite[:source_key]
  end

  # ── 독립검증(kimi) 지적 수리분 ──
  test "합산액은 확정치가 아님을 함께 낸다 — 직후 12개월은 미래다" do
    r = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" },
               current_amount: 5_000_000, prior_amounts: [ 5_000_000 ])
    assert_includes r.unresolved_factors.map { |f| f[:factor] }, "FUTURE_WINDOW",
      "제7조제2호 나목의 직후 12개월을 빼고 확정처럼 보이면 남은 연간 소요를 놓친 채 한도 안이라 판단한다"
  end

  test "물품·용역 LOW_RISK 가 '분할해도 된다'로 읽히지 않게 한다" do
    r = E.call(contract_type: "service", factors: { same_purpose: "no" })
    assert_equal "LOW_RISK", r.state
    assert_includes r.headline, "합산 산정 대상이 아니다"
  end

  test "적법 분리 판정에 §77③ 목적 심사가 별개임을 명시한다" do
    r = E.call(contract_type: "construction_general", separation_ground: "D77-1-1",
               factors: { single_project: "yes", scope_fixed: "yes", avoidance_intent: "no" })
    assert_equal "LEGITIMATE_SEPARATION_POSSIBLE", r.state
    assert_includes r.headline, "제77조제3항"
    assert_includes r.headline, "적법 확정이 아닙니다"
  end

  # ── 검토축 (§5) — 계약유형별 근거 분리 ──
  test "공사와 물품·용역의 검토축 근거가 서로 다르다" do
    c = E.call(contract_type: "construction_general", factors: { single_project: "yes", scope_fixed: "yes" })
    g = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" })

    assert_equal 8, c.review_axes.size
    assert_equal 8, g.review_axes.size

    c_loc = c.review_axes.filter_map { |a| a[:legal_basis]&.dig(:locator) }
    g_loc = g.review_axes.filter_map { |a| a[:legal_basis]&.dig(:locator) }
    assert c_loc.all? { |l| l.start_with?("제77조") }, "공사 축이 §77 외 조문을 근거로 든다: #{c_loc}"
    assert g_loc.all? { |l| l.start_with?("제7조") },  "물품·용역 축이 §7 외 조문을 근거로 든다: #{g_loc}"
    refute g_loc.any? { |l| l.include?("제77조") }, "물품·용역에 공사 조항을 끌어다 쓰면 안 된다"
  end

  test "물품·용역에서 근거를 확인하지 못한 축은 REVIEW_REQUIRED 로 남는다" do
    g = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" })
    unbased = g.review_axes.select { |a| a[:legal_basis].nil? }
    assert_equal 4, unbased.size,
      "§77(공사)·§28(한정 허용)을 끌어다 쓰면 근거 없는 축이 0이 된다 — 그게 조문 확장이다"
    assert unbased.all? { |a| a[:answer] == "REVIEW_REQUIRED" }
    assert unbased.all? { |a| a[:review_reason].present? }, "왜 판정하지 않는지 적어야 한다"
    assert_equal %w[AVOIDANCE_EFFECT TECHNICAL_INDEPENDENCE SEPARATE_ORDER_REQUIRED OBJECTIVE_SEPARATION],
                 unbased.map { |a| a[:axis] }
  end

  test "공사는 8축 전부 근거를 갖는다" do
    c = E.call(contract_type: "construction_general", factors: { single_project: "yes", scope_fixed: "yes" })
    assert c.review_axes.all? { |a| a[:legal_basis].present? }
  end

  test "판정에 실제로 쓰이는 축만 decides 로 표시된다" do
    g = E.call(contract_type: "goods", factors: { same_purpose: "yes", within_window: "yes" })
    assert_equal 4, g.review_axes.count { |a| a[:decides] }
    c = E.call(contract_type: "construction_general", factors: { single_project: "yes", scope_fixed: "yes" })
    assert_operator c.review_axes.count { |a| a[:decides] }, :>=, 3
  end

  # ── 점수·임의 임계값 금지 (§27) ──
  test "체크 개수로 위험도를 만들지 않는다" do
    all_unknown = E.call(contract_type: "construction_general",
                         factors: { single_project: "unknown", scope_fixed: "unknown", avoidance_intent: "unknown" })
    assert_equal "INSUFFICIENT_INFORMATION", all_unknown.state
    refute all_unknown.to_h.to_s.match?(/\d\/5|위험도\s*\d/), "체크 n개 = 위험 등급 식 산정 금지"
  end

  test "어떤 결과도 적법을 확정하지 않는다" do
    ContractDecision::SplitProcurementEvaluator::STATES.each do |s|
      refute_includes s, "LAWFUL_CONFIRMED"
    end
    r = E.call(contract_type: "goods", factors: { same_purpose: "no" })
    refute r.headline.include?("적법"), "'적법 확정'을 말하지 않는다 (§13)"
  end
end
