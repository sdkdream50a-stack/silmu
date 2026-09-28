// calc_complete 신고 훅 존재 회귀 (2026-09-28 · silmu-tool-analytics-coverage)
// 왜 이 테스트가 있나: 컨트롤러 이름이 tools/contract_methods 가 아니라 계측 파셜이 안 붙던 17개
// /tools/* 도구에 calc_complete 훅을 새로 달았다. 각 도구는 자체 DOM 구조(id·Stimulus target)가
// 서로 달라 tool_analytics_calc_complete.test.mjs 처럼 하나의 sandbox 로 실행할 수 없다 — 대신
// 각 파일의 성공 콜백이 실제로 window.silmuCalcResult 를 호출하도록 남아 있는지 소스 수준으로
// 고정한다(동작 검사가 아니라 존재 검사 — 완전한 실행 검증은 test/integration/tool_analytics_test.rb
// 의 렌더 조건 테스트가 대신한다).
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const root = new URL("../../", import.meta.url)
const read = (path) => readFileSync(new URL(path, root), "utf8")

const HOOKED_FILES = [
  "app/views/contract_documents/index.html.erb",
  "app/views/cost_estimates/index.html.erb",
  "app/views/design_changes/index.html.erb",
  "app/views/progress_inspections/index.html.erb",
  "app/views/cost_calculations/index.html.erb",
  "app/views/quote_documents/index.html.erb",
  "app/views/quote_reviews/index.html.erb",
  "app/views/project_plans/index.html.erb",
  "app/views/official_documents/index.html.erb",
  "app/views/contract_reasons/index.html.erb",
  "app/views/estimated_prices/index.html.erb",
  "app/views/legal_periods/index.html.erb",
  "app/views/contract_guarantees/index.html.erb",
  "app/views/estimations/index.html.erb",
  "app/views/pdf_tools/index.html.erb",
  "app/javascript/controllers/qualification_evaluation_controller.js",
  "app/javascript/controllers/insurance_calculator_controller.js",
]

for (const path of HOOKED_FILES) {
  test(`${path} 가 window.silmuCalcResult 신고 훅을 갖고 있다`, () => {
    const src = read(path)
    assert.match(src, /window\.silmuCalcResult/, `${path} 에서 calc_complete 신고 훅이 사라졌다`)
  })
}

test("contract_guarantees 는 지체상금·계약보증금 두 계산 경로 모두 신고한다", () => {
  const src = read("app/views/contract_guarantees/index.html.erb")
  const hits = src.match(/window\.silmuCalcResult/g) || []
  assert.ok(hits.length >= 2, "두 fetch 성공 콜백 중 하나가 신고 훅을 잃었다")
})

test("pdf_tools 는 split·merge·numbering 세 경로 모두 신고한다", () => {
  const src = read("app/views/pdf_tools/index.html.erb")
  assert.match(src, /silmuCalcResult\('pdf-split'/)
  assert.match(src, /silmuCalcResult\('pdf-merge'/)
  assert.match(src, /silmuCalcResult\('pdf-numbering'/)
})

test("quote_reviews 는 layout false 라 partial 을 뷰에서 직접 render 한다", () => {
  const src = read("app/views/quote_reviews/index.html.erb")
  assert.match(src, /render\s+"shared\/tool_analytics"/,
    "quote_reviews#index 는 application 레이아웃을 타지 않는다 — partial 을 직접 render 해야 한다")
})
