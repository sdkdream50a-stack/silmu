// 공무원연금 계산기 회귀 (2026-09-17 전수감사 P0).
// 공무원연금법 §43①(10년 이상 재직) · §43④(1.7%, 36년 한도) · 부칙 제13조제1항(퇴직 연도별 비율).
// "2015년 이전 임용자 1.9%" 일괄 적용은 원문에 없다 — 퇴직 연도 비율을 쓴다.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const erb = readFileSync(new URL("app/views/tools/pension_calculator.html.erb", root), "utf8")
const SCRIPT = erb.match(/<script>([\s\S]*?)<\/script>/)[1]

function run({ tenure, income, retireYear }) {
  const values = { "tenure-slider": String(tenure), "income-input": String(income) }
  const els = new Map()
  const el = (id) => {
    if (!els.has(id)) els.set(id, { value: values[id] ?? "", textContent: "", style: {}, classList: { add() {}, remove() {}, toggle() {} } })
    return els.get(id)
  }
  const sandbox = { document: { getElementById: el, querySelectorAll: () => [], addEventListener() {} } }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  vm.runInContext(SCRIPT, sandbox)
  if (retireYear) sandbox.selectRetireYear(String(retireYear))
  sandbox.calculate()
  return Number(String(el("result-pension-monthly").textContent).replace(/[^0-9]/g, ""))
}

test("NORMAL: 2026년 퇴직 20년 · 평균 400만원 → 1.736%", () => {
  assert.equal(run({ tenure: 20, income: 4000000, retireYear: 2026 }), Math.round(4000000 * 20 * 0.01736))
})

test("EDGE: 퇴직 연도가 바뀌면 비율이 바뀐다 (2030년 1.72%)", () => {
  assert.equal(run({ tenure: 20, income: 4000000, retireYear: 2030 }), Math.round(4000000 * 20 * 0.0172))
})

test("UPPER_BOUND: 36년 초과는 36년으로, 2035년 이후 1.7%", () => {
  assert.equal(run({ tenure: 40, income: 4000000, retireYear: 2035 }), Math.round(4000000 * 36 * 0.017))
})

test("LOWER_BOUND: 10년 미만 입력은 10년으로 올려 계산(슬라이더 최소 10년)", () => {
  assert.equal(run({ tenure: 5, income: 4000000, retireYear: 2026 }), Math.round(4000000 * 10 * 0.01736))
})

test("EXCEPTION: 1.9% 일괄 적용 경로가 없다", () => {
  assert.ok(!/0\.019\b/.test(SCRIPT))
})
