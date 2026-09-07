// 모의고사 «이어풀기» 결정 로직 회귀 (2026-09-07 문의 대응).
//
// 소스 문자열 검사가 아니라 동작 검사다. 컨트롤러가 `../exam_progress` 처럼
// 확장자 없는 import 를 쓰므로 node 가 직접 못 읽는다 — esbuild 로 번들해서
// 프로토타입 메서드를 그대로 호출한다. node_modules 가 없으면 건너뛴다.
import { test, beforeEach } from "node:test"
import assert from "node:assert/strict"
import { execFileSync } from "node:child_process"
import { existsSync, mkdtempSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

const ESBUILD = "node_modules/.bin/esbuild"
const SOURCE = "app/javascript/controllers/exam_quiz_controller.js"

class FakeStorage {
  constructor() { this.map = new Map() }
  getItem(k) { return this.map.has(k) ? this.map.get(k) : null }
  setItem(k, v) { this.map.set(k, String(v)) }
  removeItem(k) { this.map.delete(k) }
}
globalThis.localStorage = new FakeStorage()
globalThis.window = globalThis
globalThis.document = { addEventListener() {}, removeEventListener() {} }
globalThis.addEventListener = () => {}
globalThis.removeEventListener = () => {}

let Ctrl = null
if (existsSync(ESBUILD)) {
  const out = join(mkdtempSync(join(tmpdir(), "exam-quiz-")), "bundle.mjs")
  execFileSync(ESBUILD, [ SOURCE, "--bundle", "--format=esm", "--target=es2020", `--outfile=${out}` ], { stdio: "pipe" })
  Ctrl = (await import(out)).default
}
// node_modules 없이 (예: 루비 전용 CI) 돌 때는 조용히 건너뛴다
const opts = Ctrl ? {} : { skip: "node_modules/.bin/esbuild 없음 — `npm install` 후 실행" }

const QS = (n, base = 1000) =>
  Array.from({ length: n }, (_, i) => ({ id: base + i, subject_id: 1, chapter_num: 1, difficulty: "basic" }))

function makeCtrl({ subjectId = "1", chapterNum = 0, questions = QS(120), signedIn = false } = {}) {
  // Stimulus Controller 프로토타입의 element 등이 getter 라 단순 대입이 막힌다
  const c = Object.create(Ctrl.prototype)
  const set = (k, v) => Object.defineProperty(c, k, { value: v, writable: true, configurable: true })
  set("element", { dataset: { examQuizSubjectIdValue: subjectId, examQuizChapterNumValue: String(chapterNum) } })
  set("questionsValue", questions)
  set("currentValue", 0)
  set("scoreValue", 0)
  set("signedInValue", signedIn)
  set("wrongModeValue", false)
  set("bookmarkModeValue", false)
  set("wrongByChapter", {})
  set("totalByChapter", {})
  set("diffStats", { basic: { total: 0, wrong: 0 }, advanced: { total: 0, wrong: 0 } })
  set("hasScoreDisplayTarget", true)
  set("scoreDisplayTarget", { textContent: "0" })
  set("synced", [])
  set("syncToServer", (...a) => { c.synced.push(a) })
  return c
}

const savedFor = (over = {}) =>
  JSON.stringify({ "1": Object.assign({ current: 42, qid: 1042, total: 120, score: 30, savedAt: 1 }, over) })
const stored = () => JSON.parse(globalThis.localStorage.getItem("exam_quiz_in_progress") || "{}")

beforeEach(() => { globalThis.localStorage = new FakeStorage() })

// ── 어떤 퀴즈가 이어풀기 대상인가 ───────────────────────────────
test("과목 모의고사·전체 모의고사는 이어풀기 대상이다", opts, () => {
  assert.equal(makeCtrl({ subjectId: "1" })._resumeKey, "1")
  assert.equal(makeCtrl({ subjectId: "all" })._resumeKey, "all")
})

test("챕터 문제는 과목과 다른 키로 따로 이어진다", opts, () => {
  assert.equal(makeCtrl({ subjectId: "2", chapterNum: 7 })._resumeKey, "2-c7")
})

test("문제 집합이 매번 달라지는 모드는 대상이 아니다", opts, () => {
  assert.equal(makeCtrl({ subjectId: "mini" })._resumeKey, null, "미니 퀴즈는 매 요청 랜덤 표본")
  const wrong = makeCtrl(); Object.defineProperty(wrong, "wrongModeValue", { value: true })
  assert.equal(wrong._resumeKey, null, "오답 노트")
  const bm = makeCtrl(); Object.defineProperty(bm, "bookmarkModeValue", { value: true })
  assert.equal(bm._resumeKey, null, "북마크")
})

// ── 저장 ────────────────────────────────────────────────────
test("첫 문제에서는 저장하지 않는다 — 되살릴 진행이 없다", opts, () => {
  makeCtrl()._saveResumePoint()
  assert.deepEqual(stored(), {})
})

test("진행 중이면 위치·문제ID·점수·통계를 함께 저장한다", opts, () => {
  const c = makeCtrl()
  c.currentValue = 42; c.scoreValue = 30; c.wrongByChapter = { "1-3": 2 }
  c._saveResumePoint()
  const s = stored()["1"]
  assert.equal(s.current, 42)
  assert.equal(s.qid, 1042, "문제 순서가 바뀌어도 찾을 수 있게 ID 를 남긴다")
  assert.equal(s.total, 120)
  assert.equal(s.score, 30)
  assert.deepEqual(s.wrongByChapter, { "1-3": 2 }, "결과 화면의 취약 챕터 요약이 반쪽이 되면 안 된다")
})

test("비로그인이면 로컬에만 저장하고 서버로 보내지 않는다", opts, () => {
  const c = makeCtrl({ signedIn: false })
  c.currentValue = 10; c._saveResumePoint()
  assert.equal(c.synced.length, 0)
  assert.equal(stored()["1"].current, 10)
})

test("로그인 상태에서는 5문제마다 서버에 올린다", opts, () => {
  const c = makeCtrl({ signedIn: true })
  c.currentValue = 7; c._saveResumePoint()
  assert.equal(c.synced.length, 0, "매 문제마다 POST 하지는 않는다")
  c.currentValue = 10; c._saveResumePoint()
  assert.equal(c.synced.length, 1)
})

test("페이지를 떠날 때는 주기와 무관하게 keepalive 로 올린다", opts, () => {
  const c = makeCtrl({ signedIn: true })
  c.currentValue = 7; c._saveResumePoint({ keepalive: true })
  assert.equal(c.synced.length, 1, "로그아웃 직전 마지막 위치를 흘리면 안 된다")
  assert.equal(c.synced[0][3].keepalive, true)
})

// ── 복원 ────────────────────────────────────────────────────
test("확인하면 저장된 위치와 점수로 복원한다", opts, () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor())
  globalThis.confirm = () => true
  const c = makeCtrl(); c._maybeResume()
  assert.equal(c.currentValue, 42)
  assert.equal(c.scoreValue, 30)
  assert.equal(c.scoreDisplayTarget.textContent, 30, "화면 점수도 함께 되돌아와야 한다")
})

