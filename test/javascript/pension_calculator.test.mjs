// 공무원연금 계산기 회귀 (2026-09-17 전수감사 P0 · 2026-09-28 재직 연도별 비율로 정정).
// 공무원연금법 §43①(10년 이상 재직) · §43④(1.7%, 36년 한도) · 부칙(법률 제13387호) 제13조.
// 제13조제3항(«복무기간이 산입된 연도에 해당하는 비율»)·제4항(«2016년 1월 1일 이후의 재직기간에 대한 급여액»)과
// 공단 산정식(«재직기간별 적용비율», 단계적 인하 '16년 1.878%→'35년 1.7%)대로 비율은 재직 연도마다 적용한다.
// 2015년 이전 재직분은 종전 규정 1.9%. (9/17 판은 퇴직 연도 비율을 전 기간에 곱해 2026 퇴직 20년을 약 6% 과소 계산했다)
const Y = { 2016: 1.878, 2017: 1.856, 2018: 1.834, 2019: 1.812, 2020: 1.79, 2021: 1.78, 2022: 1.77, 2023: 1.76, 2024: 1.75, 2025: 1.74,
  2026: 1.736, 2027: 1.732, 2028: 1.728, 2029: 1.724, 2030: 1.72, 2031: 1.716, 2032: 1.712, 2033: 1.708, 2034: 1.704 }
const rateOf = (y) => (y <= 2015 ? 1.9 : Y[y] ?? 1.7)
const expected = (income, tenure, retire) => {
  let sum = 0
  for (let y = retire - tenure; y < retire; y++) sum += rateOf(y)
  return Math.round(income * sum / 100)
}
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const erb = readFileSync(new URL("app/views/tools/pension_calculator.html.erb", root), "utf8")
const SCRIPT = erb.match(/<script>([\s\S]*?)<\/script>/)[1]

function page({ tenure, income, retireYear }) {
  const values = { "tenure-slider": String(tenure), "income-input": String(income) }
  const els = new Map()
  const el = (id) => {
    if (!els.has(id)) {
      const classes = new Set(["hidden"])
      els.set(id, {
        value: values[id] ?? "", textContent: "", style: {},
        classList: {
          add: (c) => classes.add(c),
          remove: (c) => classes.delete(c),
          toggle: (c, on) => (on === undefined ? (classes.has(c) ? classes.delete(c) : classes.add(c)) : (on ? classes.add(c) : classes.delete(c))),
          contains: (c) => classes.has(c),
        },
      })
    }
    return els.get(id)
  }
  const sandbox = { document: { getElementById: el, querySelectorAll: () => [], addEventListener() {} } }
  sandbox.window = sandbox
  vm.createContext(sandbox)
  vm.runInContext(SCRIPT, sandbox)
  if (retireYear) sandbox.selectRetireYear(String(retireYear))
  sandbox.calculate()
  return { sandbox, el }
}

function run({ tenure, income, retireYear }) {
  const { el } = page({ tenure, income, retireYear })
  return Number(String(el("result-pension-monthly").textContent).replace(/[^0-9]/g, ""))
}

test("NORMAL: 2026년 퇴직 20년 · 평균 400만원 → 2006~15 1.9% + 2016~25 연도별 비율 = 1,478,800원", () => {
  assert.equal(run({ tenure: 20, income: 4000000, retireYear: 2026 }), 1478800)
  assert.equal(expected(4000000, 20, 2026), 1478800)
})

test("EDGE: 퇴직 연도가 바뀌면 재직 연도 구간이 바뀐다 (2030년 퇴직 20년)", () => {
  assert.equal(run({ tenure: 20, income: 4000000, retireYear: 2030 }), expected(4000000, 20, 2030))
})

test("UPPER_BOUND: 36년 초과는 36년으로 — 2035년 퇴직 36년(1999~2034)", () => {
  assert.equal(run({ tenure: 40, income: 4000000, retireYear: 2035 }), expected(4000000, 36, 2035))
})

test("LOWER_BOUND: 10년 미만 입력은 10년으로 올려 계산(슬라이더 최소 10년) — 2016~2025 연도별", () => {
  assert.equal(run({ tenure: 5, income: 4000000, retireYear: 2026 }), expected(4000000, 10, 2026))
})

test("NEGATIVE: 퇴직 연도 비율을 전 기간에 곱하던 값(1,388,800원)이 아니다", () => {
  assert.notEqual(run({ tenure: 20, income: 4000000, retireYear: 2026 }), Math.round(4000000 * 20 * 0.01736))
})

// 2026-09-28 감사 P2 — 음수/0 입력이 그대로 계산되거나(음수) 직전 결과가 잔존한다(0).
test("INVALID: 기준소득월액 음수는 계산을 거부하고 초기 안내로 되돌린다", () => {
  const { el } = page({ tenure: 20, income: -100, retireYear: 2026 })
  assert.equal(el("result-pension-monthly").textContent, "정보를 입력하세요")
  assert.equal(el("result-placeholder-pension").classList.contains("hidden"), false)
})

test("INVALID: 정상 계산 후 0을 입력하면 직전 결과가 아니라 초기 안내로 되돌린다", () => {
  const { sandbox, el } = page({ tenure: 20, income: 4000000, retireYear: 2026 })
  assert.notEqual(el("result-pension-monthly").textContent, "정보를 입력하세요")
  el("income-input").value = "0"
  sandbox.calculate()
  assert.equal(el("result-pension-monthly").textContent, "정보를 입력하세요")
  assert.equal(el("result-pension-2026-block").classList.contains("hidden"), true)
})

// 2026-09-28 감사 P2 — "2026년 2.1% 인상 후"가 선택한 퇴직연도와 무관하게 항상 ×1.021 적용됐다.
// 2.1%는 2025→2026 물가상승률(확정값)에만 성립하므로 2026년 퇴직 선택 시에만 보여준다.
test("DISPLAY: 2026년 퇴직 선택 시에만 2.1% 인상 블록을 보여준다", () => {
  const { el } = page({ tenure: 20, income: 4000000, retireYear: 2026 })
  assert.equal(el("result-pension-2026-block").classList.contains("hidden"), false)
  assert.equal(el("result-pension-2026").textContent, Math.round(1478800 * 1.021).toLocaleString("ko-KR") + "원")
})

test("DISPLAY: 2026년이 아닌 퇴직연도를 선택하면 미검증 2.1% 인상 블록을 숨긴다", () => {
  const { el } = page({ tenure: 20, income: 4000000, retireYear: 2030 })
  assert.equal(el("result-pension-2026-block").classList.contains("hidden"), true)
})
