# frozen_string_literal: true

require "test_helper"

# 완전정복 예산집행 4·5·6·7·8·10편 · 예산편성 2·5·7·8·10편 위험 주장 정정 (2026-09-29 R-budget) 회귀.
# 운영 모양 = 시드(정정 후)에서 edits·laws 를 거꾸로 되돌린 상태. 마이그레이션 결과가 시드와 같아야 한다(시드·운영 동기).
class GuideRiskBudgetTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929050000_guide_risk_budget.rb")
  LAWS, EDITS = eval(MIGRATION.read.split("\ncount_in = lambda").first + "\n[laws, edits]") # rubocop:disable Security/Eval
  SLUGS = (LAWS.keys + EDITS.map(&:first)).uniq.freeze

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
      sections = @expected[slug]["sections"]
      sections = sections.merge("laws" => LAWS[slug][0]) if LAWS.key?(slug)
      Guide.find_by!(slug: slug).update_columns(sections: revert(sections, slug, "sections"),
                                                rich_media: revert(@expected[slug]["rich_media"], slug, "rich_media"))
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

  STALE = {
    "budget-execution-complete-4" => [ "재무관이 확인해야 할 7가지", "지출관의 지휘를 받지 않습니다", "독립적 확인 권한", "재무관이 확인해야 할 사항의 구체적 범위", "집행기준 제4장" ],
    "budget-execution-complete-5" => [ "기금운용계획 집행지침" ],
    "budget-execution-complete-6" => [ "100만 원", "100만원", "89만", "내용연수 2년 이상", "운영기준 제4장" ],
    "budget-execution-complete-7" => [ "3요건", "세 가지 모두 충족", "법령상 금지", "금지②", "금지③", "금지⑤", "운영기준 제5장" ],
    "budget-execution-complete-8" => [ "세계잉여금으로 처리", "세계잉여금 처리", "계약 완료가 사고이월의 필수 요건", "사고이월 4가지 요건" ],
    "budget-execution-complete-10" => [ "→ 운영비. 자산취득비는 단가 100만", "단가 100만 원 이상 AND", "대체 불가능한 지출", "일반재원으로 편입" ],
    "budget-planning-complete-2" => [ "지방채 발행 제한 등", "교부세 감액, 지방채 발행 제한, 감사 지적" ],
    "budget-planning-complete-5" => [ "1년 이상", "봉급액의 0~50%", "5만~11만" ],
    "budget-planning-complete-7" => [ "2년 이상", "100만원", "설계비 요율표", "감정평가액 기준", "내구연한·단가" ],
    "budget-planning-complete-8" => [ "반드시 동일 금액" ],
    "budget-planning-complete-10" => [ "최대 150만", "반드시 동일 금액" ]
  }.freeze

  FRESH = {
    "budget-execution-complete-4" => [ "지방회계법 시행령 제33조", "회계관리에 관한 훈령 제4장(지출)", "지방회계법 제36조", "시행령 제46조" ],
    "budget-execution-complete-5" => [ "지방회계법 시행령 제33조" ],
    "budget-execution-complete-6" => [ "운영기준 405-01", "별표2 16-1", "G{정수·재물조사 대상?}", "운영기준 제6조·별표 9~11" ],
    "budget-execution-complete-7" => [ "지방재정법 제43조①", "실무 판단 기준", "법령상 명시적 금지 조항은 없음", "별표 11 편성목 801" ],
    "budget-execution-complete-8" => [ "지방회계법 제19조", "시행령 제16조", "제2~4호" ],
    "budget-execution-complete-10" => [ "지방회계관리훈령 별표2 16-1", "지방재정법 제43조①", "지방회계법 제19조" ],
    "budget-planning-complete-2" => [ "운영기준 제4조⑤", "지방교부세법 제11조②" ],
    "budget-planning-complete-5" => [ "10~50%", "5년 미만 3만 원 ~ 20년 이상 10만 원" ],
    "budget-planning-complete-7" => [ "정수·재물조사 대상", "엔지니어링사업대가의 기준", "운영기준 401-01" ],
    "budget-planning-complete-8" => [ "지방재정법 제22조②" ],
    "budget-planning-complete-10" => [ "250만 원", "160만 원", "제11조의2", "지방재정법 제22조②" ]
  }.freeze

  test "되돌린 상태가 실제로 옛 문구를 담고 있다(구 코드 = 실패 조건 재현)" do
    assert_includes body("budget-execution-complete-6"), "단가 100만원 이상?"
    assert_includes body("budget-execution-complete-7"), "3요건"
    assert_includes body("budget-planning-complete-10"), "최대 150만 원"
    assert_includes body("budget-execution-complete-4"), "집행기준 제4장"
    assert_includes body("budget-planning-complete-5"), "0~50%"
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

  test "POSITIVE/NEGATIVE: 새 근거 문구가 있고 틀린 수치·단정·장 번호는 없다" do
    migrate
    FRESH.each { |slug, list| list.each { |fresh| assert_includes body(slug), fresh, "#{slug}: #{fresh}" } }
    STALE.each { |slug, list| list.each { |stale| assert_not_includes body(slug), stale, "#{slug}: #{stale}" } }
    # 틀린 수치 대조군: 운영기준·별표 2 수치와 다른 값이 NEW 에 섞이지 않았다
    assert_not_includes body("budget-planning-complete-5"), "11만"
    assert_not_includes body("budget-planning-complete-10"), "150만"
    # 장 번호 인용 0: 운영기준은 제1~10조+별표뿐
    SLUGS.each do |slug|
      Guide.find_by!(slug: slug).sections[:laws].each do |l|
        assert_no_match(/운영기준 제\d+장|집행기준 제\d+장/, l[:name], "#{slug} #{l[:name]}")
        next if l[:checked_on].blank?

        assert l[:url].start_with?("https://www.law.go.kr/"), "#{slug} #{l[:url]}"
        assert l[:article].present? && l[:applies_to].present?, "#{slug} #{l[:name]}"
      end
    end
  end

  test "시드 원천(에피소드·비교표)에도 옛 문구가 남지 않는다" do
    STALE.each do |slug, list|
      seeded = @expected[slug].to_json
      list.each { |stale| assert_not_includes seeded, stale, "#{slug}: #{stale}" }
    end
    tables = Rails.root.join("db/seeds/add_comparison_tables.rb").read
    [ "단가 100만 원 이상 + 내용연수 2년", "태블릿PC 89만", "3요건(예측 불가·긴급·불가피)", "지출관의 지휘를 받지 않음",
      "사용 금지: 미리 알고 있던 사업, 인건비 보충", "내구연한 2년 이상 + 단가 100만 원" ].each do |stale|
      assert_not_includes tables, stale
    end
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_equal 69, LAWS.size + EDITS.size
    assert_match(/changes=69\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=69\b/, out)
    assert_match(%r{Guide/budget-execution-complete-6 fields_to_change=sections,rich_media}, out)
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "NEGATIVE: 한 편의 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    g = Guide.find_by!(slug: "budget-planning-complete-10")
    g.update_columns(sections: JSON.parse(g.read_attribute(:sections).to_json.gsub("최대 150만 원", "최대 160만 원")))
    untouched = body("budget-execution-complete-4")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("budget-execution-complete-4"), "한 편이 어긋났는데 다른 편은 써졌다 — 전체 롤백이 아니다"
  end
end