test("취소하면 처음부터 시작하고 저장분을 지운다", opts, () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor())
  globalThis.confirm = () => false
  const c = makeCtrl(); c._maybeResume()
  assert.equal(c.currentValue, 0)
  assert.deepEqual(stored(), {}, "다음 방문에 또 묻지 않는다")
})

test("문항 수가 바뀌었으면 묻지도 않고 폐기한다", opts, () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor({ total: 119 }))
  let asked = false
  globalThis.confirm = () => { asked = true; return true }
  const c = makeCtrl(); c._maybeResume()
  assert.equal(asked, false, "저장된 번호를 더는 신뢰할 수 없다")
  assert.equal(c.currentValue, 0)
  assert.deepEqual(stored(), {})
})

test("문제 순서가 밀렸으면 저장된 문제를 찾아 그 자리에서 이어준다", opts, () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor({ qid: 1050 }))
  globalThis.confirm = () => true
  const c = makeCtrl(); c._maybeResume()
  assert.equal(c.currentValue, 50)
})

test("저장된 문제가 사라졌거나 범위를 벗어나면 폐기한다", opts, () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor({ qid: 999999 }))
  globalThis.confirm = () => true
  const gone = makeCtrl(); gone._maybeResume()
  assert.equal(gone.currentValue, 0)

  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor({ current: 120 }))
  const oob = makeCtrl(); oob._maybeResume()
  assert.equal(oob.currentValue, 0)
})

test("저장된 적 없으면 아무것도 묻지 않는다", opts, () => {
  let asked = false
  globalThis.confirm = () => { asked = true; return true }
  const c = makeCtrl(); c._maybeResume()
  assert.equal(asked, false)
  assert.equal(c.currentValue, 0)
})

test("다른 퀴즈의 저장분을 끌어오지 않는다", opts, () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", savedFor())
  let asked = false
  globalThis.confirm = () => { asked = true; return true }
  const c = makeCtrl({ subjectId: "2" }); c._maybeResume()
  assert.equal(asked, false)
  assert.equal(c.currentValue, 0)
})

// ── 진행 ────────────────────────────────────────────────────
test("다음 문제로 넘어갈 때마다 위치가 저장된다", opts, () => {
  const c = makeCtrl()
  Object.defineProperty(c, "showQuestion", { value: () => {} })
  Object.defineProperty(c, "showResults", { value: () => {} })
  c.nextQuestion()
  assert.equal(stored()["1"].current, 1)
})
