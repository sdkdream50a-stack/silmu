// GA 로드 전 클릭 보존 회귀 (2026-09-23 · GAP-4 · silmu 연수 전 계측 수리)
// 왜: 운영 layout 은 window.gtag 를 load+2.5s 에 만들었고 next_action_click 은 typeof gtag 를 한 번 보고 버렸다.
// 허브(/school-office) 조회는 있는데 허브 클릭이 0 이던 원인. layout 의 <script> 와 컨트롤러를 실제로 실행해 잰다.
// gtag.js 는 «로드되면 dataLayer 를 앞에서부터 한 번 처리하고 push 를 가로챈다» 만 흉내 낸다.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const root = new URL("../../", import.meta.url)
const LAYOUT = readFileSync(new URL("app/views/layouts/application.html.erb", root), "utf8")
const GA = LAYOUT.match(/<!-- Google Analytics 4[^\n]*\n\s*<script>([\s\S]*?)<\/script>/)[1]
  .replace(/<%= ENV\['GA_MEASUREMENT_ID'\] %>/g, "G-TEST")
const CONTROLLER = readFileSync(new URL("app/javascript/controllers/next_action_controller.js", root), "utf8")
  .replace(/^import .*$/m, "")
  .replace("export default class", "globalThis.NextAction = class")

function page(href = "https://silmu.kr/school-office?utm_source=training&utm_medium=qr") {
  const hits = []
  const timers = []
  const loadListeners = []
  const scripts = []
  const sandbox = {
    Date,
    location: { href },
    setTimeout: (fn, ms) => timers.push([fn, ms]),
    addEventListener: (type, fn) => { if (type === "load") loadListeners.push(fn) },
    document: {
      createElement: () => ({}),
      head: { appendChild: (el) => scripts.push(el) },
    },
  }
  sandbox.window = sandbox
  sandbox.globalThis = sandbox
  vm.createContext(sandbox)
  const runLayout = () => vm.runInContext(GA, sandbox)
  runLayout()
  vm.runInContext(CONTROLLER.replace("class extends Controller", "class"), sandbox)

  // gtag.js 흉내 — 한 번만 로드되고, 로드 시 쌓인 명령을 순서대로 처리한 뒤 push 를 직접 처리로 바꾼다.
  let configured = false
  const process = (args) => {
    const [cmd, name, params] = Array.from(args)
    if (cmd === "config") { configured = true; hits.push({ en: "page_view", dl: sandbox.location.href }) }
    if (cmd === "event" && configured) hits.push({ en: name, dl: (params && params.page_location) || sandbox.location.href, params })
  }
  const loadGtagJs = () => {
    if (sandbox.__gtagLoaded) return
    sandbox.__gtagLoaded = true
    sandbox.dataLayer.forEach(process)
    sandbox.dataLayer.push = (args) => process(args)
  }
  const fireLoad = () => { loadListeners.splice(0).forEach((fn) => fn()); timers.splice(0).forEach(([fn]) => fn()) }
  const click = (slot) => {
    const c = new sandbox.NextAction()
    c.topicSlugValue = "hub:school-office"
    let prevented = false
    const ret = c.track({ params: { slot }, preventDefault: () => { prevented = true } })
    return { ret, prevented }
  }
  const clicks = () => hits.filter((h) => h.en === "next_action_click")
  return { sandbox, hits, clicks, scripts, runLayout, fireLoad, loadGtagJs, click }
}

test("GA 로드 전 클릭 → 큐 1 · 로드 후 전송 1 · 재처리 0", () => {
  const p = page()
  const r = p.click("now:/school-office/calendar")
  assert.equal(p.clicks().length, 0, "로드 전인데 전송됐다")
  assert.equal(p.sandbox.dataLayer.filter((a) => a[0] === "event").length, 1, "큐에 쌓이지 않았다")
  assert.equal(r.prevented, false, "계측이 사용자 이동을 막았다")

  // Turbo 이동으로 URL 이 바뀐 뒤 gtag.js 가 로드되는 상황
  p.sandbox.location.href = "https://silmu.kr/school-office/calendar"
  p.fireLoad()
  assert.equal(p.scripts.length, 1, "gtag.js 삽입이 1회가 아니다")
  p.loadGtagJs()
  assert.equal(p.clicks().length, 1)
  assert.equal(p.clicks()[0].params.slot, "now:/school-office/calendar")
  assert.equal(p.clicks()[0].dl, "https://silmu.kr/school-office?utm_source=training&utm_medium=qr",
    "큐 클릭이 클릭한 페이지(UTM 포함)가 아니라 도착 페이지로 귀속됐다")

  p.loadGtagJs()          // 두 번째 flush
  p.fireLoad()            // load 재발화
  assert.equal(p.clicks().length, 1, "중복 전송")
  assert.equal(p.scripts.length, 1)
})

test("layout 스크립트가 다시 실행돼도(Turbo head merge) config·page_view 는 1회", () => {
  const p = page()
  p.runLayout()
  assert.equal(p.sandbox.dataLayer.filter((a) => a[0] === "config").length, 1)
  p.fireLoad(); p.loadGtagJs()
  assert.equal(p.hits.filter((h) => h.en === "page_view").length, 1)
})

test("GA 가 이미 준비됐으면 클릭은 즉시 1건", () => {
  const p = page()
  p.fireLoad(); p.loadGtagJs()
  p.click("audit:/audit-cases")
  assert.equal(p.clicks().length, 1)
  p.click("audit:/audit-cases")
  assert.equal(p.clicks().length, 2, "서로 다른 클릭은 각각 센다")
})

test("gtag.js 가 차단돼도 클릭은 예외 없이 끝나고 이동을 막지 않는다", () => {
  const p = page()
  p.fireLoad()             // 스크립트 태그는 붙었지만 로드되지 않음(차단)
  const r = p.click("contract:/contract-flow")
  assert.equal(r.prevented, false)
  assert.equal(p.clicks().length, 0)
})

test("payload 에 사용자 식별자 없음 — topic_slug·slot·page_location 뿐", () => {
  const p = page()
  p.click("x:/y")
  const ev = p.sandbox.dataLayer.find((a) => a[0] === "event")
  assert.deepEqual(Object.keys(ev[2]).sort(), ["page_location", "slot", "topic_slug"])
})
