// tool_complete 정본화 회귀 (2026-09-28 · P3 silmu-tool-complete-analytics)
// 왜 이 테스트가 있나: tool_start 는 38/38 인데 tool_complete 는 #result-area 관례를 쓰는 소수 도구에서만 나갔다.
// 이제 tool_complete 는 도구가 결과를 신고하는 순간(window.silmuCalcResult)에 calc_complete 와 함께 1회 나간다.
// partial 의 <script> 를 실제로 실행하고, document 리스너에 가짜 사용자 이벤트를 흘려 gtag 호출을 센다.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const TOOL = readFileSync(new URL("app/views/shared/_tool_analytics.html.erb", root), "utf8").match(/<script>([\s\S]*)<\/script>/)[1]
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

function page(path = "/tools/pension-calculator") {
  const calls = []
  const listeners = []
  const sandbox = {
    setTimeout, clearTimeout, setInterval, clearInterval,
    location: { pathname: path, search: "" },
    document: { addEventListener: (type, fn) => listeners.push([type, fn]), getElementById: () => null },
    gtag: (...args) => calls.push(args),
  }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  const run = (p) => { sandbox.location.pathname = p; vm.runInContext(TOOL, sandbox) } // 한 번 = 한 페이지 방문(Turbo 포함)
  run(path)
  const input = { matches: () => true, closest: () => null }
  const user = (type = "input") => listeners.filter(([t]) => t === type).forEach(([, fn]) => fn({ type, target: input }))
  const count = (name, toolId) => calls.filter((c) => c[1] === name && (!toolId || (c[2].tool_id || c[2].tool_slug) === toolId)).length
  return { sandbox, calls, user, count, visit: run }
}

test("성공 결과 1회 → tool_complete 1 · calc_complete 1 (사용자 입력 뒤)", () => {
  const p = page()
  p.user("input")
  p.sandbox.silmuCalcResult("2026|20|3000000", { immediate: true })
  assert.equal(p.count("tool_complete"), 1)
  assert.equal(p.count("calc_complete"), 1)
  assert.equal(p.count("tool_start"), 1)
  assert.deepEqual(Object.keys(p.calls.find((c) => c[1] === "tool_complete")[2]), ["tool_id", "page_path"])
})

test("같은 결과를 두 번 신고(더블 클릭·중복 응답) → tool_complete 1", () => {
  const p = page()
  p.user("click")
  p.sandbox.silmuCalcResult("a", { immediate: true })
  p.sandbox.silmuCalcResult("a", { immediate: true })
  assert.equal(p.count("tool_complete"), 1)
})

test("서로 다른 결과는 각각 1회", () => {
  const p = page()
  p.user("input")
  p.sandbox.silmuCalcResult("a", { immediate: true })
  p.sandbox.silmuCalcResult("b", { immediate: true })
  assert.equal(p.count("tool_complete"), 2)
})

test("무효 입력(null) → 0 · 대기 중 결과가 무효로 바뀌면 취소", async () => {
  const p = page()
  p.user("input")
  p.sandbox.silmuCalcResult(null, { immediate: true })
  p.sandbox.silmuCalcResult("x")
  p.sandbox.silmuCalcResult(null)
  await sleep(1700)
  assert.equal(p.count("tool_complete"), 0)
  assert.equal(p.count("calc_complete"), 0)
})

test("사용자 조작 없이(페이지 로드 중 자동 계산) → tool_complete 0 · calc_complete 는 대조군으로 불변", () => {
  const p = page() // 조작 이벤트 없이 DOMContentLoaded 등에서 계산 함수가 직접 불린 경우
  p.sandbox.silmuCalcResult("restored", { immediate: true })
  assert.equal(p.count("tool_complete"), 0)
  assert.equal(p.count("calc_complete"), 1)
})

test("입력이 멈추기 전에 다른 도구로 이동(Turbo) → 이전 도구 tool_complete 0", async () => {
  const p = page("/tools/pension-calculator")
  p.user("input")
  p.sandbox.silmuCalcResult("typing")
  p.visit("/tools/salary-calculator")
  await sleep(1700)
  assert.equal(p.count("tool_complete"), 0)
  assert.equal(p.count("calc_complete"), 0)
})

// 독립 리뷰(2026-09-28) 지적: 계측 파셜이 없는 화면(가이드 등)으로 가면 세대 번호가 그대로라 이전 도구 대기분이 새 화면에서 나갔다.
test("입력이 멈추기 전에 도구가 아닌 화면으로 이동(파셜 없음) → tool_complete 0", async () => {
  const p = page("/tools/overtime-calculator")
  p.user("input")
  p.sandbox.silmuCalcResult("typing")
  p.sandbox.location.pathname = "/guides/some-guide" // 파셜을 다시 실행하지 않는 Turbo 방문
  await sleep(1700)
  assert.equal(p.count("tool_complete"), 0)
})

test("버튼만 누른 경로(샘플 등)도 tool_start 를 먼저 보정해 퍼널이 깨지지 않는다", () => {
  const p = page()
  p.user("click")
  p.sandbox.silmuCalcResult("sample", { immediate: true })
  const names = p.calls.map((c) => c[1])
  assert.deepEqual(names.filter((n) => n !== "calc_complete"), ["tool_start", "tool_complete"])
})
