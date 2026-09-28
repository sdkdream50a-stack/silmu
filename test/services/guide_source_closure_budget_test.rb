# frozen_string_literal: true

require "test_helper"

# 완전정복 예산집행 2~10편·예산편성 1~10편 출처 정정 (2026-09-29) 회귀.
# 운영 모양 = 시드(정정 후)에서 edits·laws 를 거꾸로 되돌린 상태. 마이그레이션 결과가 시드와 같아야 한다(시드·운영 동기).
class GuideSourceClosureBudgetTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929010000_guide_source_closure_budget.rb")
  LAWS, EDITS = eval(MIGRATION.read.split("\ncount_in = lambda").first + "\n[laws, edits]") # rubocop:disable Security/Eval
  SLUGS = LAWS.keys.freeze
  BPC7_TABLE = Rails.root.join("db/seeds/add_comparison_tables.rb").read[/slug: "budget-planning-complete-7".*?\n  \},/m].freeze

  setup do
    capture_io do
      load Rails.root.join("db/seeds/budget_execution_series.rb")
      load Rails.root.join("db/seeds/budget_planning_series.rb")
    end
    @expected = SLUGS.to_h do |slug|
      g = Guide.find_by!(slug: slug)
      rm = g.rich_media.deep_stringify_keys.slice("flowchart", "flashcards") # 운영엔 comparison_table 이 없다
      [ slug, { "sections" => g.read_attribute(:sections).deep_stringify_keys, "rich_media" => rm,
                "title" => g.title, "view_count" => g.view_count } ]
    end
    SLUGS.each do |slug|
      sections = revert(@expected[slug]["sections"].merge("laws" => LAWS[slug][0]), slug, "sections")
      rich_media = revert(@expected[slug]["rich_media"], slug, "rich_media")
      Guide.find_by!(slug: slug).update_columns(sections: sections, rich_media: rich_media)
    end
  end

  def revert(value, slug, field)
    EDITS.select { |s, f, _, _| s == slug && f == field }.reverse.each do |_, _, old, new|
      value = JSON.parse(value.to_json.gsub(new.to_json[1..-2]) { old.to_json[1..-2] })
    end
    value
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def body(slug)
    g = Guide.find_by!(slug: slug)
    [ g.read_attribute(:sections).to_json, g.rich_media.to_json ].join
  end

  test "되돌린 상태가 실제로 옛 문구를 담고 있다(구 코드 = 실패 조건 재현)" do
    assert_includes body("budget-planning-complete-7"), "시설비(301목)"
    assert_includes body("budget-planning-complete-5"), "2만원(첫째)"
    assert_includes body("budget-execution-complete-5"), "인건비 등"
  end

  test "NORMAL: 마이그레이션 결과가 정정된 시드와 같고 title·slug·view_count 는 그대로다" do
    migrate
    SLUGS.each do |slug|
      g = Guide.find_by!(slug: slug)
      assert_equal @expected[slug]["sections"], g.read_attribute(:sections).deep_stringify_keys, "#{slug} sections"
      assert_equal @expected[slug]["rich_media"], g.rich_media.deep_stringify_keys.slice("flowchart", "flashcards"), "#{slug} rich_media"
      assert_equal @expected[slug]["title"], g.title
      assert_equal @expected[slug]["view_count"], g.view_count
    end
  end

  test "POSITIVE/NEGATIVE: 새 근거 문구가 있고 틀린 인용은 없다" do
    migrate
    assert_includes body("budget-planning-complete-7"), "시설비(401목 시설비 및 부대비)"
    assert_includes body("budget-planning-complete-7"), "지방재정법 시행령 제41조"
    assert_not_includes body("budget-planning-complete-7"), "301목"
    assert_not_includes body("budget-planning-complete-7"), "303목"
    assert_not_includes body("budget-planning-complete-7"), "50~500억"
    assert_not_includes body("budget-planning-complete-7"), "물품관리법 제6조"
    assert_includes body("budget-planning-complete-5"), "첫째 월 5만원·둘째 월 8만원"
    assert_not_includes body("budget-planning-complete-5"), "2만원(첫째)"
    assert_not_includes body("budget-planning-complete-4"), "세항"
    assert_includes body("budget-planning-complete-4"), "분야·부문·정책사업·단위사업·세부사업·목"
    assert_not_includes body("budget-execution-complete-5"), "인건비 등"
    assert_not_includes body("budget-execution-complete-5"), "선금지급요령"
    assert_includes body("budget-execution-complete-5"), "지방재정법 시행령 제57조"
    assert_includes body("budget-planning-complete-1"), "지방재정법 제7조"
    assert_not_includes body("budget-planning-complete-1"), "\"지방회계법 제6조\""
    assert_includes body("budget-planning-complete-3"), "지방재정법 시행령 제47조제1항"
    assert_not_includes body("budget-planning-complete-3"), "지방재정법 제27조"
    assert_includes body("budget-planning-complete-8"), "지방재정법 제22조"
    assert_not_includes body("budget-planning-complete-8"), "지방재정법 제23조"
    assert_includes body("budget-planning-complete-8"), "기획예산처" # 재판정 OVERTURNED — 그대로 둔다
    assert_not_includes body("budget-planning-complete-9"), "50억·500억"
    assert_not_includes body("budget-planning-complete-10"), "민간이전(401목)"
    assert_not_includes body("budget-planning-complete-10"), "자산취득비(303목)"
    SLUGS.each do |slug|
      laws = Guide.find_by!(slug: slug).sections[:laws]
      full = laws.select { |l| l[:checked_on].present? }
      assert full.any?, "#{slug} 에 근거 블록(checked_on)이 없다"
      full.each do |l|
        assert_equal "2026-09-29", l[:checked_on]
        assert l[:url].start_with?("https://www.law.go.kr/"), "#{slug} #{l[:url]}"
        assert l[:article].present? && l[:applies_to].present?, "#{slug} #{l[:name]}"
      end
    end
  end

  test "시드 원천(19편 에피소드·7편 비교표)에도 틀린 문구가 남지 않는다" do
    seeded = @expected.to_json
    [ "자산취득비(303목)", "(303목)", "2만원(첫째)", "(인건비 등)", "지방자치단체 선금지급요령",
      "장·관·항·세항·목", "50~500억", "분리 발주 원칙", "물품관리법 제6조",
      "\"지방재정법 제23조\"", "\"지방재정법 제27조\"", "\"지방회계법 제6조\"" ].each do |stale|
      assert_not_includes seeded, stale
    end
    # 4·6편의 목 코드(301·401 등)는 재판정 범위 밖이라 DEFERRED — 7·10편만 본다.
    %w[budget-planning-complete-7 budget-planning-complete-10].each do |slug|
      assert_not_includes @expected[slug].to_json, "시설비(301목)"
      assert_not_includes @expected[slug].to_json, "민간이전(401목)"
    end
    assert BPC7_TABLE.present?
    [ "301목", "303목", "50억 이상: 지방투자심사", "반드시 분리 발주", "물품관리법 절차", "건설기술진흥법 위반" ].each do |stale|
      assert_not_includes BPC7_TABLE, stale
    end
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_match(/changes=#{LAWS.size + EDITS.size}\b/, migrate)
    assert_equal 77, LAWS.size + EDITS.size
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=77\b/, out)
    assert_match(%r{Guide/budget-planning-complete-7 fields_to_change=sections,rich_media}, out)
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "NEGATIVE: 한 편의 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    g = Guide.find_by!(slug: "budget-planning-complete-10")
    g.update_columns(sections: g.read_attribute(:sections).merge("laws" => [ { "name" => "다른 사람이 고친 법령" } ]))
    untouched = body("budget-execution-complete-2")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("budget-execution-complete-2"), "한 편이 어긋났는데 다른 편은 써졌다 — 전체 롤백이 아니다"
  end
end
