// 적격심사·종심제 Stimulus 컨트롤러 회귀 테스트 (2026-08-04 P1·P2 교정).
// jsdom을 새로 들이지 않고, 컨트롤러가 실제로 만지는 표면(target·element·fetch)만 대역으로 세워
// 프로토타입 메서드를 그대로 호출한다. 소스 문자열 검사가 아니라 동작 검사다.
import { test } from "node:test"
import assert from "node:assert/strict"

import Ctrl from "../../app/javascript/controllers/qualification_evaluation_controller.js"

function fakeEl(attrs = {}) {
  return {
    value: attrs.value ?? "",
    textContent: "",
    innerHTML: "",
    className: "",
    dataset: attrs.dataset ?? {},
    classList: {
      _set: new Set(attrs.classes ?? []),
      add(c) { this._set.add(c) },
      remove(c) { this._set.delete(c) },
      toggle(c, force) { if (force) this._set.add(c); else this._set.delete(c) },
      contains(c) { return this._set.has(c) }
    },
    scrollIntoView() {}
  }
}

// 배너·모드 전환에 필요한 최소 대역을 갖춘 컨트롤러 인스턴스
function buildController({ presumedPrice = "", projectType = "construction", bidderCount = "3", bidderInputs = [] } = {}) {
  const c = Object.create(Ctrl.prototype)

  const presumed = fakeEl({ value: presumedPrice })
  const ptype = fakeEl({ value: projectType })
  const floorRate = fakeEl({ value: "" })
  const count = fakeEl({ value: bidderCount })

  // Controller.prototype의 element는 getter라 대입이 막힌다 → 인스턴스에 정의해 가린다.
  Object.defineProperty(c, "element", {
    value: {
      querySelector(sel) {
        if (sel.includes("presumed_price")) return presumed
        if (sel.includes("project_type")) return ptype
        if (sel.includes("bidder_count")) return count
        return null
      },
      // 이미 입력돼 있는 업체 입력란. 실제 DOM에서 컨트롤러가 값을 되살릴 때 읽는 자리다.
      querySelectorAll(sel) {
        return sel.includes("bidder_") ? bidderInputs : []
      }
    },
    configurable: true
  })

  c.mode = "qualification"
  c.hasPriceBannerTarget = true
  c.priceBannerTarget = fakeEl({ classes: ["hidden"] })
  c.hasResultTarget = true
  c.resultTarget = fakeEl({ classes: ["hidden"] })

  c.modeTabTargets = [
    fakeEl({ dataset: { mode: "qualification" } }),
    fakeEl({ dataset: { mode: "comprehensive" } })
  ]
  c.hasQualificationInfoTarget = true
  c.qualificationInfoTarget = fakeEl()
  c.hasComprehensiveInfoTarget = true
  c.comprehensiveInfoTarget = fakeEl()
  c.hasProjectTypeSectionTarget = true
  c.projectTypeSectionTarget = fakeEl()
  c.hasFloorRateNoteTarget = true
  c.floorRateNoteTarget = fakeEl()
  c.hasSubmitBtnTextTarget = true
  c.submitBtnTextTarget = fakeEl()
  c.floorRateContainerTarget = { querySelector: () => floorRate }
  // 실제 렌더를 그대로 돌린다. 여기를 no-op으로 막으면 "다시 그려서 입력이 지워지는" 결함을 놓친다.
  c.hasBidderFieldsTarget = true
  c.bidderFieldsTarget = fakeEl()

  return { c, presumed, ptype, floorRate }
}

test("422 차단 사유는 화면에 표시된다", async () => {
  const { c } = buildController()
  let resultRendered = false
  c.displayResult = () => { resultRendered = true }

  const prevFetch = global.fetch
  const prevDoc = global.document
  const prevFD = global.FormData
  global.FormData = class { constructor(form) { this.form = form } }
  global.document = { querySelector: () => ({ content: "csrf-token" }) }
  global.fetch = async () => ({
    ok: false,
    status: 422,
    json: async () => ({ error: "추정가격 300억원 이상 공사는 종합심사낙찰제(종심제) 대상입니다." })
  })

  try {
    await c.submit({ preventDefault() {}, target: { action: "/qualification-evaluations/evaluate" } })
  } finally {
    global.fetch = prevFetch
    global.document = prevDoc
    global.FormData = prevFD
  }

  assert.match(c.resultTarget.innerHTML, /종합심사낙찰제/, "차단 사유가 결과 영역에 렌더돼야 한다")
  assert.equal(c.resultTarget.classList.contains("hidden"), false, "결과 영역이 보여야 한다")
  assert.equal(resultRendered, false, "422 본문을 정상 결과로 렌더하면 안 된다")
})

