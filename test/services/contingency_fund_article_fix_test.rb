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

  setup do
    Topic.new(slug: "contingency-fund", name: "예비비", faqs: OLD_FAQS, quick_stats: OLD_QS, view_count: 321).save!(validate: false)
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def topic_text
    t = Topic.find_by!(slug: "contingency-fund")
    [ t.faqs.to_json, t.quick_stats.to_json ].join
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
    assert_includes t.faqs.last["answer"], "의회가 삭감한 사업에는 예비비를 사용할 수 없습니다."
  end

  test "DRY_RUN 은 쓰지 않는다 · 적용 2건 · 재실행 0건" do
    out = migrate("DRY_RUN" => "1")
    assert_includes out, "fields_to_change=faqs"
    assert_includes out, "fields_to_change=quick_stats"
    assert_includes out, "DRY_RUN changes=2"
    assert_includes topic_text, WRONG

    assert_includes migrate, "changes=2"
    assert_includes migrate, "changes=0"
  end

  test "운영 값이 예상과 다르면 전부 롤백한다" do
    Topic.find_by!(slug: "contingency-fund").update_columns(quick_stats: [ { "label" => "사용 요건", "note" => "다른 값" } ])
    assert_raises(RuntimeError) { migrate }
    assert_includes Topic.find_by!(slug: "contingency-fund").faqs.to_json, WRONG
  end

  test "seed 원본에도 오인용이 없다" do
    %w[db/seeds/topic_faqs_backfill_2026_06_03_batch5.rb db/seeds/topic_quick_stats_backfill_2026_06_03_batch1.rb].each do |path|
      src = Rails.root.join(path).read
      assert_not_includes src, "지방재정법 시행령 제65조", path
      assert_includes src, "지방재정법 제43조제1항", path
    end
  end
end
