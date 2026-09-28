# frozen_string_literal: true

require "test_helper"

# 2026-09-29 예비비 토픽 «지방재정법 시행령 제65조»(재정분석·재정점검 조문) 오인용 정정 회귀.
# 원문 근거는 마이그레이션 머리말(law.go.kr DRF URL) 참조.
class ContingencyFundArticleFixTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929040000_contingency_fund_article_fix.rb")
  WRONG = "시행령 제65조"

  # 운영(2026-09-29 익명 GET)과 같은 옛 값
  OLD_FAQS = [
    { "question" => "예비비는 얼마까지 편성할 수 있나요?",
      "answer" => "일반예비비는 일반회계 예산총액의 100분의 1(1%) 이내로 계상할 수 있습니다(지방재정법 제43조). 재해·재난 대비 목적예비비는 별도로 편성할 수 있으며, 실무상 일반예비비는 0.3~0.7% 수준으로 편성하는 경우가 많습니다." },
    { "question" => "예비비는 어떤 경우에 쓸 수 있나요?",
      "answer" => "예측 불가능성, 긴급성, 기존 예산의 전용·이용으로 해결 불가, 목적 적합성 요건을 모두 충족해야 사용할 수 있습니다(지방재정법 시행령 제65조). 신규 사업 추진이나 의회가 삭감한 사업에는 예비비를 사용할 수 없습니다." }
  ].freeze
  OLD_QS = [
    { "label" => "일반예비비 한도", "value" => "일반회계 예산총액의 1% 이내", "note" => "지방재정법 제43조" },
    { "label" => "사용 요건", "value" => "예측불가·긴급·예산부족·목적적합 모두 충족", "note" => "지방재정법 시행령 제65조" }
  ].freeze
  OLD_RULE = <<~MD
    ## 예비비 사용 제한 및 금지 사항

    ❌ 사용 불가 사례
    - 예산 편성 시 충분히 예측 가능했던 지출
    - 신규 사업 추진을 위한 예산 확보
    - 인건비 부족분 보충(별도 규정 없는 경우)
  MD
  OLD_REGULATION = <<~MD
    #### 예비비 종류 및 편성 한도
    | 구분 | 내용 | 편성 한도 |
    |------|------|----------|
    | 일반예비비 | 재해·재난 등 예측 불가 경비 | 일반회계 세출예산의 1/100 이상 |
    | 목적예비비 | 특정 목적을 위해 편성 | 세출예산 총액의 2/100 이내 |

    #### 예비비 사용 절차 (지방재정법 제43조 및 시행령 제59조)
    1. **사용 신청**: 해당 부서에서 예비비 사용 신청서 제출
    6. **사후 보고**: 다음 정기의회에 예비비 사용 명세서 제출 및 보고

    #### 예비비 사용 제한 사항 (행안부 지침)
    - 의회 의결로 삭감된 사업에 예비비 지원 금지
    - 인건비 예비비 사용은 법령상 의무 지출 증가에 한정
    - 신규 사업은 원칙적으로 추경 편성 대상 (예비비 사용 부적합)
    - 연말 집중 예비비 사용은 재정분석 감점 대상
  MD
  OLD_GUIDE_SECTIONS = {
    "step2" => { "title" => "예비비 사용 가능 요건 3가지", "items" => [
      "요건①: 예측 불가능성 — 당초 예산 편성 시 예상할 수 없었던 사유여야 함",
      "요건②: 긴급성 — 추경 편성이나 전용을 기다릴 시간적 여유가 없어야 함",
      "요건③: 불가피성 — 다른 예산 과목으로 대체하거나 지출을 연기할 수 없어야 함",
      "※ 세 요건을 모두 충족해야 예비비 사용 가능 — 하나라도 빠지면 불가"
    ] },
    "step3" => { "title" => "예비비 신청 절차 (5단계)", "items" => [ "1단계: 사용 요건 검토 — 예측 불가능성·긴급성·불가피성 3요건 자가 점검" ] }
  }.freeze

  setup do
    Topic.new(slug: "contingency-fund", name: "예비비", faqs: OLD_FAQS, quick_stats: OLD_QS,
              rule_content: OLD_RULE, regulation_content: OLD_REGULATION, view_count: 321).save!(validate: false)
    Guide.new(slug: "budget-execution-complete-7", title: "예비비 사용 완전정복 — 왕초보 완전정복 7편", category: "예산",
              sections: OLD_GUIDE_SECTIONS, view_count: 77).save!(validate: false)
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def topic_text
    t = Topic.find_by!(slug: "contingency-fund")
    [ t.faqs.to_json, t.quick_stats.to_json, t.rule_content, t.regulation_content ].join
  end

  test "옛 값에는 오인용이 있다 (대조군)" do
    assert_includes topic_text, WRONG
  end

  test "오인용 시행령 제65조가 사라지고 확인된 법 제43조제1항이 들어간다 · slug·이름·조회수 불변" do
    migrate
    text = topic_text
    assert_not_includes text, WRONG
    assert_not_includes text, "재정분석"
    assert_includes text, "지방재정법 제43조제1항은 예비비를 「예측할 수 없는 예산 외의 지출 또는 예산 초과 지출」에 충당하도록"
    assert_includes text, "지방재정법 제43조제1항(예측할 수 없는 지출)"
    assert_not_includes text, "요건을 모두 충족해야"
    t = Topic.find_by!(slug: "contingency-fund")
    assert_equal "예비비", t.name
    assert_equal 321, t.view_count
    assert_equal OLD_FAQS.map { |f| f["question"] }, t.faqs.map { |f| f["question"] }
  end

  test "법령에 없는 의무 문구가 사라지고 제43조제3항 금지는 법적 서술로 남는다" do
    migrate
    text = topic_text
    assert_not_includes text, "신규 사업 추진이나"
    assert_not_includes text, "모두 충족"
    assert_includes text, "신규 사업은 실무상 예비비 대신 추가경정예산으로 처리하는 것이 일반적입니다."
    assert_includes text, "긴급·예산부족·목적적합(실무 검토)"
    answer = Topic.find_by!(slug: "contingency-fund").faqs.last["answer"]
    assert_includes answer, "폐지되거나 감액된 지출항목에는 예비비를 사용할 수 없습니다(같은 조 제3항)."
  end

  test "DRY_RUN 은 쓰지 않는다 · 적용 2건 · 재실행 0건" do
    out = migrate("DRY_RUN" => "1")
    assert_includes out, "Guide/budget-execution-complete-7 fields_to_change=sections"
    assert_includes out, "fields_to_change=regulation_content"
    assert_includes out, "fields_to_change=rule_content"
    assert_includes out, "fields_to_change=faqs"
    assert_includes out, "fields_to_change=quick_stats"
    assert_includes out, "DRY_RUN changes=20"
    assert_includes topic_text, WRONG

    assert_includes migrate, "changes=20"
    assert_includes migrate, "changes=0"
  end

  test "운영 값이 예상과 다르면 전부 롤백한다" do
    Topic.find_by!(slug: "contingency-fund").update_columns(quick_stats: [ { "label" => "사용 요건", "note" => "다른 값" } ])
    assert_raises(RuntimeError) { migrate }
    assert_includes Topic.find_by!(slug: "contingency-fund").faqs.to_json, WRONG
  end

  test "사용 불가 사례·«행안부 지침» 제한 사항·가이드 3요건이 법(제43조①③)과 실무로 나뉜다" do
    migrate
    t = Topic.find_by!(slug: "contingency-fund")
    assert_includes t.rule_content, "신규 사업 추진을 위한 예산 확보 (실무 관행 — 법령상 금지 조항은 없으나 실무상 추경 대상)"
    assert_equal 1, t.rule_content.scan("신규 사업 추진을 위한 예산 확보").size
    reg = t.regulation_content
    assert_not_includes reg, "행안부 지침"
    assert_not_includes reg, "재정분석 감점"
    assert_not_includes reg, "원칙적으로 추경 편성 대상"
    assert_includes reg, "예비비 사용 불가 (지방재정법 제43조제3항)"
    assert_includes reg, "별표 11은 일반예비비를 «법령에서 제한하는 경우를 제외하고 … 모든 사업으로 사용가능»"
    assert_equal 3, reg.scan("(실무 관행)").size
  end

  test "regulation 편성 한도·절차 조문이 법 제43조·시행령 제56조③ 원문과 맞는다" do
    migrate
    reg = Topic.find_by!(slug: "contingency-fund").regulation_content
    assert_not_includes reg, "1/100 이상"
    assert_not_includes reg, "2/100"
    assert_not_includes reg, "시행령 제59조"
    assert_includes reg, "| 일반예비비 | 재해·재난 등 예측 불가 경비 | 일반회계·교육비특별회계 예산 총액의 100분의 1 이내 (지방재정법 제43조제1항) |"
    assert_includes reg, "| 목적예비비 | 재해·재난 관련 목적 예비비 (지방재정법 제43조제2항) | 별도 계상 가능 · 편성 한도 없음 (예산편성 운영기준 별표 11 편성목 801) |"
    assert_includes reg, "#### 예비비 사용 절차 (지방재정법 제43조 및 시행령 제56조제3항)"
    assert_not_includes reg, "시행령 제48조"
    assert_not_includes reg, "다음 정기의회"
    assert_includes reg, "6. **사후 보고**: 「지방자치단체의 장은 예비비로 사용한 금액의 명세서를 「지방자치법」 제150조제1항에 따라 지방의회의 승인을 받아야 한다」(지방재정법 제43조제4항)"

    g = Guide.find_by!(slug: "budget-execution-complete-7")
    guide = g.sections.to_json
    assert_not_includes guide, "하나라도 빠지면 불가"
    assert_not_includes guide, "모두 충족"
    assert_includes guide, "법령 요건①: 예측 불가능성 — 「예측할 수 없는 예산 외의 지출 또는 예산 초과 지출」에 충당 (지방재정법 제43조제1항)"
    assert_includes guide, "실무 검토 요건②: 긴급성"
    assert_includes guide, "실무 검토 요건③: 불가피성"
    assert_equal OLD_GUIDE_SECTIONS["step3"], g.sections["step3"]
    assert_equal 77, g.view_count
  end

  test "가이드 값이 예상과 다르면 토픽 정정까지 전부 롤백한다" do
    Guide.find_by!(slug: "budget-execution-complete-7").update_columns(sections: { "step2" => { "title" => "다른 값", "items" => [] } })
    assert_raises(RuntimeError) { migrate }
    assert_includes Topic.find_by!(slug: "contingency-fund").regulation_content, "행안부 지침"
  end

  test "seed 원본에도 오인용이 없다" do
    %w[db/seeds/topic_faqs_backfill_2026_06_03_batch5.rb db/seeds/topic_quick_stats_backfill_2026_06_03_batch1.rb].each do |path|
      src = Rails.root.join(path).read
      assert_not_includes src, "지방재정법 시행령 제65조", path
      assert_not_includes src, "신규 사업 추진이나", path
      assert_not_includes src, "목적적합 모두 충족", path
      assert_includes src, "지방재정법 제43조제1항", path
    end
    assert_not_includes Rails.root.join("db/seeds/budget_execution_part2.rb").read, "하나라도 빠지면 불가"
    assert_includes Rails.root.join("db/seeds/topics/contingency_fund.rb").read, "법령상 금지 조항은 없으나 실무상 추경 대상"
  end
end
