# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/seeds/construction_contract_part1").to_s
require Rails.root.join("db/seeds/construction_contract_part2").to_s

# 공사계약 완전정복 1~10편 고위험 잔여 주장 정정 (2026-09-29 · risk contract) 회귀.
# 근거 = 독립 재판정 R-contract/decisions.md + 인접 항목 apply_extra.md. 원문 목록은 마이그레이션 머리말.
class GuideRiskContractTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929060000_guide_risk_contract.rb")
  EDITS = eval(MIGRATION.read[/^edits = (\[.*?\n\])\.freeze/m, 1]).freeze # rubocop:disable Security/Eval
  EPISODES = (CONSTRUCTION_CONTRACT_EPISODES_PART1 + CONSTRUCTION_CONTRACT_EPISODES_PART2).freeze
  SLUGS = EDITS.map(&:first).uniq.freeze
  SEED_FILES = %w[construction_contract_part1 construction_contract_part2 add_comparison_tables]
               .map { |f| Rails.root.join("db/seeds/#{f}.rb") }.freeze

  # 재판정이 틀렸다고 확인한 문구 — 적용 후 어디에도 남으면 안 된다(적용 전 운영에는 모두 있다).
  STALE = [
    "천재지변으로 연장된 경우에도 간접비는 청구할 수 없습니다", "(천재지변·시공사 귀책은 해당 없음)",
    "불가항력(천재지변 등)이면 연장만", "D[연장 승인, 간접비 청구 불가]", "불가항력: 연장만",
    "천재지변이나 시공사 귀책은 청구 불가", "발주처 귀책 공기 연장 시 해당", "I[천재지변 간접비 청구 불가]",
    "천재지변은 양측 추가 비용 없음", "천재지변은 불가항력이므로 양쪽 모두 추가 비용 부담 없음",
    "10억 원 이상: 일반경쟁입찰 의무", "M[일반경쟁 의무]", "준공 후 최소 1년", "최소 1년(준공 후)",
    "종합심사낙찰제 또는 적격심사제 의무",
    "누설 시 담당자 형사처벌 대상", "해당 계약 무효 처리 가능", "(유출 시 계약 무효)", "사전 누설은 형사처벌 대상",
    "10억 원 이상 공사는 나라장터(G2B) 의무 공고", "D[나라장터 의무 공고]", "E[자체 공고 가능]",
    "추정가격 1억 원 이상 공사", "1억 원 이상 의무", "G{1억 원 이상?}", "원칙적으로 현장설명 불참 업체는 입찰 참가 불가",
    "해당 입찰이 무효 처리될 수 있습니다", "현장설명 의무 대상(1억 원 이상)",
    "건축법 위반으로 이행강제금", "이행강제금과 공사 중지 명령이 동시에", "계약 금액의 3~5%",
    "기성 실적 및 자금 계획 검토 후 지급",
    "공사계약 일반조건 제19조", "일방 설계변경", "시공을 강요하는 것은 위법", "공사 중지 → 분쟁조정위원회",
    "정부 공식 선포 기간 한정", "예상 불가능한 장애", "시방서에 명시된 기상 기준(영하 몇 도 이하",
    "개산 청구 불인정", "개산(어림 청구) 불인정", "설계변경을 통해 계약금액에 반영", "M[설계변경으로 계약금액 반영]",
    "(건축·토목·전기·통신·소방 등 공종별 동일)", "전문공사·설비공사: 계약금액의 2%", "일반공사 3%)",
    "철근콘크리트, 철골 등 주요 구조부): 10년", "설비(급·배수, 냉난방, 환기 등): 2~3년", "전기·통신·소방 설비: 2년",
    "가장 긴 기간이 보증금 유효 기간", "구조부 10년, 설비 2~3년", "계약금액의 3%. 현금",
    "10년. 철근콘크리트·철골", "(급·배수·냉난방 2~3년, 전기·통신·소방 2년)",
    "계약 관련 서류 준공 후 10년 보존", "준공 후 10년 보존이 필요", "준공 후 10년. 하자담보",
    "종합심사", "가격(60%) + 공사수행능력(40%)", "10억 원 미만 공사에 주로 적용", "현재는 사실상 폐지",
    "국가계약분쟁조정위원회", "지방계약분쟁조정위원회"
  ].freeze

  # 운영과 같은 «적용 전» 상태 = 시드(적용 후와 동일)에 edit 를 역순으로 되돌린다.
  def before_state(episode)
    state = {
      "description" => episode[:description],
      "sections" => episode[:sections].deep_stringify_keys,
      "rich_media" => episode[:rich_media].deep_stringify_keys
    }
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

  def all_bodies = SLUGS.map { |s| body(s) }.join

  test "EDGE: 적용 전(운영) 상태에는 틀린 문구가 모두 있다 — 옛 상태는 회귀 검사에 실패한다" do
    STALE.each { |s| assert_includes all_bodies, s, "적용 전 상태에 없는 stale 문구: #{s}" }
  end

  test "NORMAL: 적용 후 10편이 시드와 같고 틀린 문구가 하나도 없다" do
    migrate
    EPISODES.each do |ep|
      g = Guide.find_by!(slug: ep[:slug])
      assert_equal ep[:description], g.description, ep[:slug]
      assert_equal ep[:sections].deep_stringify_keys, g.sections, ep[:slug]
      assert_equal ep[:rich_media].deep_stringify_keys, g.rich_media, ep[:slug]
    end
    STALE.each { |s| assert_not_includes all_bodies, s }
  end

  test "NORMAL: 천재지변 간접비 — 7곳+10편 반복 모두 원문(법 제22조②·집행기준 제9장 제8절 2-라) 방향으로" do
    migrate
    cc7 = body("construction-contract-complete-7")
    assert_includes cc7, "천재지변·감염병 등 불가항력으로 계약기간을 연장한 경우에도 실비 범위에서 계약금액을 조정해야 함"
    assert_includes cc7, "D[연장 승인 + 실비 조정 · 법 제22조②]"
    assert_includes cc7, "발주처 책임·불가항력: 연장+실비 조정"
    assert_includes cc7, "부도 보증시공 연장·시공사 귀책"
    assert_equal 4, cc7.scan("제22조②").size
    cc10 = body("construction-contract-complete-10")
    assert_includes cc10, "→ 네, 실비 범위에서 계약금액을 조정합니다."
    assert_includes cc10, "I[불가항력 연장도 실비 조정]"
    # negative control — «청구 불가»·«연장만» 은 어떤 편에도 남지 않는다
    [ cc7, cc10 ].each do |b|
      assert_no_match(/천재지변[^.。]{0,20}(청구 불가|청구할 수 없|추가 비용 (부담 )?없)/, b)
      assert_no_match(/(불가항력|천재지변)[^.]{0,12}연장만(?! 제외)/, b)
    end
  end

  test "NORMAL: 새 수치·조문(positive)과 틀린 수치(negative control)" do
    migrate
    cc1 = body("construction-contract-complete-1")
    assert_includes cc1, "시행령 제20조①1호"
    assert_includes cc1, "제42조의3"
    assert_not_includes cc1, "N[종합심사낙찰제]"
    assert_includes cc1, "공종별 1년 이상 10년 이하"
    cc3 = body("construction-contract-complete-3")
    assert_includes cc3, "10억 원 미만 7일·10억~50억 원 미만 15일·50억 원~고시금액 미만 30일·고시금액 이상 40일"
    assert_includes cc3, "추정가격 300억 원 이상 공사에서 현장설명을 한 경우"
    assert_not_includes cc3, "1억 원 이상"
    cc4 = body("construction-contract-complete-4")
    assert_includes cc4, "5천만원 이하 벌금"
    assert_includes cc4, "공종별 계약금액의 2~5%"
    assert_not_includes cc4, "3~5%"
    cc8 = body("construction-contract-complete-8")
    assert_includes cc8, "중요 구조물공사와 조경공사: 5%"
    assert_includes cc8, "그 밖의 구조상 주요부분 5년"
    assert_includes cc8, "주된 공사의 종류를 기준"
    assert_not_includes cc8, "공종별 동일"
    assert_includes body("construction-contract-complete-5"), "최초 지급 시 30%까지는 의무 지급"
    assert_includes body("construction-contract-complete-6"), "제9장 제6절 5-가"
    assert_includes body("construction-contract-complete-6"), "제34조의2"
    assert_includes body("construction-contract-complete-7"), "집행기준 제1장 제8절 1·2"
    assert_includes body("construction-contract-complete-9"), "공공기록물법 시행령 제26조"
    assert_includes body("construction-contract-complete-2"), "형법 제127조"
  end

  test "NORMAL: 흐름도 새 라벨은 Mermaid 대괄호 라벨 안에 괄호를 넣지 않는다" do
    migrate
    SLUGS.each do |slug|
      chart = Guide.find_by!(slug: slug).rich_media["flowchart"].to_s
      chart.scan(/\w\[([^\]]*)\]/).flatten.each { |label| assert_no_match(/[()]/, label, "#{slug}: #{label}") }
    end
  end

  test "UPPER_BOUND: 88개 edit 가 한 번 적용되고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_match(/changes=88\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    assert_match(/DRY_RUN changes=88\b/, migrate("DRY_RUN" => "1"))
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "INVARIANT: slug·title·view_count 불변 · description 은 3편 사실 오류 1건만 바뀐다" do
    before = Guide.where(slug: SLUGS).order(:slug).pluck(:slug, :title, :view_count)
    descriptions = Guide.where(slug: SLUGS).order(:slug).pluck(:slug, :description).to_h
    migrate
    assert_equal before, Guide.where(slug: SLUGS).order(:slug).pluck(:slug, :title, :view_count)
    after = Guide.where(slug: SLUGS).order(:slug).pluck(:slug, :description).to_h
    assert_equal [ "construction-contract-complete-3" ], after.keys.reject { |s| after[s] == descriptions[s] }
    assert_includes after["construction-contract-complete-3"], "최저가 낙찰 vs 종합평가낙찰제"
  end

  test "NORMAL: 3편 낙찰 방식·8편 분쟁 기관(2차 종결)" do
    migrate
    cc3 = body("construction-contract-complete-3")
    assert_equal 0, cc3.scan("종합심사").size
    assert_includes cc3, "추정가격 300억 원 미만 공사에 적용(시행령 제42조①"
    assert_includes cc3, "300억~500억 원 미만 50점·500억~1,000억 원 미만 40점·1,000억 원 이상 35점"
    assert_includes cc3, "N[종합평가낙찰제]"
    assert_not_includes cc3, "60%"
    cc8 = body("construction-contract-complete-8")
    assert_includes cc8, "지방계약심의조정위원회"
    assert_includes cc8, "제34조의2"
    assert_not_includes cc8, "분쟁조정위원회"
  end

  test "ROLLBACK: 지문이 하나라도 없으면 한 편도 바꾸지 않는다" do
    g = Guide.find_by!(slug: "construction-contract-complete-10")
    rm = g.rich_media.merge("flowchart" => g.rich_media["flowchart"].sub("D --> I[천재지변 간접비 청구 불가]", "D --> I[운영에서 달라진 값]"))
    assert_not_equal g.rich_media, rm
    g.update_columns(rich_media: rm)
    before = SLUGS.map { |s| body(s) }
    assert_raises(RuntimeError) { migrate }
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "SEED: 시드 원천(비교표 포함)에도 틀린 문구가 없다" do
    text = SEED_FILES.map(&:read).join
    STALE.each { |s| assert_not_includes text, s }
    [ "필요 (1억원 이상 의무)", "입찰 공고 최소 기간은 7일", "\"계약금액의 3~5%\"", "\"가능\", \"불가\", \"불가\"",
      "하자보수보증금: 일반공사 계약금액의 3%",
      "\"계약금액의 10~20%\"", "추가 의회 동의", "7~14일", "종합심사낙찰제", "공사수행능력(40%)" ].each { |s| assert_not_includes text, s }
  end
end
