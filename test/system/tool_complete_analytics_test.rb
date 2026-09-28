# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 P3 — tool_complete 는 «성공한 사용자 행동 1회당 1번» 이다.
# 실제 브라우저에서 도구 종류별 대표(계산기·판정기·문서 생성·다운로드·AI)를 눌러 gtag 호출을 센다.
# 테스트 환경엔 GA 가 없으므로 방문 직후 window.gtag 를 기록기로 심는다(partial 은 전송 시점에 gtag 를 찾는다).
class ToolCompleteAnalyticsTest < ApplicationSystemTestCase
  SETTLE = 2.2 # partial SETTLE_MS(1.5s) + 여유

  def arm_gtag
    page.execute_script(<<~JS)
      window.__ev = [];
      window.gtag = function () { window.__ev.push(Array.prototype.slice.call(arguments)); };
    JS
  end

  def count(name)
    page.evaluate_script("(window.__ev || []).filter(function (e) { return e[0] === 'event' && e[1] === #{name.to_json}; }).length")
  end

  # 앱 코드의 smooth scroll·패널 등장으로 클릭 좌표가 밀리는 것(ElementClickIntercepted)을 피한다.
  def press(selector, double: false)
    el = find(selector)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' })", el)
    sleep 0.3
    double ? el.double_click : el.click
  end

  def stub_fetch(js_response)
    page.execute_script("window.fetch = function () { return #{js_response}; };")
  end

  # ── 계산기 ──
  test "계산기(연금): 유효한 결과 1회 → start 1 · complete 1" do
    visit "/tools/pension-calculator"
    arm_gtag
    find("#income-input").fill_in(with: "3000000")
    sleep SETTLE
    assert_equal 1, count("tool_start")
    assert_equal 1, count("tool_complete")
  end

  test "계산기(연금): 무효 입력(0) → complete 0" do
    visit "/tools/pension-calculator"
    arm_gtag
    find("#income-input").fill_in(with: "0")
    sleep SETTLE
    assert_equal 1, count("tool_start")
    assert_equal 0, count("tool_complete")
  end

  test "계산기(퇴직금): 계산 버튼 더블 클릭 → complete 1" do
    visit "/tools/severance-calculator"
    arm_gtag
    find("#monthly-income").fill_in(with: "4500000")
    press("button[onclick='calculate()']", double: true)
    sleep SETTLE
    assert_equal 1, count("tool_complete")
  end

  test "이동만 함(입력 없음 · 페이지 로드 자동 계산) → complete 0" do
    visit "/tools/contract-legality-check" # DOMContentLoaded 에서 기본 체크리스트를 그린다
    arm_gtag
    sleep SETTLE
    page.execute_script("Turbo.visit('/tools/severance-calculator')") # 로드 시 calculate() 를 한 번 부른다
    assert_selector "#monthly-income"
    sleep SETTLE
    assert_equal 0, count("tool_complete")
    assert_equal 0, count("tool_start")
  end

  # ── 판정기 ──
  test "판정기(분할계약): 서버 판정이 화면에 나오면 complete 1" do
    visit "/tools/split-contract-checker"
    arm_gtag
    find("#contract-type").select("물품 (시행령 제7조제2호 · 추정가격 합산)")
    assert_selector "#result-card:not(.hidden)"
    sleep SETTLE
    assert_equal 1, count("tool_complete")
  end

  test "판정기(분할계약): 서버 호출 실패 → complete 0" do
    visit "/tools/split-contract-checker"
    arm_gtag
    stub_fetch("Promise.reject(new Error('offline'))")
    find("#contract-type").select("물품 (시행령 제7조제2호 · 추정가격 합산)")
    sleep SETTLE
    assert_equal 1, count("tool_start")
    assert_equal 0, count("tool_complete")
  end

  test "판정기(계약 적법성): 로드 때 그린 기본 체크리스트는 완료가 아니고, 단계를 고르면 1" do
    visit "/tools/contract-legality-check"
    arm_gtag
    sleep SETTLE
    assert_equal 0, count("tool_complete")
    find("#contract-stage").select("입찰·견적 단계")
    sleep SETTLE
    assert_equal 1, count("tool_complete")
  end

  # ── 문서 생성 ──
  test "문서 생성(사업계획서): 생성 1회 → complete 1 · 더블 클릭도 1 · 필수값 누락 → 0" do
    visit "/tools/project-plan"
    arm_gtag
    find("#pp-project-name").fill_in(with: "사무실 LED 조명 교체")
    press("button[onclick='ppGenerate()']")
    sleep 0.5
    assert_equal 0, count("tool_complete"), "필수값 누락(사업 필요성 등)인데 완료로 셌다"

    find("#pp-necessity").fill_in(with: "노후 형광등 교체 필요")
    find("#pp-content").fill_in(with: "LED 120개 교체")
    find("#pp-budget").fill_in(with: "15000000")
    press("button[onclick='ppGenerate()']", double: true)
    assert_selector "#pp-result.active"
    sleep 0.5
    assert_equal 1, count("tool_complete")
  end

  # ── 다운로드 ──
  test "다운로드(PDF 쪽번호): 파일 응답 성공 → complete 1" do
    pdf = Rails.root.join("tmp/tool_complete_sample.pdf")
    File.binwrite(pdf, Prawn::Document.new { text "silmu" }.render)
    visit "/tools/pdf"
    arm_gtag
    press("button.tab-btn[data-tool='numbering']")
    attach_file "numbering-file", pdf.to_s, make_visible: true
    assert_selector "#numbering-options:not(.hidden)"
    press("button[onclick='processNumbering()']")
    sleep 2
    assert_equal 1, count("tool_complete")
  ensure
    FileUtils.rm_f(pdf) if pdf
  end

  test "다운로드(PDF 쪽번호): 서버 오류 응답 → complete 0" do
    pdf = Rails.root.join("tmp/tool_complete_sample_fail.pdf")
    File.binwrite(pdf, Prawn::Document.new { text "silmu" }.render)
    visit "/tools/pdf"
    arm_gtag
    press("button.tab-btn[data-tool='numbering']")
    attach_file "numbering-file", pdf.to_s, make_visible: true
    assert_selector "#numbering-options:not(.hidden)"
    stub_fetch("Promise.resolve(new Response(JSON.stringify({ error: 'x' }), { status: 422, headers: { 'Content-Type': 'application/json' } }))")
    press("button[onclick='processNumbering()']")
    sleep 1
    assert_equal 0, count("tool_complete")
  ensure
    FileUtils.rm_f(pdf) if pdf
  end

  # ── AI ──
  def fill_official_document
    visit "/tools/official-document"
    arm_gtag
    # 테스트 환경은 CSRF meta 를 렌더하지 않는다(운영은 렌더) — odGenerate 가 meta.content 를 읽다 멈추지 않게 심는다.
    page.execute_script("var m = document.createElement('meta'); m.name = 'csrf-token'; m.content = 't'; document.head.appendChild(m);")
    press(".od-type-btn[data-type='draft']")
    find("#od-recipient").fill_in(with: "총무과장")
    find("#od-title").fill_in(with: "LED 조명 교체 추진 계획")
    find("#od-content-summary").fill_in(with: "노후 형광등 150개를 LED 로 교체")
  end

  test "AI(공문서): 성공 응답 → complete 1" do
    fill_official_document
    stub_fetch("Promise.resolve(new Response(JSON.stringify({ success: true, html: '<p>본문</p>', term_compliance_rate: 1, term_changes_count: 0 }), { headers: { 'Content-Type': 'application/json' } }))")
    press("#od-generate-btn")
    assert_selector "#od-result.active"
    sleep 0.5
    assert_equal 1, count("tool_complete")
  end

  test "AI(공문서): 실패 응답·네트워크 오류 → complete 0" do
    fill_official_document
    stub_fetch("Promise.resolve(new Response(JSON.stringify({ success: false, error: 'AI 오류' }), { headers: { 'Content-Type': 'application/json' } }))")
    press("#od-generate-btn")
    sleep 0.5
    stub_fetch("Promise.reject(new Error('offline'))")
    press("#od-generate-btn")
    sleep 0.5
    assert_equal 1, count("tool_start")
    assert_equal 0, count("tool_complete")
  end
end
