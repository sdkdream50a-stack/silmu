// calc_complete·글 귀속 계측 회귀 (2026-09-14 · silmu-lead-attribution-tool-completion-v1)
// 왜 이 테스트가 있나: 같은 repo 에서 «gtag 가 늦게 정의되는데 스크립트가 파싱 시점에 typeof 검사로 return» 결함이
// 2026-06-27(/start) 과 2026-09-12(_tool_analytics) 두 번 났다. 렌더·request test 는 둘 다 GREEN 이었다.
// jsdom 을 들이지 않고, partial 의 <script> 를 실제로 실행해 gtag 호출을 기록한다 — 소스 문자열 검사가 아니라 동작 검사.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const scriptOf = (path) => readFileSync(new URL(path, root), "utf8").match(/<script>([\s\S]*)<\/script>/)[1]
const TOOL = scriptOf("app/views/shared/_tool_analytics.html.erb")
const SOURCE = scriptOf("app/views/shared/_source_attribution.html.erb")
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

function page({ search = "", gtagNow = true } = {}) {
  const calls = []
  const store = new Map()
  const listeners = []
  const sandbox = {
    setTimeout, clearTimeout, setInterval, clearInterval, URL, URLSearchParams,
    location: { pathname: "/tools/overtime-calculator", search, href: "http://x/tools/overtime-calculator" + search },
    sessionStorage: { getItem: (k) => (store.has(k) ? store.get(k) : null), setItem: (k, v) => store.set(k, String(v)), removeItem: (k) => store.delete(k) },
    document: { addEventListener: (...a) => listeners.push(a), getElementById: () => null, visibilityState: "visible" },
    addEventListener: () => {},
  }
  sandbox.window = sandbox
  const gtag = (...args) => calls.push(args)
  if (gtagNow) sandbox.gtag = gtag
  vm.createContext(sandbox)
  vm.runInContext(SOURCE, sandbox)
  vm.runInContext(TOOL, sandbox)
  const calc = () => calls.filter((c) => c[0] === "event" && c[1] === "calc_complete")
  return { sandbox, calls, calc, defineGtag: () => { sandbox.gtag = gtag } }
}

test("gtag 가 스크립트 실행 뒤에 정의돼도 calc_complete 가 전달된다 (운영 layout = load+2.5s)", async () => {
  const p = page({ gtagNow: false })
  p.sandbox.silmuCalcResult("2500000|0.55|10|0|0", { immediate: true })
  assert.equal(p.calc().length, 0)
  p.defineGtag()
  await sleep(1200)
  assert.equal(p.calc().length, 1)
})

test("같은 결과는 한 번만 · 서로 다른 결과는 각각 · null 은 대기 취소", async () => {
  const p = page()
  p.sandbox.silmuCalcResult("a", { immediate: true })
  p.sandbox.silmuCalcResult("a", { immediate: true })
  assert.equal(p.calc().length, 1)
  p.sandbox.silmuCalcResult("b")
  p.sandbox.silmuCalcResult(null)
  await sleep(1700)
  assert.equal(p.calc().length, 1, "무효로 바뀐 대기 결과가 전송됐다")
  p.sandbox.silmuCalcResult("c")
  await sleep(1700)
  assert.equal(p.calc().length, 2)
})

test("payload 는 tool_slug(+source_post) 뿐 — 입력 요약(signature)은 전송하지 않는다", () => {
  const p = page()
  p.sandbox.silmuCalcResult("2500000|0.55|10|0|0", { immediate: true })
  const [, , params] = p.calc()[0]
  assert.deepEqual(Object.keys(params), ["tool_slug"])
  assert.equal(params.tool_slug, "overtime-calculator")
  assert.ok(!JSON.stringify(p.calls).includes("2500000"))
})

test("규약 착지의 utm_content(logNo)만 source_post 로 실리고, 모르면 키가 없다", () => {
  const utm = "?utm_source=naver_blog&utm_medium=referral&utm_campaign=silmu_naver&utm_content="
  const withPost = page({ search: utm + "224243216770" })
  withPost.sandbox.silmuCalcResult("x", { immediate: true })
  assert.equal(withPost.calc()[0][2].source_post, "224243216770")

  for (const search of [utm + "cta_card", "?utm_source=naver_blog&utm_medium=referral&utm_campaign=other&utm_content=224243216770", ""]) {
    const p = page({ search })
    p.sandbox.silmuCalcResult("x", { immediate: true })
    assert.ok(!("source_post" in p.calc()[0][2]), `source_post 가 실렸다: ${search}`)
  }
})
