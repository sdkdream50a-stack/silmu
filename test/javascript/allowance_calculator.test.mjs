// 수당 계산기 회귀 (2026-09-17 전수감사 P0).
// 직급보조비: 국가 수당규정 별표15(개정 2026.1.2)·지방 별표14(개정 2026.6.23) — 8·9급 175,000원.
// 정근수당: 별표2(개정 2025.1.3) "2년 미만 10%" — 1년 미만 미지급 구분 삭제.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const erb = readFileSync(new URL("app/views/tools/allowance_calculator.html.erb", root), "utf8")
const SCRIPT = erb.match(/<script>([\s\S]*?)<\/script>/)[1]

function page(values) {
  const els = new Map()
  const el = (id) => {
    if (!els.has(id)) {
      els.set(id, { value: values[id] ?? "", textContent: "", innerHTML: "", classList: { add() {}, remove() {} } })
    }
    return els.get(id)
  }
  const sandbox = { document: { getElementById: el, querySelectorAll: () => [], addEventListener() {} }, addEventListener() {} }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  vm.runInContext(SCRIPT, sandbox)
  return { sandbox, el }
}

const won = (text) => Number(String(text).replace(/[^0-9]/g, "").slice(0, 9))

test("NORMAL: 9급 직급보조비는 175,000원", () => {
  const p = page({ grade: "9" })
  p.sandbox.calculateRank()
  assert.equal(won(p.el("val-rank").textContent), 175000)
})

test("EDGE: 8급 175,000 · 7급 180,000 · 6급 185,000", () => {
  for (const [g, amt] of [["8", 175000], ["7", 180000], ["6", 185000]]) {
    const p = page({ grade: g })
    p.sandbox.calculateRank()
    assert.equal(won(p.el("val-rank").textContent), amt)
  }
})

test("LOWER_BOUND: 근무연수 0년(1년 미만)도 정근수당 10%", () => {
  const p = page({ "monthly-salary": "2133000", "service-years": "0" })
  p.sandbox.calculateJeongeun()
  assert.equal(won(p.el("val-jeongeun").textContent), 213300)
})

test("UPPER_BOUND: 10년 이상 50%", () => {
  const p = page({ "monthly-salary": "3000000", "service-years": "25" })
  p.sandbox.calculateJeongeun()
  assert.equal(won(p.el("val-jeongeun").textContent), 1500000)
})

test("EXCEPTION: 표에 없는 호봉을 고르면 이전 봉급을 지운다", () => {
  const p = page({ grade: "9", step: "25", "monthly-salary": "2542700" })
  p.sandbox.updateSalary()
  assert.equal(p.el("monthly-salary").value, "")
})
