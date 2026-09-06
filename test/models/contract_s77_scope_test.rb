# frozen_string_literal: true

require "test_helper"

#
# §77 적용범위 회귀 (2026-09-06)
#
# 시행령 제77조는 **공사 전용**이다(표제·본문 모두 "공사"). 따라서 §77 을 근거로 든 진술이
# 공사로 한정되지 않았다면 그 자체가 과확장이다 — 물품·용역의 분할은 §7제2호(추정가격 합산)와
# 행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 제1장 제1절 5.라가 규율한다.
#
# 이 테스트는 "제77조가 있다"로 판정하지 않는다. 같은 **진술(statement)** 안에
#   ① 공사 한정 표지        ② 적용범위를 한정·부정하는 표현   ③ 두 트랙 병기(§7제2호·행안부 예규)
# 중 하나가 있어야 통과한다. 셋 다 없으면 범위를 밝히지 않은 것이다.
#
# 판정 불가로 남긴 것과 사용자에게 나가지 않는 것은 **결함과 섞어 세지 않는다.**
# 전건 근거는 docs/silmu-p2/r2-align/_data/s77_inventory_after.json.
#
class ContractS77ScopeTest < ActiveSupport::TestCase
  S77 = /(?:제77조(?:제\d항)?(?:제\d호)?(?:[가-힣]목)?|§\s*77(?:제\d항)?)/
  CONSTRUCTION = /공사|구조물|공종|공구|시공|설계서|펜스|현장설명/
  SCOPE_LIMIT  = /적용되지\s*않|적용을\s*받지\s*않|인용\s*금지|근거로\s*대지\s*않|공사\s*조항|공사\s*한정|범위를\s*넘|잘못\s*인용/
  # 맨 "예규"는 기획재정부 회계예규·조달청 예규(국가계약 계열)까지 두 트랙으로 착각한다.
  # 행정안전부 집행기준을 가리킬 때만 인정한다 — 실제로 2건이 그렇게 통과했다.
  TWO_TRACK    = /제7조제2호|§\s*7제2호|집행기준\s*제?1?장|행안부\s*예규|행정안전부\s*예규/
  COMMENT      = /\A\s*(?:#|\/\/|<!--)/
  # 줄바꿈을 넘기면 Ruby heredoc 마커(<<~CONTENT)가 태그 시작이 되어 다음 '>' 까지 본문을
  # 통째로 지운다 — 그 구간의 §77 진술이 검사에서 사라진다(실제로 양성 대조가 그걸 잡았다).
  TAG          = /<[^>\n]+>/

  # 판정 대상 원천. R2 판단 엔진·규칙집(§14 동결)은 대상이 아니다.
  SOURCES = %w[
    app/views/legal_compliance_mailer/monthly_deep_check.html.erb
    app/views/topics/flowcharts/_split_contract_prohibition.html.erb
    app/views/guides/audit_frequent_issues.html.erb
    app/views/contract_reasons/index.html.erb
    app/views/guides/contract_flow.html.erb
    app/services/regulation_verifier.rb
    config/tool_trust.yml
    db/seeds/topic_split_contract.rb
    db/seeds/topic_estimated_amount.rb
    db/seeds/topic_faqs_backfill_2026_06_03_batch4.rb
    db/seeds/topic_quick_stats_backfill_2026_06_03_batch7.rb
    db/seeds/zz_guide_verification_2026_06_09_batch5.rb
    db/seeds/zz_topic_verification_2026_06_09_batch4.rb
    db/seeds/audit_cases/contract_method_violations.rb
    db/seeds/audit_cases/topic_audit_cases_batch_01.rb
  ].freeze

  # 자동 규칙이 문장 단위라 못 보는 것. **사유와 함께** 둔다 — 사유 없는 예외는 은폐다.
  ALLOWED = {
    # 계약유형 확정 불가 → CONTEXT_AMBIGUOUS 로 남긴다(§7). 억지로 0 으로 만들지 않는다.
    "db/seeds/audit_cases/topic_audit_cases_batch_01.rb" => [
      "지방계약법 시행령 제77조 (계약 분할 금지), 행정안전부 예규 제2023-24호",
      "실내환경 개선사업(총사업비 1억 5천만원)",
      "'계약 분할 금지 조항(시행령 제77조) 위반 여부"
    ],
    # 사건 자체가 공사(총 공사금액 3억 4,700만원·전문공사 기준 2억원 초과)인데
    # 그 사실이 앞 문장에 있어 진술 단위로는 안 보인다.
    "db/seeds/audit_cases/contract_method_violations.rb" => [
      "단일 사업을 분할하여 금액 기준을 낮추는 행위는"
    ]
  }.freeze

  def statements(text)
    text.gsub(TAG) { |m| " " * m.length }.split(/(?<=[.。!?])\s+|\n/)
  end

  def scoped?(st)
    st.match?(CONSTRUCTION) || st.match?(SCOPE_LIMIT) || st.match?(TWO_TRACK)
  end

  def allowed?(rel, st)
    Array(ALLOWED[rel]).any? { |a| st.include?(a) }
  end

  # 범위를 밝히지 않은 §77 진술을 돌려준다. 주석은 사용자에게 나가지 않으므로 세지 않는다.
  def unscoped_statements(rel)
    text = Rails.root.join(rel).read
    statements(text).filter_map do |st|
      s = st.strip
      next if s.empty? || !s.match?(S77) || s.match?(COMMENT)
      next if scoped?(s) || allowed?(rel, s)
      s[0, 200]
    end
  end

  # ── 양성 대조 — 정정 전 커밋의 실제 문장으로 증명한다 ────────────
  # 다 고친 뒤에는 워킹트리에 결함 표본이 없다. 그때 "0건"만 단언하면
  # 탐지기가 죽어도 통과한다. 그래서 히스토리 blob 을 양성 대조로 쓴다.
  BEFORE_COMMIT = "1ccf310"

  def blob(commit, rel)
    out = `git -C #{Rails.root} show #{commit}:#{rel} 2>/dev/null`
    assert $?.success?, "blob 취득 실패: #{commit}:#{rel}"
    out
  end

  test "양성 대조: 정정 전 원천에서 범위 없는 §77 진술이 실제로 검출된다" do
    {
      "db/seeds/topic_estimated_amount.rb" => "시행령 §77로 금지됩니다",
      "db/seeds/topic_split_contract.rb" => "- 금지 근거: 지방계약법 시행령 제25조, 제77조",
      "app/views/legal_compliance_mailer/monthly_deep_check.html.erb" => "제77조(분할계약 금지)",
      "config/tool_trust.yml" => %(laws: "지방계약법 시행령 제77조"),
      "db/seeds/audit_cases/contract_method_violations.rb" => "시행령 제77조는 분할계약을 명시적으로 금지합니다"
    }.each do |rel, needle|
      before = blob(BEFORE_COMMIT, rel)
      assert_includes before, needle, "#{rel}: 정정 전 표본이 그 커밋에 없다 — 대조 표본이 잘못됐다"
      hit = statements(before).find { |s| s.include?(needle) }
      assert hit, "#{rel}: 표본이 진술로 잘리지 않는다"
      assert_not scoped?(hit),
                 "#{rel}: 탐지기가 정정 전 문장을 이미 '범위 있음'으로 본다 — 탐지기가 죽었다\n  #{hit[0, 160]}"
    end
  end

  # ── 음성 대조 ────────────────────────────────────────────────
  test "음성 대조: 공사 문맥의 정당한 §77 인용은 잡지 않는다" do
    [
      "**지방계약법 시행령 제77조 (공사의 분할계약 금지):** 동일 구조물공사 또는 단일공사",
      "지방계약법 시행령 제77조가 공사의 분할계약 금지를 규정합니다.",
      "{ \"label\" => \"허용 예외\", \"value\" => \"공구별 분할·하자책임 구분 용이 공종 분리 등\", \"note\" => \"지방계약법 시행령 제77조제1항 각 호\" }"
    ].each { |s| assert scoped?(s), "공사 한정 인용을 결함으로 본다: #{s[0, 60]}" }
  end

  test "음성 대조: 적용범위를 한정·부정한 문장과 두 트랙 병기 문장은 잡지 않는다" do
    [
      "물품·용역 — 제77조는 공사 조항이라 적용되지 않습니다.",
      "- 공사의 분할계약 금지: 시행령 제77조 (표제·본문 모두 \"공사\" — 물품·용역에 인용 금지)",
      "분할계약은 공사의 경우 시행령 제77조가, 물품·용역의 경우 시행령 제7조제2호와 행정안전부 예규가 규율합니다."
    ].each { |s| assert scoped?(s), "옳은 문장을 결함으로 본다: #{s[0, 60]}" }
  end

  test "음성 대조: 국가계약 계열 예규(기재부·조달청)는 두 트랙 표지가 아니다" do
    assert_not TWO_TRACK.match?("- 근거: 시행령 제77조, 기획재정부 회계예규"),
               "기획재정부 회계예규를 행안부 집행기준으로 오인한다"
    assert_not TWO_TRACK.match?("- 근거: 시행령 제77조, 조달청 예규"),
               "조달청 예규를 행안부 집행기준으로 오인한다"
    assert TWO_TRACK.match?("행정안전부 예규(집행기준 제1장 제1절 5.라)"), "행안부 집행기준을 못 알아본다"
  end

  # ── 현재 원천에서 0건 ────────────────────────────────────────
  test "§77 을 근거로 든 진술은 전부 적용범위를 밝힌다 (범위 미표시 0건)" do
    offenders = SOURCES.to_h { |rel| [ rel, unscoped_statements(rel) ] }.reject { |_, v| v.empty? }
    assert_empty offenders,
                 "범위를 밝히지 않은 §77 진술이 남아 있다:\n" +
                 offenders.map { |k, v| "  #{k}\n    - #{v.join("\n    - ")}" }.join("\n")
  end

  # 예외 목록은 결함을 숨기는 가장 쉬운 길이다. 개수·폭·실재를 모두 고정한다.
  # (개수만 세면 «넓은 앵커 하나»로 파일 전체를 면제시킬 수 있다)
  test "예외 목록은 조용히 넓어지지 않는다 — 개수·앵커 폭·실재를 함께 고정" do
    total = ALLOWED.values.sum(&:size)
    assert_equal 4, total,
                 "예외 항목 수가 바뀌었다(#{total}) — 판정 없이 늘리거나 줄이지 않는다"
    ALLOWED.each do |rel, anchors|
      src = Rails.root.join(rel).read
      anchors.each do |a|
        assert_operator a.length, :>=, 20,
                        "예외 앵커가 너무 짧다(#{a.length}자) — 넓은 앵커는 파일 전체를 면제시킨다: #{a}"
        assert_includes src, a, "예외 항목이 원천에서 사라졌다: #{a[0, 40]}"
        # 그 앵커가 실제로 §77 진술을 가리키는지 — 무관한 문자열로 면제받는 것을 막는다
        assert a.match?(S77) || src[/[^\n]*#{Regexp.escape(a)}[^\n]*/].to_s.match?(S77),
               "예외 앵커가 §77 진술을 가리키지 않는다: #{a[0, 40]}"
      end
    end
    ambiguous = ALLOWED["db/seeds/audit_cases/topic_audit_cases_batch_01.rb"]
    assert_equal 3, ambiguous.size, "CONTEXT_AMBIGUOUS 3건이 바뀌었다"
  end

  # ── 정정된 정본 표현이 실제로 실려 있다 (양성) ──────────────────
  test "정본 표현 양성: 두 트랙 근거가 실제로 실려 있다" do
    {
      "app/views/topics/flowcharts/_split_contract_prohibition.html.erb" => "제7조제2호",
      "app/views/guides/audit_frequent_issues.html.erb" => "집행기준 제1장 제1절 5.라",
      "config/tool_trust.yml" => "제7조제2호",
      "db/seeds/topic_estimated_amount.rb" => "행정안전부 예규",
      "db/seeds/topic_split_contract.rb" => "제7조제2호",
      "db/seeds/audit_cases/contract_method_violations.rb" => "제7조제2호"
    }.each do |rel, needle|
      assert_includes Rails.root.join(rel).read, needle,
                      "#{rel}: 물품·용역 트랙 근거(#{needle})가 없다"
    end
  end

  test "§77 표제를 조문 원문대로 쓴다 — '추정가격 산정'은 §7이지 §77이 아니다" do
    src = Rails.root.join("db/seeds/topic_split_contract.rb").read
    assert_not_includes src, "시행령 제77조 (추정가격 산정)",
                        "§77 을 '추정가격 산정' 조문으로 표기한다"
    assert_includes src, "시행령 제77조 (공사의 분할계약 금지)", "§77 표제가 조문 원문과 다르다"
  end

  test "§77 인용문은 조문 원문이어야 한다 — 국가계약법 문체의 창작 인용문 0건" do
    src = Rails.root.join("db/seeds/audit_cases/topic_audit_cases_batch_01.rb").read
    assert_not_includes src, "각 중앙관서의 장 또는 계약담당공무원은 수의계약의 한도금액을 초과하기 위하여",
                        "§77 인용문이 조문 원문에 없는 문장이다(국가계약법 문체)"
    assert_includes src, "행정안전부장관이 정하는 동일 구조물공사 또는 단일공사로서",
                        "§77①의 실제 원문이 인용되지 않았다"
  end

  # ── 엔진 ↔ 콘텐츠 의미 정합 ──────────────────────────────────
  test "의미 정합: 물품 트랙에 엔진은 §77 을 인용하지 않고, 콘텐츠도 §77 을 단독 근거로 들지 않는다" do
    r = ContractDecision::SplitProcurementEvaluator.call(
      contract_type: "goods",
      factors: { same_purpose: "yes", within_window: "yes" },
      current_amount: 18_000_000, prior_amounts: [ 18_000_000, 15_000_000 ]
    )
    assert_equal "HIGH_SPLIT_RISK", r.state
    refute_includes r.legal_basis.to_s, "제77조", "엔진이 물품 트랙에 §77 을 인용한다"
    assert_includes r.legal_basis.to_s, "제7조제2호", "엔진이 물품 트랙 근거(§7제2호)를 내지 않는다"

    SOURCES.each do |rel|
      assert_empty unscoped_statements(rel),
                   "#{rel}: 엔진은 물품에 §77 을 대지 않는데 콘텐츠는 범위 없이 §77 을 든다"
    end
  end

  test "의미 정합: 공사 트랙에서는 엔진과 콘텐츠가 모두 §77 을 근거로 삼는다" do
    r = ContractDecision::SplitProcurementEvaluator.call(
      contract_type: "construction_general",
      factors: { single_project: "yes", scope_fixed: "yes" }
    )
    assert_equal "HIGH_SPLIT_RISK", r.state
    assert_includes r.legal_basis.to_s, "제77조", "엔진이 공사 트랙에 §77 을 인용하지 않는다"
    assert_includes Rails.root.join("db/seeds/topic_split_contract.rb").read,
                    "제77조 (공사의 분할계약 금지)",
                    "콘텐츠가 공사 트랙에서 §77 을 근거로 삼지 않는다"
  end

  # ── §14 R2 core 동결 ────────────────────────────────────────
  test "R2 판단 엔진·규칙집은 이번 정정으로 바뀌지 않았다" do
    diff = `git -C #{Rails.root} diff --name-only 93c4fd0 -- app/services/contract_decision config/contract_decision_rules.yml config/contract_thresholds.yml`
    assert_equal "", diff.strip, "R2 core 가 변경됐다:\n#{diff}"
  end
end
