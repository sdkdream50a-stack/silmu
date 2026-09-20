# frozen_string_literal: true

require "test_helper"

# P2 (2026-09-20 · CONNECTED_WORKFLOW) — 단계 ↔ 자산 결속 등록부.
#
# 이 파일이 경계하는 두 가지 항진식(§17):
#   ① 「연결이 하나 빠졌는데 테스트가 여전히 통과」
#   ② 「엉뚱한 도구를 다른 단계에 심었는데 통과」
# ①은 **척추 본문에서 기대값을 파생**해 막는다 — 본문이 도구 이름을 적었으면 그 도구는
#   그 단계에 결속돼 있어야 한다. 내가 손으로 적은 목록이 아니라 화면 텍스트가 채점한다.
# ②는 그룹 ↔ 자산 종류 대조 + 수직 슬라이스(물품) 앵커로 막는다.
# 두 검사 모두 **음성 대조**를 함께 둔다 — 결함을 심었을 때 실제로 걸리는지 확인한다.
class WorkflowBindingsTest < ActiveSupport::TestCase
  SPINE_VIEW = Rails.root.join("app", "views", "guides", "contract_flow.html.erb")

  # 척추 본문을 단계별로 자른다. `step_data` 의 각 단계가 한 줄이라 줄 단위로 나뉜다.
  def spine_text
    @spine_text ||= begin
      source = File.read(SPINE_VIEW)
      WorkflowBindings::STAGE_IDS.index_with do |stage_id|
        line = source.lines.find { |l| l.lstrip.match?(/\A['"]#{Regexp.escape(stage_id)}['"]\s*=>/) }
        raise "척추에서 #{stage_id} 를 찾지 못했다 — 단계 id 가 바뀌었다면 등록부도 함께 고쳐야 한다" if line.nil?

        line
      end
    end
  end

  # ── 등록부 자체의 불변식 ────────────────────────────────────────────────
  test "등록부가 로드되고 척추의 24단계 안에만 있다" do
    assert_equal 24, WorkflowBindings::STAGE_IDS.size
    WorkflowBindings.all.each_key do |stage_id|
      assert_includes WorkflowBindings::STAGE_IDS, stage_id
    end
  end

  test "척추의 모든 단계가 등록부에 실재한다" do
    # 빈 단계를 두더라도 «키가 없다» 와 «자산이 없다» 를 구분할 수 있어야 한다.
    missing = WorkflowBindings::STAGE_IDS - WorkflowBindings.all.keys
    assert_empty missing, "등록부에 없는 척추 단계: #{missing.join(', ')}"
  end

  test "한 단계 안에 같은 경로가 두 번 오지 않는다" do
    WorkflowBindings.all.each do |stage_id, groups|
      paths = groups.values.flatten.map { |i| i["path"] }
      assert_equal paths.uniq, paths, "#{stage_id} 에 중복 경로가 있다"
    end
  end

  test "모든 항목이 label·path·why 를 갖는다" do
    WorkflowBindings.all.each do |stage_id, groups|
      groups.each do |group, items|
        items.each do |item|
          %w[label path why].each do |key|
            assert item[key].present?, "#{stage_id}/#{group}/#{item['path']} 의 #{key} 가 비었다"
          end
          assert item["path"].start_with?("/"), "#{stage_id}/#{group}: 절대 경로가 아니다"
        end
      end
    end
  end

  # ── fail-closed 검증 (양성 대조) ────────────────────────────────────────
  # 검증기가 살아 있는지 실제로 결함을 먹여 확인한다. 통과만 보고 «검증한다» 고 하지 않는다.
  def load_stages(yaml)
    Tempfile.create([ "wb", ".yml" ]) do |f|
      f.write(yaml)
      f.flush
      original = WorkflowBindings::PATH
      WorkflowBindings.send(:remove_const, :PATH)
      WorkflowBindings.const_set(:PATH, Pathname.new(f.path))
      WorkflowBindings.reset!
      begin
        yield
      ensure
        WorkflowBindings.send(:remove_const, :PATH)
        WorkflowBindings.const_set(:PATH, original)
        WorkflowBindings.reset!
      end
    end
  end

  test "척추에 없는 단계 id 를 거부한다" do
    load_stages("stages:\n  goods-99:\n    tools:\n      - {label: x, path: /tools/x, why: y}\n") do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "why 가 빠진 항목을 거부한다" do
    load_stages("stages:\n  goods-1:\n    tools:\n      - {label: x, path: /tools/x}\n") do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "알 수 없는 그룹을 거부한다" do
    load_stages("stages:\n  goods-1:\n    gadgets:\n      - {label: x, path: /tools/x, why: y}\n") do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "근거 없는 school 강등을 거부한다" do
    yaml = "stages:\n  goods-1:\n    topics:\n      - {label: x, path: /topics/x, why: y, school: reference}\n"
    load_stages(yaml) do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "존재하지 않는 도구를 school_note_source 로 적으면 거부한다" do
    yaml = "stages:\n  goods-1:\n    topics:\n      - {label: x, path: /topics/x, why: y, " \
           "school: conditional, school_note_source: 없는도구}\n"
    load_stages(yaml) do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "지자체 기준 자산을 행동 묶음에 결속하면 거부한다" do
    yaml = "stages:\n  goods-1:\n    tools:\n      - {label: x, path: /tools/budget-transfer-checker, why: y, " \
           "school: reference, school_note_source: budget-transfer-checker}\n"
    load_stages(yaml) do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "한 단계에 같은 경로를 두 번 적으면 거부한다" do
    # ⚠️ 위 「중복 경로가 없다」 는 **현재 데이터가 깨끗하다** 만 말한다. 검증기를 지워도
    #    그 검사는 통과한다(변이 M6 로 실측). 검증기가 사는지는 결함을 먹여야 알 수 있다.
    yaml = "stages:\n  goods-1:\n    tools:\n      - {label: a, path: /tools/x, why: y}\n" \
           "    forms:\n      - {label: b, path: /tools/x, why: y}\n"
    load_stages(yaml) do
      assert_raises(WorkflowBindings::InvalidRegistry) { WorkflowBindings.all }
    end
  end

  test "정상 등록부는 같은 로더로 통과한다" do  # 음성 대조 — 위 거부들이 «무조건 거부» 가 아님을 보인다
    yaml = "stages:\n  goods-1:\n    tools:\n      - {label: x, path: /tools/x, why: y}\n"
    load_stages(yaml) do
      assert_equal 1, WorkflowBindings.all["goods-1"]["tools"].size
    end
  end

  # ── ① 「빠진 연결」 — 기대값을 척추 본문에서 파생한다 ────────────────────
  test "척추 본문이 이름을 적은 도구는 그 단계에 결속돼 있다" do
    registry = self.class.tools_registry
    unbound = []

    WorkflowBindings::STAGE_IDS.each do |stage_id|
      text = spine_text[stage_id]
      bound = WorkflowBindings.stage(stage_id).values.flatten.map { |i| i["path"] }

      registry.each do |tool|
        next unless text.include?(tool[:title])
        next if bound.include?(tool[:path])

        unbound << "#{stage_id} 본문이 «#{tool[:title]}» 을 적었는데 #{tool[:path]} 가 결속돼 있지 않다"
      end
    end

    assert_empty unbound, unbound.join("\n")
  end

  test "위 검사가 실제로 «빠진 연결» 을 잡는다" do  # 음성 대조
    # goods-3 본문은 «계약방식 결정 도우미» 를 이름으로 적는다. 그 결속을 뺀 상태를 만들어
    # 같은 검사식을 먹인다 — 걸리지 않으면 위 검사는 죽어 있다.
    registry = self.class.tools_registry
    text = spine_text["goods-3"]
    named = registry.select { |t| text.include?(t[:title]) }
    assert_not_empty named, "척추 goods-3 가 도구 이름을 더 이상 적지 않는다 — 검사 전제가 깨졌다"

    bound_without = WorkflowBindings.stage("goods-3").values.flatten
                                    .map { |i| i["path"] } - [ named.first[:path] ]
    assert_not_empty(named.reject { |t| bound_without.include?(t[:path]) },
                     "결속을 뺐는데도 검사가 통과한다 — 검사식이 죽어 있다")
  end

  # ── ① 보강 — 서식이 «다른 단계» 에 심겼는가 ────────────────────────────
  # 도구는 척추 본문에 이름이 **한 번만** 나온다(goods-3). 그래서 그 검사 하나로는 표본이 1이다.
  # 서식은 척추 `docs` 가 이름을 적는다 — 그 이름이 척추 어딘가에 있다면, 그 서식은
  # **그 이름이 나오는 단계**에 결속돼야 한다. 기대값은 여전히 척추가 만든다.
  #
  # 등록부 이름과 척추 표기가 다른 경우만 별칭을 둔다. 단 **변별력 있는 별칭만** —
  # 「표준계약서 → 계약서」 는 척추 7단계에 나와서 어디에 붙여도 통과한다(= 검사가 죽는다).
  # 그런 것은 별칭을 만들지 않고 **미검증으로 남겨 두고 그 사실을 아래에서 단언**한다.
  # (독립 리뷰 R2 MEDIUM-1)
  FORM_SPINE_ALIASES = {
    "구매 기안문" => "구매 품의서",       # 척추 goods-1 만
    "납품확인서" => "납품서",             # 척추 goods-6 만
    "대금청구서" => "대금 지급청구서",     # 척추 goods-8 · service-8
    "설계변경 요청서" => "설계변경"        # 척추 construction-5 만
  }.freeze

  # 척추와 대조할 수 없는 서식. 목록을 비워 두지 않고 **적어 둔다** —
  # 「검사됨」과 「검사 못 함」을 구분하기 위해서다.
  # 변별력 있는 토큰 = 척추 **1~2단계**에만 나오는 것. 0단계(척추가 그 이름을 안 쓴다)와
  # 3단계 이상(어디에 붙여도 통과한다)은 둘 다 검사로 쓸 수 없다.
  FORMS_NOT_COMPARABLE = {
    "물품구매 표준계약서" => "척추는 «계약서» 로만 적어 이 이름이 0단계",
    "용역 표준계약서" => "척추는 «계약서(과업 별첨)» 로만 적어 이 이름이 0단계"
  }.freeze
  COMPARABLE_STAGE_RANGE = (1..2).freeze

  def form_spine_token(label)
    core = label.sub(/\A(물품|용역|공사)\s*/, "")
    FORM_SPINE_ALIASES.fetch(core, core)
  end

  # 탐지 루프 — 테스트와 **음성 대조가 같은 코드를 탄다**.
  # (독립 리뷰 R2 MEDIUM-2: 종전 대조는 루프를 돌리지 않고 전제만 재확인해 항상 통과했다)
  def detect_misplaced_forms(bindings)
    checked = []
    misplaced = []

    bindings.each do |stage_id, groups|
      (groups["forms"] || []).each do |form|
        token = form_spine_token(form["label"])
        next unless spine_text.values.any? { |line| line.include?(token) }

        checked << "#{stage_id}:#{form['label']}"
        next if spine_text[stage_id].to_s.include?(token)

        where = spine_text.select { |_, line| line.include?(token) }.keys
        misplaced << "#{stage_id} 에 «#{form['label']}» 를 걸었는데 척추는 그 이름을 #{where.join(',')} 에서만 적는다"
      end
    end

    [ checked, misplaced ]
  end

  test "척추가 이름을 적은 서식은 그 이름이 나오는 단계에 결속돼 있다" do
    checked, misplaced = detect_misplaced_forms(WorkflowBindings.all)

    total = WorkflowBindings.all.sum { |_, g| (g["forms"] || []).size }
    assert_equal total - FORMS_NOT_COMPARABLE.size, checked.size,
                 "대조 가능/불가 집합이 예상과 다르다 — 척추 표기가 바뀌었을 수 있다 (checked=#{checked.size} total=#{total})"
    assert_empty misplaced, misplaced.join("\n")
  end

  test "대조 불가로 분류한 서식이 실제로 대조 불가인지 확인한다" do
    # 「검사 못 한다」도 단언한다 — 조용히 빠지면 커버리지 착시가 된다.
    FORMS_NOT_COMPARABLE.each do |label, why|
      token = form_spine_token(label)
      where = spine_text.select { |_, line| line.include?(token) }.keys
      assert_not COMPARABLE_STAGE_RANGE.cover?(where.size),
                 "«#{label}»(#{why}) 의 토큰 «#{token}» 이 이제 #{where.size}단계에 나온다 — " \
                 "변별력이 생겼으니 별칭을 만들어 검사에 넣어라"
    end
  end

  test "대조 가능으로 쓰는 별칭은 실제로 변별력이 있다" do  # 양성 대조
    FORM_SPINE_ALIASES.each_value do |token|
      where = spine_text.select { |_, line| line.include?(token) }.keys
      assert COMPARABLE_STAGE_RANGE.cover?(where.size),
             "별칭 토큰 «#{token}» 이 #{where.size}단계에 나온다 — 검사가 변별하지 못한다"
    end
  end

  test "위 검사가 실제로 «다른 단계에 심은 서식» 을 잡는다" do  # 음성 대조 — 같은 루프를 탄다
    planted = WorkflowBindings.all.transform_values { |g| g.transform_values(&:dup) }
    planted["service-1"] = planted["service-1"].merge(
      "forms" => [ { "label" => "착수계", "path" => "/templates/7", "why" => "결함 주입" } ]
    )

    _, clean = detect_misplaced_forms(WorkflowBindings.all)
    assert_empty clean, "실제 등록부에서 오배치가 검출됐다"

    _, caught = detect_misplaced_forms(planted)
    assert_not_empty caught,
                     "착수계를 service-1 에 심었는데도 탐지 루프가 통과한다 — 검사식이 죽어 있다"
  end

  # ── ② 「엉뚱한 자산」 — 그룹과 자산 종류가 맞는가 ────────────────────────
  test "tools 묶음에는 실재하는 도구만 온다" do
    tool_paths = self.class.tools_registry.map { |t| t[:path] }
    WorkflowBindings.all.each do |stage_id, groups|
      (groups["tools"] || []).each do |item|
        assert_includes tool_paths, item["path"],
                        "#{stage_id}: 도구 등록부에 없는 경로를 tools 로 결속했다 — #{item['path']}"
      end
    end
  end

  test "forms 묶음에는 실재하는 서식 번호만 온다" do
    ids = TemplatesController::TEMPLATES.map { |t| t[:id].to_s }
    WorkflowBindings.all.each do |stage_id, groups|
      (groups["forms"] || []).each do |item|
        assert_match %r{\A/templates/\d+\z}, item["path"], "#{stage_id}: 서식 경로 형식이 아니다"
        assert_includes ids, item["path"].split("/").last,
                        "#{stage_id}: 없는 서식 번호 — #{item['path']}"
      end
    end
  end

  test "참고 묶음의 경로 접두사가 종류와 일치한다" do
    { "topics" => "/topics/", "guides" => "/guides/", "audit_cases" => "/audit-cases/",
      "review_lab" => "/review-lab" }.each do |group, prefix|
      WorkflowBindings.all.each do |stage_id, groups|
        (groups[group] || []).each do |item|
          assert item["path"].start_with?(prefix),
                 "#{stage_id}/#{group}: #{item['path']} 가 #{prefix} 로 시작하지 않는다"
        end
      end
    end
  end

  # ── 수직 슬라이스(물품) 앵커 — «업무 하나 끝까지» 가 실제로 이어지는가 ──
  # ASSET_COVERAGE 측정 결과 물품이 승자였다(ACTIONABLE 8/8). 그 8단계가 끊기면 실패한다.
  GOODS_ANCHORS = {
    "goods-1" => "/tools/project-plan",
    "goods-2" => "/tools/estimated-price",
    "goods-3" => "/tools/contract-method",
    "goods-4" => "/tools/quote-review",
    "goods-5" => "/tools/contract-documents",
    "goods-6" => "/templates/4",
    "goods-7" => "/templates/3",
    "goods-8" => "/tools/legal-period"
  }.freeze

  # 척추 본문은 도구를 «행위» 로 적지 이름으로 적지 않는다(이름 일치는 24단계 중 1건뿐).
  # 그래서 텍스트 파생이 닿지 않는 용역·공사 핵심 단계는 앵커로 결정론적으로 고정한다.
  # (독립 리뷰 R1 MEDIUM-2 — 「23단계 침묵」 지적 반영)
  SERVICE_ANCHORS = {
    "service-1" => "/tools/project-plan",
    "service-2" => "/forms/과업지시서.html",
    "service-3" => "/tools/cost-calculation",
    "service-4" => "/tools/contract-method",
    "service-5" => "/templates/7",
    "service-7" => "/templates/8",
    "service-8" => "/tools/legal-period"
  }.freeze

  CONSTRUCTION_ANCHORS = {
    "construction-1" => "/tools/project-plan",
    "construction-2" => "/tools/cost-estimate",
    "construction-3" => "/tools/contract-method",
    "construction-4" => "/templates/11",
    "construction-5" => "/tools/design-change",
    "construction-6" => "/tools/progress-inspection",
    "construction-7" => "/templates/12"
  }.freeze

  test "용역 핵심 단계의 결속이 사라지지 않는다" do
    SERVICE_ANCHORS.each do |stage_id, path|
      paths = WorkflowBindings.stage(stage_id).values.flatten.map { |i| i["path"] }
      assert_includes paths, path, "#{stage_id} 의 핵심 결속이 사라졌다 — #{path}"
    end
  end

  test "공사 핵심 단계의 결속이 사라지지 않는다" do
    CONSTRUCTION_ANCHORS.each do |stage_id, path|
      paths = WorkflowBindings.stage(stage_id).values.flatten.map { |i| i["path"] }
      assert_includes paths, path, "#{stage_id} 의 핵심 결속이 사라졌다 — #{path}"
    end
  end

  test "앵커가 척추 단계 id 와 어긋나지 않는다" do  # 양성 대조 — 앵커가 죽은 단계를 가리키면 무의미
    (GOODS_ANCHORS.keys + SERVICE_ANCHORS.keys + CONSTRUCTION_ANCHORS.keys).each do |stage_id|
      assert_includes WorkflowBindings::STAGE_IDS, stage_id
      assert spine_text[stage_id].present?, "#{stage_id} 가 척추에 없다"
    end
  end

  test "물품 수직 슬라이스 8단계가 끊기지 않는다" do
    GOODS_ANCHORS.each do |stage_id, path|
      paths = WorkflowBindings.stage(stage_id).values.flatten.map { |i| i["path"] }
      assert_includes paths, path, "#{stage_id} 의 핵심 결속이 사라졌다 — #{path}"
    end
  end

  test "물품 8단계 전부가 «행동» 자산을 갖는다" do
    (1..8).each do |n|
      stage_id = "goods-#{n}"
      groups = WorkflowBindings.stage(stage_id)
      actionable = WorkflowBindings::ACTIONABLE_GROUPS.sum { |g| (groups[g] || []).size }
      assert_operator actionable, :>, 0,
                      "#{stage_id} 에 눌러서 진행할 자산이 없다 — 흐름이 여기서 끊긴다"
    end
  end

  test "«행동 자산» 검사가 빈 단계를 실제로 잡는다" do  # 음성 대조
    empty = { "topics" => [ { "path" => "/topics/x" } ] }
    actionable = WorkflowBindings::ACTIONABLE_GROUPS.sum { |g| (empty[g] || []).size }
    assert_equal 0, actionable, "참고자료만 있는 단계를 «행동 있음» 으로 세고 있다"
  end

  # ── §9 학교 surface ────────────────────────────────────────────────────
  test "학교 surface 핵심에 LOCAL_GOV_ONLY 자산이 0건" do
    # 판정 정본은 P0 가 이미 소유한다(school_office_hub_test 와 같은 목록).
    localgov = %w[/tools/budget-category-finder /tools/budget-transfer-checker
                  /guides/budget-execution-complete-3]
    leaked = WorkflowBindings.all.flat_map do |stage_id, groups|
      WorkflowBindings::ACTIONABLE_GROUPS.flat_map do |g|
        (groups[g] || []).map { |i| i["path"] }.select { |p| localgov.include?(p) }
                         .map { |p| "#{stage_id}:#{p}" }
      end
    end
    assert_empty leaked, "지자체 기준 자산이 행동 묶음에 결속됐다: #{leaked.join(', ')}"
  end

  test "학교 조건부 문구는 tool_trust 에서 읽어 온다" do
    conditional = WorkflowBindings.all.values.flat_map { |g| g.values.flatten }
                                  .select { |i| i["school"].present? }
    assert_not_empty conditional, "조건부 결속이 하나도 없다 — 이 검사가 무의미해졌다"

    trust = YAML.load_file(Rails.root.join("config", "tool_trust.yml"))
    conditional.each do |item|
      expected = trust.dig("tools", item["school_note_source"], "jurisdiction", "school_differs")
      assert_equal expected, item["school_note"],
                   "#{item['path']} 의 학교 문구가 tool_trust 와 어긋난다 — 옮겨 적지 말고 읽어야 한다"
    end
  end

  # 도구 등록부는 헬퍼라 라우트 헬퍼 컨텍스트가 필요하다(기존 테스트와 같은 방식).
  def self.tools_registry
    @tools_registry ||= Class.new do
      include ToolsHelper
      include Rails.application.routes.url_helpers
    end.new.tools_registry.map { |t| t.merge(path: t[:path].to_s) }
  end
end