test("200 응답은 정상 결과 경로로 간다", async () => {
  const { c } = buildController()
  let rendered = null
  c.displayResult = (data) => { rendered = data }

  const prevFetch = global.fetch
  const prevDoc = global.document
  const prevFD = global.FormData
  global.FormData = class { constructor(form) { this.form = form } }
  global.document = { querySelector: () => ({ content: "csrf-token" }) }
  global.fetch = async () => ({ ok: true, status: 200, json: async () => ({ mode: "qualification" }) })

  try {
    await c.submit({ preventDefault() {}, target: { action: "/qualification-evaluations/evaluate" } })
  } finally {
    global.fetch = prevFetch
    global.document = prevDoc
    global.FormData = prevFD
  }

  assert.deepEqual(rendered, { mode: "qualification" })
})

test("300억 배너는 추정가격 기준이고 공사에만 뜬다", () => {
  const under = buildController({ presumedPrice: "29999999999" })
  under.c.checkThreshold()
  assert.equal(under.c.priceBannerTarget.classList.contains("hidden"), true, "300억 미만이면 뜨지 않는다")

  const over = buildController({ presumedPrice: "30000000000" })
  over.c.checkThreshold()
  assert.equal(over.c.priceBannerTarget.classList.contains("hidden"), false, "정확히 300억이면 뜬다")

  const service = buildController({ presumedPrice: "31000000000", projectType: "service" })
  service.c.checkThreshold()
  assert.equal(service.c.priceBannerTarget.classList.contains("hidden"), true, "종심제는 공사 대상이라 용역엔 뜨지 않는다")
})

test("종심제로 갔다가 적격심사로 돌아오면 300억 배너가 되살아난다", () => {
  const { c } = buildController({ presumedPrice: "30000000000" })

  c.checkThreshold()
  assert.equal(c.priceBannerTarget.classList.contains("hidden"), false, "먼저 배너가 떠 있어야 한다")

  c._applyMode("comprehensive")
  assert.equal(c.priceBannerTarget.classList.contains("hidden"), true, "종심제에서는 숨는다")

  c._applyMode("qualification")
  assert.equal(c.priceBannerTarget.classList.contains("hidden"), false,
    "적격심사로 복귀하면 경고가 다시 떠야 한다 — 숨은 채 남으면 사전 경고 없이 제출된다")
})

test("모드를 바꾸면 이전 모드의 낙찰하한율이 남지 않는다", () => {
  const { c, floorRate } = buildController()
  floorRate.value = "80"

  c._applyMode("comprehensive")

  assert.equal(floorRate.value, "", "이전 계약유형의 공고문 값이 남으면 확인 없이 그대로 제출된다")
})

// 소스 문자열 검사는 동적 보간(`${...max}`)이나 표기 변경("20.0")으로 뚫린다.
// 실제로 렌더된 결과물을 검사해야 의미가 같은 회귀를 잡는다.
// 인라인 강조(<strong> 등)는 문장을 끊지 않는다 — 끊으면 같은 문장 안의 단서를 놓쳐 오탐이 난다.
const INLINE_TAGS = /<\/?(?:strong|b|em|i|span|small|u|code|br)\b[^>]*>/gi

function textSegments(html) {
  return html.replace(INLINE_TAGS, "").replace(/<[^>]*>/g, "\n")
    .split("\n").map(s => s.trim()).filter(Boolean)
}

const SCORE_ITEMS = ["가격", "시공실적", "시공능력", "경영상태", "사회적책임"]

