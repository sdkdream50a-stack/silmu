// 시간외근무수당 계산 회귀 (2026-09-17 전수감사 P0).
// 공무원수당규정 §15②(개정 2026.1.2): 기준호봉 봉급액 × 55%(8급 이하 60%) ÷ 209 × 150%.
// 별표12: 일반직 기준호봉 = 해당 계급 10호봉. 봉급 = 공무원보수규정 별표3(개정 2026.1.2).
// 화면 <script> 를 그대로 실행해 결과 DOM 값을 읽는다.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const erb = readFileSync(new URL("app/views/tools/overtime_calculator.html.erb", root), "utf8")
const SCRIPT = erb.match(/<script>([\s\S]*?)<\/script>/)[1]

function run({ grade = "", overtime = "", night = "", holiday = "" }) {
  const values = { "grade-select": grade, "overtime-hours": overtime, "night-hours": night, "holiday-days": holiday }
  const els = new Map()
  const el = (id) => {
    if (!els.has(id)) {
      els.set(id, { value: values[id] ?? "", textContent: "", checked: false, classList: { add() {}, remove() {} } })
    }
    return els.get(id)
  }
  const sandbox = { document: { getElementById: el }, Math, parseInt, parseFloat }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  vm.runInContext(SCRIPT + "\ncalculate()", sandbox)
  const num = (id) => Number(String(el(id).textContent).replace(/[^0-9]/g, ""))
  return { hourly: num("hourly-rate"), total: num("total-pay") }
}

test("NORMAL: 9급 시간당 단가는 10호봉 2,542,700원 × 60% 기준 10,949원", () => {
  assert.equal(run({ grade: "9", overtime: "10" }).hourly, 10949)
})

test("LOWER_BOUND: 8급도 60% — 12,113원 (2026.1.2 개정 전 55%였다면 11,103원)", () => {
  assert.equal(run({ grade: "8", overtime: "1" }).hourly, 12113)
})

test("EDGE: 7급부터 55% — 12,368원 · 6급 13,692원 · 5급 16,053원", () => {
  assert.equal(run({ grade: "7", overtime: "1" }).hourly, 12368)
  assert.equal(run({ grade: "6", overtime: "1" }).hourly, 13692)
  assert.equal(run({ grade: "5", overtime: "1" }).hourly, 16053)
})

test("UPPER_BOUND: 월 57시간 한도 — 60시간 입력은 57시간분만 지급", () => {
  const capped = run({ grade: "9", overtime: "60" }).total
  const exact = run({ grade: "9", overtime: "57" }).total
  assert.equal(capped, exact)
  assert.equal(exact, Math.round(2542700 * 0.6 / 209 * 1.5 * 57))
})

test("EXCEPTION: 계급 미선택이면 계산하지 않는다", () => {
  assert.equal(run({ overtime: "10" }).total, 0)
})
