# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/seeds/construction_contract_part1").to_s
require Rails.root.join("db/seeds/construction_contract_part2").to_s
require Rails.root.join("db/seeds/hr_welfare_part1").to_s
require Rails.root.join("db/seeds/hr_welfare_part2").to_s

# 공사계약·인사복무 완전정복 20편 출처 정정 (2026-09-29) 회귀.
# 교체 근거 = 독립 재판정(verified_contract_hr.md · verified_budget.md cc1 행). 원문 목록은 마이그레이션 머리말.
class GuideSourceClosureContractHrTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929020000_guide_source_closure_contract_hr.rb")
  SOURCE = MIGRATION.read
  EDITS = eval(SOURCE[/^edits = (\[.*?\n\])\.freeze/m, 1]).freeze # rubocop:disable Security/Eval
  LAWS_OLD = eval(SOURCE[/^laws_old = (\{.*?\n\})\.freeze/m, 1]).freeze # rubocop:disable Security/Eval
  LAWS_NEW = eval(SOURCE[/^laws_new = (\{.*?\n\})\.freeze/m, 1]).freeze # rubocop:disable Security/Eval
  EPISODES = (CONSTRUCTION_CONTRACT_EPISODES_PART1 + CONSTRUCTION_CONTRACT_EPISODES_PART2 +
              HR_WELFARE_EPISODES_PART1 + HR_WELFARE_EPISODES_PART2).freeze
  SEED_FILES = %w[construction_contract_part1 construction_contract_part2 hr_welfare_part1 hr_welfare_part2]
               .map { |f| Rails.root.join("db/seeds/#{f}.rb") }.freeze

  # 재판정이 틀렸다고 확인한 문구 — 시드·마이그레이션 결과 어디에도 남으면 안 된다.
  STALE = [
    "지방계약법 제2조 제1호", "지방계약법 시행령 제4조", "지방계약법 시행령 제9조", "지방계약법 시행규칙 제5조",
    "연면적 200㎡ 초과 건축공사, 총공사비 5억 원", "계약 금액의 10~20%", "감리 선정 의무 — 일정 규모",
    "기성금 지급 기한(14일)", "청구일로부터 14일 이내 지급", "7일~14일 이내 신청", "7~14일 이내 신청",
    "사유 종료 후 7일 이내", "공사계약 일반조건 제27조", "공사계약 일반조건 제26조", "공사계약 일반조건 제35조~제39조",
    "지방자치단체 공사계약 집행기준", "지방자치단체 계약 집행기준 제7장", "감사원법 제33조~제36조", "공사계약 일반조건 전반",
    "계속하여 7일 이상 병가", "11주 이하 5일", "공가 허용 사유 9가지", "공무상 재해로 인한 통원 치료 시간은 공가",
    "공무상 질병: 최대 3년", "공무상 질병휴직 최대 3년", "현금 지급 불가", "공무원연금법 제68조",
    "연 최대 700만 원", "감사원법 제34조", "§17의2", "연속 7일 이상 병가", "총공사비 10% 초과 증액", "의회 동의(또는",
    "30일 이내 계약서"
  ].freeze

  SLUGS = LAWS_NEW.keys.freeze

  # 운영과 같은 «적용 전» 상태 = 시드(적용 후와 동일)에 edit 를 역순으로 되돌리고 laws 를 옛 값으로.
  def before_state(episode)
    slug = episode[:slug]
    state = {
      "description" => episode[:description],
      "sections" => episode[:sections].deep_stringify_keys,
      "rich_media" => episode[:rich_media].deep_stringify_keys
    }
    mine = EDITS.select { |s, *| s == slug }
    mine.each_with_index.reverse_each do |(_, field, old, new, _), i|
      state[field] = if new == :delete
        # 지운 원소는 바로 다음 edit 의 old(이미 되돌려진 상태) 앞에 있었다
        restore_leaf(state[field], mine[i + 1][2], old)
      else
        replace_in(state[field], new, old)
      end
    end
    state["sections"] = state["sections"].merge("laws" => LAWS_OLD.fetch(slug))
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

  def restore_leaf(value, marker, leaf)
    case value
    when Array
      value.flat_map { |v| v == marker ? [ leaf, v ] : [ restore_leaf(v, marker, leaf) ] }
    when Hash then value.transform_values { |v| restore_leaf(v, marker, leaf) }
    else value
    end
  end

  setup do
    EPISODES.each do |ep|
      Guide.new(slug: ep[:slug], title: ep[:title], category: ep[:category], view_count: 7, **before_state(ep).symbolize_keys)
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

  test "EDGE: 적용 전(운영) 상태에는 틀린 문구가 있다 — 옛 코드는 회귀 검사에 실패한다" do
    all = SLUGS.map { |s| body(s) }.join
    STALE.each { |s| assert_includes all, s, "적용 전 상태에 없는 stale 문구: #{s}" }
  end

  test "NORMAL: 적용 후 20편이 시드와 같고 틀린 문구가 하나도 없다" do
    migrate
    EPISODES.each do |ep|
      g = Guide.find_by!(slug: ep[:slug])
      assert_equal ep[:description], g.description, ep[:slug]
      assert_equal ep[:sections].deep_stringify_keys, g.sections, ep[:slug]
      assert_equal ep[:rich_media].deep_stringify_keys, g.rich_media, ep[:slug]
    end
    all = SLUGS.map { |s| body(s) }.join
    STALE.each { |s| assert_not_includes all, s }
  end

  test "NORMAL: 새 조문 문자열(positive control)과 옛 조문 부재(negative control)" do
    migrate
    assert_includes body("construction-contract-complete-3"), "받은 날로부터 10일 이내에 계약서 서명"
    assert_includes body("construction-contract-complete-3"), "제8장 제3절 1-가"
    assert_includes body("construction-contract-complete-5"), "검사 완료 후 5일, 지방계약법 시행령 제67조④"
    assert_includes body("construction-contract-complete-7"), "집행기준 제9장 제8절 2-가"
    assert_includes body("construction-contract-complete-7"), "지방계약법 시행령 제75조의2"
    assert_includes body("construction-contract-complete-8"), "제9장 제11절"
    assert_includes body("construction-contract-complete-4"), "공사이행보증서(계약금액의 40%, 예정가격 70% 미만 낙찰 시 50%)"
    assert_includes body("construction-contract-complete-6"), "지방계약법 시행령 제74조③"
    assert_includes body("hr-welfare-complete-3"), "지방공무원 복무규정 제7조의5③"
    assert_includes body("hr-welfare-complete-3"), "15주 이내 10일, 16~21주 30일, 22~27주 60일, 28주 이상 90일"
    assert_includes body("hr-welfare-complete-4"), "총 13개 호 중 발췌"
    assert_includes body("hr-welfare-complete-5"), "2년 범위에서 연장 가능(최대 5년, 지방공무원법 제64조제1호 단서)"
    assert_includes body("hr-welfare-complete-6"), "지방공무원 보수규정 제18조"
    assert_includes body("hr-welfare-complete-8"), "소득세법 제51조의3"
    assert_includes body("hr-welfare-complete-9"), "감사원법 제31조·제32조"
    assert_includes body("hr-welfare-complete-10"), "지방공무원 복무규정 제7조의2⑥"
    # 진단서 기준은 «연 6일 초과» 하나뿐 — 연속 일수 기준이 조건으로 남으면 안 된다
    assert_not_includes body("hr-welfare-complete-3"), "두 조건 중 하나"
    assert_not_includes body("hr-welfare-complete-3"), "진단서 제출 기준 ①"
    assert_not_includes body("hr-welfare-complete-5"), "공무원수당규정 §11의3"
  end

  test "NORMAL: 근거 블록 — 모든 편에 1~3개 이상, url 은 law.go.kr 공식 링크, 필수 키와 확인일" do
    migrate
    SLUGS.each do |slug|
      laws = Guide.find_by!(slug: slug).sections["laws"]
      verified = laws.select { |l| l.key?("url") }
      assert verified.size.between?(1, 3), "#{slug}: 근거 블록 #{verified.size}개"
      verified.each do |law|
        assert_equal %w[applies_to article checked_on name text url], law.keys.sort, "#{slug}: #{law['name']}"
        assert_match %r{\Ahttps://www\.law\.go\.kr/(법령|행정규칙)/}, law["url"]
        assert_equal "2026-09-29", law["checked_on"]
      end
      assert_equal laws.map { |l| l["name"] }.uniq, laws.map { |l| l["name"] }, "#{slug}: 근거 이름 중복"
    end
  end

  test "UPPER_BOUND: 33개 필드가 한 번 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_match(/changes=33\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    assert_match(/DRY_RUN changes=33\b/, migrate("DRY_RUN" => "1"))
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "INVARIANT: slug·title·view_count 는 바뀌지 않는다" do
    before = Guide.where(slug: SLUGS).order(:slug).pluck(:slug, :title, :view_count)
    migrate
    assert_equal before, Guide.where(slug: SLUGS).order(:slug).pluck(:slug, :title, :view_count)
  end

  test "ROLLBACK: 근거 블록 지문이 어긋나면 한 편도 바꾸지 않는다" do
    g = Guide.find_by!(slug: "hr-welfare-complete-10")
    g.update_columns(sections: g.sections.merge("laws" => [ { "name" => "운영에서 달라진 값", "text" => "x" } ]))
    before = SLUGS.map { |s| body(s) }
    assert_raises(RuntimeError) { migrate }
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "ROLLBACK: 본문 지문이 없으면 한 편도 바꾸지 않는다" do
    g = Guide.find_by!(slug: "hr-welfare-complete-5")
    g.update_columns(sections: JSON.parse(g.sections.to_json.sub("공무상 질병: 최대 3년", "공무상 질병: 다른 문장")))
    before = SLUGS.map { |s| body(s) }
    assert_raises(RuntimeError) { migrate }
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "SEED: 시드 원천에도 틀린 문구가 없다" do
    text = SEED_FILES.map(&:read).join
    STALE.each { |s| assert_not_includes text, s }
  end
end
