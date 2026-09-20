# frozen_string_literal: true

require "test_helper"

# P2 (2026-09-20 · CONNECTED_WORKFLOW) — `/guides/contract-flow` 가 결속을 실제로 싣는가.
#
# ⚠️ 검사를 두 우주로 나눈다(P1-1 이 세운 규율 상속).
#   · 코드 불변식(경로가 라우팅되는가 · 페이로드가 실리는가 · 계측이 그대로인가) → 이 파일
#   · 데이터 불변식(그 slug 의 레코드가 실제로 있는가) → 운영 스모크
#     (tools/smoke_workflow_bindings_0920.sh 가 운영에서 전 경로를 GET 한다)
#   test DB 픽스처에는 토픽·감사사례 레코드가 거의 없다. 여기서 GET 하면 «죽은 링크» 로 보이지만
#   운영에서는 살아 있다 — 그 차이를 사실로 착각하지 않으려고 나눈다.
class ContractFlowBindingsTest < ActionDispatch::IntegrationTest
  SPINE_VIEW = Rails.root.join("app", "views", "guides", "contract_flow.html.erb")

  test "흐름도가 열린다" do
    get contract_flow_url
    assert_response :success
    assert_includes response.body, "계약 흐름도"
  end

  test "결속 페이로드가 화면에 실린다" do
    get contract_flow_url
    assert_response :success

    # ⚠️ 종전 판본은 `WorkflowBindings.payload.keys` 와 대조했다 — **기대값을 피검 대상에서 읽는**
    #    동어반복이라 ERB 출력 여부만 쟀다(독립 리뷰 R1 TAUTOLOGY-2). 척추에서 파생한 값으로 바꾼다.
    payload = binding_payload
    spine_ids = File.read(SPINE_VIEW).scan(/['"]((?:goods|service|construction)-\d)['"]\s*=>/).flatten.uniq
    assert_equal 24, spine_ids.size, "척추 단계 추출이 깨졌다 — 검사 전제가 무너졌다"

    unknown = payload.keys - spine_ids
    assert_empty unknown, "척추에 없는 단계가 화면에 실렸다: #{unknown.join(', ')}"
    assert_operator payload.size, :>=, 20, "결속된 단계가 비정상적으로 적다"
    %w[goods-3 goods-8 service-2 construction-6].each do |stage_id|
      assert payload.key?(stage_id), "#{stage_id} 결속이 화면에 실리지 않았다"
    end
  end

  test "화면에 실린 모든 결속 경로가 라우팅된다" do
    get contract_flow_url
    paths = binding_payload.values.flat_map { |g| g.values.flatten }.map { |i| i["path"] }.uniq
    assert_operator paths.size, :>=, 40, "결속 경로가 비정상적으로 적다"

    unreachable = paths.reject { |path| reachable?(path) }
    assert_empty unreachable, "도달할 수 없는 결속 경로: #{unreachable.join(', ')}"
  end

  test "도달 검사가 실제로 오탐을 잡는다" do  # 양성 대조
    assert_not reachable?("/존재할수없는경로ZZZQQQ9999"),
               "없는 경로를 도달 가능이라고 판정한다 — 검사식이 죽어 있다"
    assert_not reachable?("/forms/없는서식ZZZQQQ.html"),
               "public 에 없는 정적 파일을 도달 가능이라고 판정한다"
    assert reachable?("/tools/contract-method"), "라우팅되는 경로를 못 찾는다 — 검사식이 과탐이다"
    assert reachable?("/forms/과업지시서.html"), "실재하는 정적 서식을 못 찾는다 — 검사식이 과탐이다"
  end

  test "정적 결속 경로는 test 에서도 실제로 열린다" do
    # 레코드가 필요 없는 경로만 — 픽스처 유무와 무관하게 성립한다.
    %w[/tools/contract-method /tools/estimated-price /tools/project-plan /tools/quote-review
       /tools/contract-documents /tools/legal-period /tools/cost-estimate /tools/design-change
       /tools/progress-inspection /tools/contract-guarantee /templates/3 /templates/4].each do |path|
      get path
      assert_response :success, "#{path} 가 열리지 않는다"
    end
  end

  # ── 계측 비회귀 (§14) ──────────────────────────────────────────────────
  test "새 GA4 이벤트를 만들지 않고 next_action_click 을 재사용한다" do
    get contract_flow_url
    assert_includes response.body, 'data-next-action-topic-slug-value="flow:contract-flow"',
                    "기존 next_action 계측이 붙어 있지 않다"

    js = File.read(Rails.root.join("app", "javascript", "controllers", "contract_flow_controller.js"))
    events = js.scan(/gtag\(\s*["']event["']\s*,\s*["']([a-z_]+)["']/).flatten
    assert_empty events, "흐름도 컨트롤러가 자체 GA4 이벤트를 만들었다: #{events.join(', ')}"
    assert_includes js, "next-action#track", "결속 링크에 기존 계측이 걸려 있지 않다"
  end

  test "slot 에 단계와 도착 경로가 함께 실린다" do
    js = File.read(Rails.root.join("app", "javascript", "controllers", "contract_flow_controller.js"))
    assert_match(/stepKey \+ ':' \+ item\.path/, js,
                 "slot 이 «단계:경로» 형태가 아니면 workflow_stage 를 얻을 수 없다")
  end

  # ── 척추 비회귀 ────────────────────────────────────────────────────────
  test "기존 step_data 척추가 그대로 실린다" do
    get contract_flow_url
    steps = JSON.parse(CGI.unescapeHTML(
      response.body[/data-contract-flow-steps-value="([^"]*)"/, 1]
    ))
    assert_equal 24, steps.size, "척추 단계 수가 바뀌었다"
    %w[goods service construction].each do |cat|
      (1..8).each { |n| assert steps.key?("#{cat}-#{n}"), "#{cat}-#{n} 가 척추에서 사라졌다" }
    end
    # 기존 근거 법령 링크(P2 이전부터 있던 것)가 남아 있는가
    assert steps.dig("goods-2", "laws").present?, "기존 laws 결속이 사라졌다"
  end

  test "물품/용역/공사 분기가 유지된다" do
    get contract_flow_url
    %w[goods service construction].each do |cat|
      assert_includes response.body, "id=\"flow-#{cat}\"", "#{cat} 흐름 탭이 사라졌다"
    end
  end

  # ── §9 학교 surface 비회귀 ─────────────────────────────────────────────
  test "학교 허브가 흐름도를 입구로 링크한다" do
    get school_office_url
    assert_response :success
    assert_includes SchoolOfficeController.primary_items.map { |i| i[:path] }, "/guides/contract-flow",
                    "학교 사용자가 흐름도로 들어올 입구가 없다"
  end

  test "학교 허브 핵심에 지자체 기준 자산이 여전히 0건" do  # P0 비회귀
    localgov = %w[/tools/budget-category-finder /tools/budget-transfer-checker
                  /guides/budget-execution-complete-3]
    primary = SchoolOfficeController.primary_items.map { |i| i[:path] }
    assert_empty localgov & primary, "P0 가 고친 혼입이 되살아났다"
  end

  private

  def binding_payload
    raw = response.body[/data-contract-flow-bindings-value="([^"]*)"/, 1]
    assert raw.present?, "결속 페이로드가 화면에 없다"
    JSON.parse(CGI.unescapeHTML(raw))
  end

  # 결속 경로는 두 종류다 — Rails 라우트와 `public/` 의 정적 서식(`/forms/*.html`).
  # 정적 파일은 웹서버가 내주므로 `recognize_path` 로는 보이지 않는다. 파일 실재로 판정한다.
  def reachable?(path)
    bare = path.split("?").first
    return File.file?(Rails.public_path.join(CGI.unescape(bare).delete_prefix("/"))) if bare.start_with?("/forms/")

    Rails.application.routes.recognize_path(bare, method: :get)
    true
  rescue ActionController::RoutingError
    false
  end
end
