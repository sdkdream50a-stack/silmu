require "test_helper"

SCHOOL_BUDGET_GUIDELINE_CORRECTION_LIBRARY_ONLY = true unless defined?(SCHOOL_BUDGET_GUIDELINE_CORRECTION_LIBRARY_ONLY)
load Rails.root.join("db/content_migrations/20261126090000_school_budget_guideline_dates.rb").to_s

# 2026-11-26 — 학교회계 예산편성 토픽에서 전국 공통 근거가 없는 지침 시달 고정 월(9월·10월)을 뺀다.
class SchoolBudgetGuidelineCorrectionTest < ActiveSupport::TestCase
  M = SchoolBudgetGuidelineCorrection20261126
  BEFORE = Rails.root.join("test/fixtures/files/school_budget_guideline_before")

  def before_value(field) = File.read(BEFORE.join("#{field}.md"), encoding: "UTF-8")

  def setup_topic
    topic = Topic.find_or_initialize_by(slug: M::SLUG)
    topic.name ||= M::SLUG
    M::GUARDS.each_key { |f| topic[f] = yield(f) }
    topic.save!(validate: false)
    topic
  end

  test "운영 원본(2026-11-26)이면 세 필드를 새 값으로 바꾼다" do
    topic = setup_topic { |f| before_value(f) }
    M.run!(dry_run: false)
    topic.reload
    M::GUARDS.each_key { |f| assert_equal M.value(f), topic[f], f }
  end

  test "새 값에는 고정 월 지침 일정이 없고 수령→변경 확인→편성 순서와 공문 확인 안내가 있다" do
    all = M::GUARDS.keys.map { |f| M.value(f) }.join("\n")
    assert_no_match(/(9월|10월)[^\n]{0,12}(지침|통보|시달)/, all)
    assert_no_match(/10~11월|10월~11월/, all)
    assert_includes M.value("flowchart_mermaid"), "지침 변경 내용 확인"
    assert_includes M.value("summary"), "소속 교육청 공문"
    assert_includes M.value("practical_tips"), "회계연도 시작 30일 전까지"
    assert_includes M.value("practical_tips"), "회계연도 시작 5일 전까지"
  end

  test "운영값이 가드와 다르면 아무것도 쓰지 않고 실패한다" do
    topic = setup_topic { |_f| "다른 사람이 고친 값" }
    error = assert_raises(RuntimeError) { M.run!(dry_run: false) }
    assert_match "아무것도 쓰지 않음", error.message
    assert_equal "다른 사람이 고친 값", topic.reload.summary
  end

  test "이미 새 값이면 변경 없이 통과한다(멱등)" do
    setup_topic { |f| M.value(f) }
    assert_empty M.run!(dry_run: false)
  end
end
