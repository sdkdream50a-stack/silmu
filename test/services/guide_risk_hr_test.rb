# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/seeds/hr_welfare_part1").to_s
require Rails.root.join("db/seeds/hr_welfare_part2").to_s

# 인사복무 완전정복 2~10편 위험도 기반 잔여 주장 정정 (2026-09-29, series=hr) 회귀.
# 교체 근거 = R-hr/decisions.md(독립 재판정) + apply_extra.md(인접 항목 원문 대조). 원문 목록은 마이그레이션 머리말.
class GuideRiskHrTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929070000_guide_risk_hr.rb")
  EDITS = eval(MIGRATION.read[/^edits = (\[.*?\n\])\.freeze/m, 1]).freeze # rubocop:disable Security/Eval
  SLUGS = EDITS.map(&:first).uniq.freeze
  EPISODES = (HR_WELFARE_EPISODES_PART1 + HR_WELFARE_EPISODES_PART2).select { |ep| SLUGS.include?(ep[:slug]) }.freeze
  SEED_FILES = %w[hr_welfare_part1 hr_welfare_part2].map { |f| Rails.root.join("db/seeds/#{f}.rb") }.freeze

  # 원문과 다르다고 확인한 문구 — 적용 후 9편과 시드 원천 어디에도 남으면 안 된다.
  STALE = [
    "배우자측 친가", "배우자·부모·자녀 사망: 5일", "사망 모두 5일", "형제자매·배우자 형제자매 사망: 1일", "역일(달력상)",
    "경조사 휴가 일수(5일)", "'조부모 사망은 3일'", "출산일로부터 120일", "가족 돌봄 특별휴가: 연간 20일", "연간 2일 이내",
    "1시간 미만이면 공제 없음", "1시간 미만이면 연가 공제 없음", "나머지 분 단위는 올림",
    "2년차는 무급", "2년차 무급", "이후 무급", "복직 30일 전", "만료 30일 전까지", "발령 전까지 복직 불가", "지역가입자로 전환",
    "시효(5년)", "30일 이내에 변동 신고", "30일 이내 신고 의무", "일할 계산 없이 전액",
    "연 240만 원 한도", "부정공제", "5월 종합소득세 신고 기간에 경정청구", "육아휴직 취소", "즉시 취소", "감봉~파면",
    "학위 취득·연수 목적으로 최대 3년", "임용월 20일"
  ].freeze

  # 운영과 같은 «적용 전» 상태 = 시드(적용 후와 같음)에 edit 를 역순으로 되돌린 값.
  def before_state(episode)
    state = { "sections" => episode[:sections].deep_stringify_keys, "rich_media" => episode[:rich_media].deep_stringify_keys }
    EDITS.select { |s, *| s == episode[:slug] }.reverse_each do |_, field, old, new|
      state[field] = replace_in(state[field], new, old)
    end
    state
  end

  def replace_in(value, from, to)
    case value
    when String then value.gsub(from) { to }
    when Array  then value.map { |v| replace_in(v, from, to) }
    when Hash   then value.transform_values { |v| replace_in(v, from, to) }
    else value
    end
  end

  setup do
    EPISODES.each do |ep|
      Guide.new(slug: ep[:slug], title: ep[:title], category: ep[:category], description: ep[:description], view_count: 7,
                **before_state(ep).symbolize_keys).save!(validate: false)
    end
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def body(slug)
    g = Guide.find_by!(slug: slug)
    [ g.description, g.sections.to_json, g.rich_media.to_json ].join
  end

  def all_bodies
    SLUGS.map { |s| body(s) }.join
  end

  test "EDGE: 적용 전(운영) 상태에는 틀린 문구가 있다 — 옛 상태는 회귀 검사에 실패한다" do
    STALE.each { |s| assert_includes all_bodies, s, "적용 전 상태에 없는 stale 문구: #{s}" }
  end

  test "NORMAL: 적용 후 9편이 시드와 같고 틀린 문구가 하나도 없다" do
    migrate
    EPISODES.each do |ep|
      g = Guide.find_by!(slug: ep[:slug])
      assert_equal ep[:sections].deep_stringify_keys, g.sections, ep[:slug]
      assert_equal ep[:rich_media].deep_stringify_keys, g.rich_media, ep[:slug]
    end
    STALE.each { |s| assert_not_includes all_bodies, s }
  end

  test "NORMAL: 원문 수치(positive control)는 들어가고 틀린 수치(negative control)는 없다" do
    migrate
    three = body("hr-welfare-complete-3")
    assert_includes three, "본인 및 배우자의 형제자매 사망: 3일 (지방공무원 복무규정 별표 1)"
    assert_includes three, "제7조의7제1항 단서"
    assert_includes three, "지방공무원 복무규정 제7조의8"
    assert_includes three, "가족돌봄휴가: 연간 10일 범위"
    assert_includes three, "제7조의7제9항제2호"
    assert_includes three, "출산 후 120일(다태아 150일) 이내, 3회(다태아 5회)"
    assert_not_includes three, "연간 20일"
    assert_not_includes three, "형제자매 사망: 1일"
    assert_includes body("hr-welfare-complete-4"), "누계 8시간을 연가 1일로 뺍니다(지방공무원 복무규정 제7조의2제6항)"
    five = body("hr-welfare-complete-5")
    assert_includes five, "1년 초과 2년 이하는 50% (지방공무원 보수규정 제27조제1항)"
    assert_includes five, "K[1년 이하 봉급 70% / 1년 초과~2년 50%]"
    assert_includes five, "N[만료 후 30일 이내 복귀 신고]"
    assert_includes five, "지방공무원법 제65조제3항"
    assert_includes five, "국민건강보험법 제6조제2항"
    assert_includes body("hr-welfare-complete-6"), "민법 제163조제1호(3년)"
    seven = body("hr-welfare-complete-7")
    assert_includes seven, "결근 1일마다 일액(월액 ÷ 그 달의 일수)을 감액"
    assert_includes seven, "지체 없이 부양가족신고서로 신고"
    eight = body("hr-welfare-complete-8")
    assert_includes eight, "연 300만 원 납입 한도 내 납입액의 40% 소득공제(최대 120만 원)"
    assert_not_includes eight, "240만"
    assert_includes eight, "법정신고기한부터 5년 이내에 경정청구"
    nine = body("hr-welfare-complete-9")
    assert_includes nine, "지방공무원 임용령 제38조의17"
    assert_includes nine, "견책~파면, 지방공무원 징계규칙 별표 1"
    ten = body("hr-welfare-complete-10")
    assert_includes ten, "1년 이내 사용 가능합니다(지방공무원법 제64조제10호)"
    assert_includes ten, "각각 6개월이 더해집니다(지방공무원 임용령 제34조제1항제2호)"
    assert_includes ten, "교육감이 임용권을 가진 지방공무원은 매월 17일입니다"
    assert_not_includes ten, "최대 3년 사용"
  end

  test "UPPER_BOUND: 16개 필드가 한 번 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_match(/changes=16\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    assert_match(/DRY_RUN changes=16\b/, migrate("DRY_RUN" => "1"))
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "INVARIANT: slug·title·description·view_count·laws 는 바뀌지 않는다" do
    snapshot = -> { Guide.where(slug: SLUGS).order(:slug).map { |g| [ g.slug, g.title, g.description, g.view_count, g.sections["laws"] ] } }
    before = snapshot.call
    migrate
    assert_equal before, snapshot.call
  end

  test "ROLLBACK: 운영 문구가 기대와 다르면(다른 수치) 한 편도 바꾸지 않는다" do
    g = Guide.find_by!(slug: "hr-welfare-complete-10")
    g.update_columns(sections: JSON.parse(g.sections.to_json.sub("견책은 6개월 동안", "견책은 3개월 동안")))
    before = SLUGS.map { |s| body(s) }
    assert_raises(RuntimeError) { migrate }
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "SEED: 시드 원천에도 틀린 문구가 없다" do
    text = SEED_FILES.map(&:read).join
    STALE.each { |s| assert_not_includes text, s }
  end
end
