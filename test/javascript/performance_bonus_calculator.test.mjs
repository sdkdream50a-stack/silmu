// 성과상여금 계산기 회귀 (2026-09-17 전수감사 P0).
// 수당규정 별표2의3: 지급기준액 = 계급별 기준호봉(9급 10·8급 12·7급 15·6급 18·5급 18·1~4급 20)의 전년도 월봉급액.
// 2026년 지급분 = 공무원보수규정 별표3(개정 2025.1.3) 값.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const erb = readFileSync(new URL("app/views/tools/performance_bonus_calculator.html.erb", root), "utf8")
const SCRIPT = erb.match(/<script>([\s\S]*?)<\/script>/)[1]

function run({ grade = "", rate = "", payCount = "1" }) {
  const values = { "rank-grade": grade, "custom-rate": rate, "pay-count": payCount }
  const els = new Map()
  const el = (id) => {
    if (!els.has(id)) els.set(id, { value: values[id] ?? "", textContent: "", classList: { add() {}, remove() {} } })
    return els.get(id)
  }
  const sandbox = { document: { getElementById: el, querySelectorAll: () => [] } }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  vm.runInContext(SCRIPT, sandbox)
  sandbox.calculate()
  return { amount: String(el("bonus-amount").textContent), annual: String(el("annual-amount").textContent) }
}
const won = (t) => Number(t.replace(/[^0-9]/g, ""))

test("NORMAL: 9급 A등급 = 2,456,700 × 125%", () => {
  assert.equal(won(run({ grade: "9", rate: "125" }).amount), Math.round(2456700 * 1.25))
})

test("EDGE: 6급 기준은 18호봉(4,090,900원) — 본인 호봉과 무관", () => {
  assert.equal(won(run({ grade: "6", rate: "172.5" }).amount), Math.round(4090900 * 1.725))
})

test("UPPER_BOUND: 1급 20호봉 7,507,800원 · 연 2회면 연간 합계", () => {
  const r = run({ grade: "1", rate: "85", payCount: "2" })
  assert.equal(won(r.amount), Math.round(7507800 * 0.85))
  assert.equal(won(r.annual), Math.round(7507800 * 0.85 * 2))
})

test("LOWER_BOUND: 계급 미선택이면 금액을 내지 않는다", () => {
  assert.equal(won(run({ rate: "125" }).amount), 0)
})

test("EXCEPTION: 근거 없는 '부서 성과 ×70%' 계수가 없다", () => {
  assert.ok(!/\*=\s*0\.7\b/.test(SCRIPT))
})
