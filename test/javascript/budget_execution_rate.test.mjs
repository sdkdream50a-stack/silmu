// 예산 집행률 «균등 배분 참고선» 회귀 (2026-09-18 LECTURE_READINESS P0-2).
//
// 막는 것: 학교회계(3.1~2.28) 사용자가 9월에 «75%» 를 참고선으로 받는 것.
//   회계연도 시작 1월 → 9월은 9개월 경과 → 75.0%
//   회계연도 시작 3월 → 9월은 7개월 경과 → 58.3%   ← 수리 전에는 이것이 나오지 않았다
//
// 화면 <script> 를 그대로 실행해 함수 결과를 읽는다(overtime_calculator.test.mjs 와 같은 방식).
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const erb = readFileSync(new URL("app/views/tools/budget_execution_rate.html.erb", root), "utf8")
const SCRIPT = erb.match(/<script>([\s\S]*?)<\/script>/)[1]

// baseMonth·fiscalStart 를 select 값으로 주고 참고선(%)을 돌려받는다.
function referenceRate({ baseMonth, fiscalStart }) {
  const values = { "base-month": String(baseMonth), "fiscal-start-month": String(fiscalStart) }
  const els = new Map()
  const el = (id) => {
    if (!els.has(id)) {
      els.set(id, {
        value: values[id] ?? "",
        textContent: "",
        style: {},
        className: "",
        innerHTML: "",
        classList: { add() {}, remove() {} }
      })
    }
    return els.get(id)
  }
  const sandbox = {
    document: { getElementById: el, querySelectorAll: () => [], addEventListener() {}, cookie: "" },
    Math, parseInt, parseFloat, Number, String
  }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  vm.runInContext(SCRIPT, sandbox)
  return sandbox.referenceRatePercent()
}

test("지방자치단체(1월 시작) 9월 참고선 = 75.0%", () => {
  assert.equal(referenceRate({ baseMonth: 9, fiscalStart: 1 }).toFixed(1), "75.0")
})

test("학교회계(3월 시작) 9월 참고선 = 58.3% — 75% 가 아니다", () => {
  const rate = referenceRate({ baseMonth: 9, fiscalStart: 3 })
  assert.equal(rate.toFixed(1), "58.3")
  assert.notEqual(rate.toFixed(1), "75.0", "학교회계에 지자체 참고선이 나온다")
})

test("경계 — 회계연도 첫 달은 1개월 경과(8.3%)", () => {
  assert.equal(referenceRate({ baseMonth: 1, fiscalStart: 1 }).toFixed(1), "8.3")
  assert.equal(referenceRate({ baseMonth: 3, fiscalStart: 3 }).toFixed(1), "8.3")
})

test("경계 — 회계연도 마지막 달은 12개월 경과(100%)", () => {
  assert.equal(referenceRate({ baseMonth: 12, fiscalStart: 1 }).toFixed(1), "100.0")
  assert.equal(referenceRate({ baseMonth: 2, fiscalStart: 3 }).toFixed(1), "100.0")
})

test("연도 경계 랩어라운드 — 3월 시작 회계연도의 1월은 11개월 경과", () => {
  assert.equal(referenceRate({ baseMonth: 1, fiscalStart: 3 }).toFixed(1), "91.7")
})

test("12개월 전체가 1~12개월 경과로 정확히 한 번씩 매핑된다(3월 시작)", () => {
  const elapsed = []
  for (let m = 1; m <= 12; m++) {
    elapsed.push(Math.round((referenceRate({ baseMonth: m, fiscalStart: 3 }) / 100) * 12))
  }
  assert.deepEqual([...elapsed].sort((a, b) => a - b), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
})

test("예외 — fiscal-start-month 가 비어 있거나 범위 밖이면 1월로 떨어진다", () => {
  assert.equal(referenceRate({ baseMonth: 9, fiscalStart: "" }).toFixed(1), "75.0")
  assert.equal(referenceRate({ baseMonth: 9, fiscalStart: 99 }).toFixed(1), "75.0")
})

// 음성 대조 — 출처 없는 분기 목표치(25/50/75/90)가 화면에 되살아나지 않는다.
test("출처 없는 분기 목표율이 화면에 없다", () => {
  assert.equal(/quarter_targets\s*=/.test(erb), false, "quarter_targets 가 다시 생겼다")
  assert.equal(/다음 분기말 목표/.test(erb), false, "출처 없는 분기말 목표 카드가 다시 생겼다")
  assert.equal(/연말\(12월\): 90% 이상/.test(erb), false, "출처 없는 12월 90% 기준이 다시 생겼다")
})

// 음성 대조 — 법령이 집행 목표율을 정한다는 단정이 되살아나지 않는다.
test("지방재정법이 집행 목표율을 정한다는 단정이 없다", () => {
  assert.equal(
    /달성해야 하며, 미달 시 다음 연도 예산 삭감/.test(erb),
    false,
    "법령 근거 없는 의무 단정이 다시 생겼다"
  )
})
