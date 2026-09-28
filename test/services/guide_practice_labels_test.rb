# frozen_string_literal: true

require "test_helper"

# 2026-09-29 실무 가이드 4건 라벨 정정 회귀. 근거 없는 순위·의무 표현에 «실무 절차/예시» 라벨을 붙인다.
# 새 법적 주장·title/slug/description 변경은 없다. 머리말 근거는 마이그레이션 파일 참조.
class GuidePracticeLabelsTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929080000_guide_practice_labels.rb")

  OLD_BEC5_WHY = "선집행은 감사원 지적 1위 유형 중 하나입니다. '빨리 처리하려고', '예산 소진하려고', '업체가 요청해서' 등 다양한 이유로 발생하지만, 이유를 불문하고 위법입니다. 담당자 개인이 전액 변상 명령을 받은 사례도 있습니다."
  OLD_BEC7_STEP3_TITLE = "예비비 신청 절차 (5단계)"
  OLD_BEC8_STEP3_TITLE = "불용액 처리 절차 (5단계)"
  OLD_HRW9_STEP1_TITLE = "지적 사례 1~3위: 금전 관련 3대 유형"

  setup do
    Guide.new(slug: "budget-execution-complete-5", title: "선집행 금지 완전정복 — 왕초보 완전정복 5편", category: "예산",
              view_count: 11,
              sections: { "why_it_matters" => OLD_BEC5_WHY }).save!(validate: false)
    Guide.new(slug: "budget-execution-complete-7", title: "예비비 사용 완전정복 — 왕초보 완전정복 7편", category: "예산",
              view_count: 22,
              sections: { "step3" => { "title" => OLD_BEC7_STEP3_TITLE, "items" => [ "1단계: 사용 요건 검토" ] } }).save!(validate: false)
    Guide.new(slug: "budget-execution-complete-8", title: "예산 이월·불용 처리 실무 — 왕초보 완전정복 8편", category: "예산",
              view_count: 33,
              sections: { "step3" => { "title" => OLD_BEC8_STEP3_TITLE, "items" => [ "1단계: 연도 말 집행 잔액 확인" ] } }).save!(validate: false)
    Guide.new(slug: "hr-welfare-complete-9", title: "인사·복무 감사 지적 사례 TOP 10 — 왕초보 완전정복 9편", category: "복무",
              view_count: 44,
              sections: { "step1" => { "title" => OLD_HRW9_STEP1_TITLE, "body" => "1위. 수당 이중지급" } }).save!(validate: false)
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def sections_text(slug)
    Guide.find_by!(slug: slug).sections.to_json
  end

  test "옛 값이 있다 (대조군)" do
    assert_includes sections_text("budget-execution-complete-5"), "감사원 지적 1위 유형"
    assert_includes sections_text("budget-execution-complete-7"), OLD_BEC7_STEP3_TITLE
    assert_includes sections_text("budget-execution-complete-8"), OLD_BEC8_STEP3_TITLE
    assert_includes sections_text("hr-welfare-complete-9"), OLD_HRW9_STEP1_TITLE
  end

  test "4건 모두 라벨이 붙고 옛 문구는 사라진다 · slug·title·view_count 불변" do
    migrate

    bec5 = Guide.find_by!(slug: "budget-execution-complete-5")
    assert_not_includes bec5.sections["why_it_matters"], "감사원 지적 1위 유형"
    assert_includes bec5.sections["why_it_matters"], "선집행은 감사에서 자주 지적되는 유형입니다"
    assert_includes bec5.sections["why_it_matters"], "'빨리 처리하려고'"

    bec7 = Guide.find_by!(slug: "budget-execution-complete-7")
    assert_equal "예비비 신청 절차 (5단계 · 실무 절차 — 기관별 상이)", bec7.sections["step3"]["title"]

    bec8 = Guide.find_by!(slug: "budget-execution-complete-8")
    assert_equal "불용액 처리 절차 (5단계) (실무 절차 — 기관별 상이)", bec8.sections["step3"]["title"]

    hrw9 = Guide.find_by!(slug: "hr-welfare-complete-9")
    assert_equal "지적 사례 1~3위: 금전 관련 3대 유형 (순위는 실무 경험에 따른 예시이며 공식 통계가 아님)", hrw9.sections["step1"]["title"]
    assert_includes hrw9.sections["step1"]["title"], "1~3위" # 순번 유지 — 재배열 없음

    [ [ "budget-execution-complete-5", "선집행 금지 완전정복 — 왕초보 완전정복 5편", 11 ],
      [ "budget-execution-complete-7", "예비비 사용 완전정복 — 왕초보 완전정복 7편", 22 ],
      [ "budget-execution-complete-8", "예산 이월·불용 처리 실무 — 왕초보 완전정복 8편", 33 ],
      [ "hr-welfare-complete-9", "인사·복무 감사 지적 사례 TOP 10 — 왕초보 완전정복 9편", 44 ] ].each do |slug, title, view_count|
      g = Guide.find_by!(slug: slug)
      assert_equal title, g.title
      assert_equal view_count, g.view_count
    end
  end

  test "DRY_RUN 은 쓰지 않는다 · 적용 4건 · 재실행 0건" do
    out = migrate("DRY_RUN" => "1")
    assert_includes out, "Guide/budget-execution-complete-5 fields_to_change=sections"
    assert_includes out, "Guide/budget-execution-complete-7 fields_to_change=sections"
    assert_includes out, "Guide/budget-execution-complete-8 fields_to_change=sections"
    assert_includes out, "Guide/hr-welfare-complete-9 fields_to_change=sections"
    assert_includes out, "DRY_RUN changes=4"
    assert_includes sections_text("budget-execution-complete-5"), "감사원 지적 1위 유형"

    assert_includes migrate, "changes=4"
    assert_includes migrate, "changes=0"
  end

  test "운영 값이 예상과 다르면 전부 롤백한다" do
    Guide.find_by!(slug: "hr-welfare-complete-9").update_columns(sections: { "step1" => { "title" => "다른 값" } })
    assert_raises(RuntimeError) { migrate }
    assert_includes sections_text("budget-execution-complete-5"), "감사원 지적 1위 유형"
    assert_includes sections_text("budget-execution-complete-7"), OLD_BEC7_STEP3_TITLE
  end

  test "롤백: new → old 역적용하면 옛 값으로 돌아간다" do
    migrate
    g = Guide.find_by!(slug: "budget-execution-complete-7")
    assert_not_includes sections_text("budget-execution-complete-7"), "감사원"
    reverted = g.sections.to_json.sub("예비비 신청 절차 (5단계 · 실무 절차 — 기관별 상이)", OLD_BEC7_STEP3_TITLE)
    g.update_columns(sections: JSON.parse(reverted))
    assert_equal OLD_BEC7_STEP3_TITLE, Guide.find_by!(slug: "budget-execution-complete-7").sections["step3"]["title"]
  end

  test "seed 원본에 옛 문구가 없고 새 라벨이 있다" do
    part1 = Rails.root.join("db/seeds/budget_execution_part1.rb").read
    assert_not_includes part1, "감사원 지적 1위 유형"
    assert_includes part1, "선집행은 감사에서 자주 지적되는 유형입니다"

    part2 = Rails.root.join("db/seeds/budget_execution_part2.rb").read
    assert_not_includes part2, "title: \"#{OLD_BEC7_STEP3_TITLE}\""
    assert_includes part2, "예비비 신청 절차 (5단계 · 실무 절차 — 기관별 상이)"
    assert_not_includes part2, "title: \"#{OLD_BEC8_STEP3_TITLE}\""
    assert_includes part2, "불용액 처리 절차 (5단계) (실무 절차 — 기관별 상이)"

    hrw = Rails.root.join("db/seeds/hr_welfare_part2.rb").read
    assert_not_includes hrw, "title: \"#{OLD_HRW9_STEP1_TITLE}\""
    assert_includes hrw, "지적 사례 1~3위: 금전 관련 3대 유형 (순위는 실무 경험에 따른 예시이며 공식 통계가 아님)"
  end
end
