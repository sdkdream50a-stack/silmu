# frozen_string_literal: true

require "test_helper"

# 인사·복무 1·2·6·7편 지방공무원 기준 전환 (2026-09-27) 회귀.
# 원문: 지방공무원법 · 지방공무원 복무규정 · 지방공무원 보수규정 · 지방공무원 수당 등에 관한 규정 (마이그레이션 머리말 참조).
class HrGuidesLocalBasisTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260927120000_hr_guides_local_civil_servant_basis.rb")
  Guide # autoload — 아래 eval 이 상수 Guide 를 참조한다
  EDITS = eval(MIGRATION.read[/edits = (\[.*?\])\.freeze/m, 1]).freeze # rubocop:disable Security/Eval
  SLUGS = EDITS.map { |_, slug, _, _, _| slug }.uniq.freeze

  # 운영과 같은 모양: jsonb 는 old 를 문자열 leaf 로, description 은 old 를 이어 붙인다.
  # 같은 필드 안에서 다른 old 의 부분 문자열인 old(단계 제목 «연가 사용 제한 사유» 등)는 앞 edit 이 바뀐 뒤에만 1회가 된다.
  setup do
    SLUGS.each do |slug|
      rows = EDITS.select { |_, s, _, _, _| s == slug }
      olds = ->(field) { rows.select { |_, _, f, _, _| f == field }.map { |row| row[3] } }
      Guide.new(slug: slug, title: slug, category: "복무",
                description: olds.call("description").join(" / ").presence || slug,
                sections: { "items" => olds.call("sections") },
                rich_media: { "flashcards" => olds.call("rich_media").map { |o| { "front" => o, "back" => "유지" } } })
           .save!(validate: false)
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

  test "NORMAL: 네 편에서 국가공무원 규정 인용이 사라지고 지방공무원 규정이 들어간다" do
    migrate
    SLUGS.each do |slug|
      text = body(slug)
      refute_match(/국가공무원|공무원임용령|(?<!지방)공무원보수규정 제|(?<!지방)공무원수당 등에 관한 규정|인사혁신처/, text, "#{slug} 에 국가공무원 기준이 남았다")
    end
    assert_includes body("hr-welfare-complete-2"), "지방공무원 복무규정 제7조의10"
    # 학교행정실 독자 기준: 교육감 임용 지방공무원 = 별표 30 교육부 17일. «20일» 만 보이면 틀리게 읽힌다(2026-09-27 재검증).
    assert_includes body("hr-welfare-complete-6"), "학교·교육청 소속처럼 교육감이 임용권을 가진 지방공무원은 매월 17일"
    assert_includes body("hr-welfare-complete-6"), "그 밖의 지방공무원은 매월 20일"
    assert_not_includes body("hr-welfare-complete-6"), "지방 20일·교육청 소속은 교육부 지급일"
    assert_includes body("hr-welfare-complete-7"), "2021. 1. 5. 삭제"
    # 독립 법령검증(2026-09-27) 지적: 지방 보수규정에는 봉급표가 없다 — 제4조제3항이 공무원보수규정 별표 3 을 준용한다.
    assert_includes body("hr-welfare-complete-6"), "「공무원보수규정」 별표 3(일반직)을 준용"
    assert_not_includes body("hr-welfare-complete-6"), "「지방공무원 보수규정」 별표에 있고"
    # 삭제된 제7조의10제2항은 «일수 상한» 이 아니라 «10년 내 미사용 소멸» 이었다.
    assert_includes body("hr-welfare-complete-2"), "10년 안에 쓰지 않으면 소멸하던"
    assert_not_includes body("hr-welfare-complete-2"), "저축 일수 상한을 두던"
    # 연가일수 표 = 지방공무원 복무규정 §7① 2024. 7. 2. 개정 6단계(11·15·16·17·20·21). 옛 12·14일 구간이 남으면 안 된다.
    assert_includes body("hr-welfare-complete-2"), "1년 이상 3년 미만: 15일"
    assert_includes body("hr-welfare-complete-2"), "3년 이상 4년 미만: 16일"
    assert_not_includes body("hr-welfare-complete-2"), ": 12일"
    assert_not_includes body("hr-welfare-complete-2"), ": 14일"
  end

  test "EDGE: 지방공무원 규정과 다른 옛 수치(저축 30일·2년 소멸·일할 계산·S 20/30/50)가 남지 않는다" do
    migrate
    assert_not_includes body("hr-welfare-complete-2"), "최대 30일"
    assert_not_includes body("hr-welfare-complete-2"), "2년 이내"
    assert_not_includes body("hr-welfare-complete-2"), "연간 최대 6일"
    assert_not_includes body("hr-welfare-complete-6"), "1~2호봉"
    assert_not_includes body("hr-welfare-complete-7"), "일할 계산하여 지급"
    assert_not_includes body("hr-welfare-complete-7"), "차상위 30%"
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_match(/changes=#{EDITS.size}\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = body("hr-welfare-complete-7")
    assert_match(/DRY_RUN changes=#{EDITS.size}\b/, migrate("DRY_RUN" => "1"))
    assert_equal before, body("hr-welfare-complete-7")
  end

  test "NEGATIVE: 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    g = Guide.find_by!(slug: "hr-welfare-complete-6")
    g.update_columns(sections: { "items" => [ "다른 사람이 이미 고친 문장" ] })
    untouched = body("hr-welfare-complete-1")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("hr-welfare-complete-1"), "한 편이 어긋났는데 다른 편은 써졌다 — 전체 롤백이 아니다"
  end
end