// "가격50", "가격: 50점", "= 100 점"처럼 표기를 바꿔도 같은 단정이다.
// 정확 문구가 아니라 "배점 항목이 숫자와 함께 둘 이상 나열되는가"로 판정한다.
function isScoreClaim(segment) {
  if (/총점\s*[:：(（[]?\s*\d+\s*점/.test(segment)) return true
  if (/=\s*\d+\s*점/.test(segment)) return true
  // 괄호 표기("가격(50점)")도 같은 단정이다 → 숫자 앞의 여는 기호를 허용한다.
  return SCORE_ITEMS.filter(item =>
    new RegExp(`${item}\\s*[:：(（[]?\\s*\\d`).test(segment)).length >= 2
}

// 표는 열 순서가 바뀔 수 있다 → 헤더에서 열 위치를 파생해 셀을 읽는다.
function cellUnderHeader(html, headerPattern, rowKey) {
  const headers = (html.match(/<th[\s\S]*?<\/th>/g) || [])
    .map(th => th.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim())
  const col = headers.findIndex(h => headerPattern.test(h))
  assert.ok(col >= 0, `헤더 ${headerPattern}를 찾지 못했다 — 통과가 아니라 대상을 놓친 것이다`)

  const row = (html.match(/<tr[\s\S]*?<\/tr>/g) || []).find(r => r.includes(rowKey))
  assert.ok(row, `${rowKey} 행을 찾지 못했다 — 통과가 아니라 대상을 놓친 것이다`)

  const cells = (row.match(/<td[\s\S]*?<\/td>/g) || [])
    .map(td => td.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim())
  return cells[col]
}

test("렌더된 종심제 결과에 배점·총점 단정이 참고 표시 없이 남지 않는다", () => {
  const { c } = buildController()
  c.mode = "comprehensive"

  c._displayComprehensiveResult({
    mode: "comprehensive",
    score_unavailable: true,
    notice: "별표 산식 미지원",
    winner: null,
    bidders: [ {
      name: "A", bid_price: 38_000_000_000, bid_ratio: 95.0,
      construction: 20, capacity: 15, management: 10, social: 5,
      non_price_total: 50, total_score: null, is_qualified: null, below_floor: false
    } ],
    metadata: {
      estimated_price: 40_000_000_000, floor_rate: 89.745, floor_price: 35_898_000_000,
      score_structure: {
        price: { name: "가격", max: 50 }, construction: { name: "시공실적", max: 20 },
        capacity: { name: "시공능력", max: 15 }, management: { name: "경영상태", max: 10 },
        social: { name: "사회적책임", max: 5 }
      }
    }
  })

  for (const seg of textSegments(c.resultTarget.innerHTML)) {
    if (isScoreClaim(seg)) {
      assert.match(seg, /참고|공고문/,
        `미확인 배점·총점을 참고 표시 없이 렌더하고 있다 — "${seg.slice(0, 90)}"`)
    }
  }

  // 서버가 총점을 nil로 보냈으면 총점 칸에는 다른 값이 대신 들어가면 안 된다.
  // 비가격 소계(50)를 총점 자리에 넣으면 사용자는 산출되지 않은 총점을 본 것이 된다.
  const total = cellUnderHeader(c.resultTarget.innerHTML, /^총점/, "A")
  assert.equal(total, "—",
    `총점을 산출하지 않는데 총점 칸에 "${total}"이 표시됐다`)
})

test("렌더된 종심제 입력은 미확인 참고 배점을 상한으로 강제하지 않는다", () => {
  const { c } = buildController()
  c.mode = "comprehensive"
  c.bidderFieldsTarget = fakeEl()

  c._renderComprehensiveBidderFields(1)

  const html = c.bidderFieldsTarget.innerHTML
  // 특정 값 몇 개만 금지하면 19 같은 값으로 여전히 막을 수 있다.
  // "제한적 상한이 없을 것"을 요구한다 — 없거나, 참고 배점을 가리지 않는 일반 상한(100 이상)이어야 한다.
  const PERMISSIVE_MAX = 100
  const fields = ["construction", "capacity", "management", "social"]

  for (const field of fields) {
    const input = html.match(new RegExp(`<input[^>]*name="bidder_1_${field}"[^>]*>`))
    assert.ok(input, `${field} 입력을 찾지 못했다 — 통과가 아니라 대상을 놓친 것이다`)

    // 따옴표 종류·생략·공백까지 허용해서 뽑는다. max=20 / max = "20" / max='20' 전부 같은 상한이다.
    const max = input[0].match(/\bmax\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/)
    if (max) {
      const value = Number(max[1] ?? max[2] ?? max[3])
      assert.ok(Number.isFinite(value) && value >= PERMISSIVE_MAX,
        `${field}: 상한 ${value}는 공고문 배점이 다를 때 정당한 값을 막는다 — 상한을 두지 않거나 ${PERMISSIVE_MAX} 이상이어야 한다`)
    }
  }
})

test("용역을 고른 채 종심제에 다녀와도 공사 참고값을 안내하지 않는다", () => {
  const { c } = buildController({ projectType: "service" })

  c._applyMode("comprehensive")
  c._applyMode("qualification")

  const note = c.floorRateNoteTarget.textContent
  assert.match(note, /용역/, `용역인데 안내가 "${note}"다`)
  assert.doesNotMatch(note, /공사 참고값/,
    "용역 사용자가 공사 참고값 89.745%를 입력하면 하한가·미달 여부가 잘못 산출된다")
})

test("사업 종류를 바꾸면 안내와 입력이 그 종류를 따른다", () => {
  const { c, ptype, floorRate } = buildController()
  floorRate.value = "89.745"

  ptype.value = "service"
  c.updateScoreStructure()

  assert.match(c.floorRateNoteTarget.textContent, /용역/)
  assert.equal(floorRate.value, "", "이전 종류의 공고문 값이 남으면 안 된다")

  ptype.value = "construction"
  c.updateScoreStructure()
  assert.match(c.floorRateNoteTarget.textContent, /공사/)
})

test("같은 모드 탭을 다시 눌러도 입력한 값이 지워지지 않는다", () => {
  const { c, floorRate } = buildController()
  floorRate.value = "89.745"
  c.bidderFieldsTarget.innerHTML = "<!--사용자가 입력해 둔 업체 정보-->"

  c._applyMode("qualification") // 이미 qualification 모드

  assert.equal(floorRate.value, "89.745", "모드가 바뀌지 않았는데 공고문 값을 지우면 사용자가 다시 입력해야 한다")
  assert.equal(c.bidderFieldsTarget.innerHTML, "<!--사용자가 입력해 둔 업체 정보-->",
    "업체 입력란을 다시 그리면 입력해 둔 업체 정보가 전부 사라진다")
})

test("모드가 실제로 바뀌면 업체 입력란은 그 모드에 맞게 다시 그린다", () => {
  const { c } = buildController()
  c.bidderFieldsTarget.innerHTML = "<!--이전 모드 입력-->"

  c._applyMode("comprehensive")

  assert.notEqual(c.bidderFieldsTarget.innerHTML, "<!--이전 모드 입력-->",
    "모드가 바뀌면 그 모드의 입력 항목으로 다시 그려야 한다")
})

test("낙찰하한율 안내는 특정 숫자를 권하지 않는다", () => {
  // 공사 하한율은 추정가격 구간별로 갈린다(89.745 / 88.745 / 87.495 / 81.995).
  // 한 값을 참고값으로 권하면 다른 구간 사용자가 그대로 넣어 하한가·미달 판정이 틀린다.
  const construction = buildController()
  construction.c._setFloorRateNote(false)
  assert.doesNotMatch(construction.c.floorRateNoteTarget.textContent, /\d+\.\d+\s*%/)

  const service = buildController({ projectType: "service" })
  service.c._setFloorRateNote(false)
  assert.doesNotMatch(service.c.floorRateNoteTarget.textContent, /\d+\.\d+\s*%/)

  const comprehensive = buildController()
  comprehensive.c._setFloorRateNote(true)
  assert.doesNotMatch(comprehensive.c.floorRateNoteTarget.textContent, /\d+\.\d+\s*%/,
    "종심제는 300억 이상 구간인데 89.745%를 권하면 특히 어긋난다")
})

test("업체 수를 바꿔도 입력해 둔 업체 정보가 남는다", () => {
  const { c } = buildController({
    bidderCount: "4",
    bidderInputs: [
      { name: "bidder_1_name", value: "(주)가나건설" },
      { name: "bidder_1_price", value: "450000000" },
      { name: "bidder_2_name", value: "(주)다라건설" },
      { name: "bidder_count", value: "4" } // 업체 값이 아니므로 복원 대상이 아니다
    ]
  })

  c.updateBidderFields()

  const html = c.bidderFieldsTarget.innerHTML
  assert.match(html, /value="\(주\)가나건설"/, "업체 수만 바꿨는데 입력한 업체명이 사라지면 안 된다")
  assert.match(html, /value="450000000"/)
  assert.match(html, /value="\(주\)다라건설"/)
})

test("조건이 바뀐 뒤 늦게 도착한 응답은 버린다", async () => {
  const { c } = buildController()
  let release
  const pending = new Promise(resolve => { release = resolve })

  const prevFetch = global.fetch
  const prevDoc = global.document
  const prevFD = global.FormData
  global.FormData = class { constructor(form) { this.form = form } }
  global.document = { querySelector: () => ({ content: "csrf-token" }) }
  global.fetch = async () => {
    await pending
    return { ok: true, status: 200, json: async () => ({ mode: "qualification" }) }
  }

  let rendered = false
  c.displayResult = () => { rendered = true }

  const inFlight = c.submit({ preventDefault() {}, target: { action: "/x" } })
  c._applyMode("comprehensive") // 응답을 기다리는 동안 조건이 바뀐다
  release()
  await inFlight

  global.fetch = prevFetch
  global.document = prevDoc
  global.FormData = prevFD

  assert.equal(rendered, false,
    "바뀐 조건 위에 옛 요청의 판정이 그려지면 사용자는 지금 조건의 결과로 읽는다")
})

test("입력 변경 뒤 늦게 도착한 응답은 버린다", async () => {
  const { c } = buildController()
  let release
  const pending = new Promise(resolve => { release = resolve })

  const prevFetch = global.fetch
  const prevDoc = global.document
  const prevFD = global.FormData
  global.FormData = class { constructor(form) { this.form = form } }
  global.document = { querySelector: () => ({ content: "csrf-token" }) }
  global.fetch = async () => {
    await pending
    return { ok: true, status: 200, json: async () => ({ mode: "qualification" }) }
  }

  let rendered = false
  c.displayResult = () => { rendered = true }
  const inFlight = c.submit({ preventDefault() {}, target: { action: "/x" } })
  c.inputChanged()
  release()
  await inFlight

  global.fetch = prevFetch
  global.document = prevDoc
  global.FormData = prevFD
  assert.equal(rendered, false, "입력값을 바꾼 뒤 이전 조건의 응답을 표시하면 안 된다")
})

test("중복 제출 응답 순서가 뒤집혀도 최신 결과만 표시한다", async () => {
  const { c } = buildController()
  const releases = []
  const prevFetch = global.fetch
  const prevDoc = global.document
  const prevFD = global.FormData
  global.FormData = class { constructor(form) { this.form = form } }
  global.document = { querySelector: () => ({ content: "csrf-token" }) }
  global.fetch = () => new Promise(resolve => releases.push(resolve))

  const rendered = []
  c.displayResult = data => { rendered.push(data.request) }
  const first = c.submit({ preventDefault() {}, target: { action: "/x" } })
  const second = c.submit({ preventDefault() {}, target: { action: "/x" } })

  releases[1]({ ok: true, json: async () => ({ mode: "qualification", request: "second" }) })
  await second
  releases[0]({ ok: true, json: async () => ({ mode: "qualification", request: "first" }) })
  await first

  global.fetch = prevFetch
  global.document = prevDoc
  global.FormData = prevFD
  assert.deepEqual(rendered, ["second"])
})

test("산출 조건이 바뀌면 이전 결과를 남기지 않는다", () => {
  const modeChange = buildController()
  modeChange.c.resultTarget.innerHTML = "<div>적격심사 결과</div>"
  modeChange.c.resultTarget.classList.remove("hidden")

  modeChange.c._applyMode("comprehensive")

  assert.equal(modeChange.c.resultTarget.innerHTML, "",
    "모드가 바뀌었는데 이전 결과가 남으면 다른 조건의 판정을 보고 판단하게 된다")
  assert.equal(modeChange.c.resultTarget.classList.contains("hidden"), true)

  const typeChange = buildController()
  typeChange.c.resultTarget.innerHTML = "<div>공사 결과</div>"
  typeChange.c.resultTarget.classList.remove("hidden")

  typeChange.ptype.value = "service"
  typeChange.c.updateScoreStructure()

  assert.equal(typeChange.c.resultTarget.innerHTML, "",
    "사업 종류가 바뀌었는데 이전 결과가 남으면 안 된다")
})
