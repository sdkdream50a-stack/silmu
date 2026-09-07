// 모의고사 «이어풀기» 저장소 회귀 (2026-09-07 문의 대응).
// exam_progress.js 는 외부 import 가 없어 node_modules 없이도 그대로 돌아간다.
// localStorage 만 대역으로 세우고 모듈이 실제로 하는 일을 본다.
import { test, beforeEach } from "node:test"
import assert from "node:assert/strict"

class FakeStorage {
  constructor() { this.map = new Map() }
  getItem(k) { return this.map.has(k) ? this.map.get(k) : null }
  setItem(k, v) { this.map.set(k, String(v)) }
  removeItem(k) { this.map.delete(k) }
}
globalThis.localStorage = new FakeStorage()

const { saveInProgress, getInProgress, clearInProgress, getAllInProgress } =
  await import("../../app/javascript/exam_progress.js")

beforeEach(() => { globalThis.localStorage = new FakeStorage() })

test("저장한 위치를 그대로 되읽는다", () => {
  saveInProgress("1", { current: 42, qid: 777, total: 120, score: 30 })
  const got = getInProgress("1")
  assert.equal(got.current, 42)
  assert.equal(got.qid, 777)
  assert.equal(got.score, 30)
})

test("savedAt 이 자동으로 붙는다 — 서버 병합이 최신 판정에 쓴다", () => {
  const before = Date.now()
  saveInProgress("1", { current: 1 })
  assert.ok(getInProgress("1").savedAt >= before)
})

test("퀴즈마다 위치가 따로 보관된다", () => {
  saveInProgress("1", { current: 10 })
  saveInProgress("2", { current: 20 })
  saveInProgress("3-c5", { current: 3 })
  assert.equal(getInProgress("1").current, 10)
  assert.equal(getInProgress("2").current, 20)
  assert.equal(getInProgress("3-c5").current, 3)
})

test("한 퀴즈를 지워도 다른 퀴즈는 남는다", () => {
  saveInProgress("1", { current: 10 })
  saveInProgress("2", { current: 20 })
  clearInProgress("1")
  assert.equal(getInProgress("1"), null)
  assert.equal(getInProgress("2").current, 20)
})

test("없는 키를 지워도 터지지 않는다", () => {
  clearInProgress("nope")
  assert.deepEqual(getAllInProgress(), {})
})

test("저장된 적 없으면 null 이다 — 이어풀기를 제안하지 않는다", () => {
  assert.equal(getInProgress("1"), null)
})

test("localStorage 가 깨져 있어도 빈 값으로 살아난다", () => {
  globalThis.localStorage.setItem("exam_quiz_in_progress", "{망가진 JSON")
  assert.deepEqual(getAllInProgress(), {})
  assert.equal(getInProgress("1"), null)
})

test("저장이 막힌 환경(사생활 보호 모드)에서도 예외를 던지지 않는다", () => {
  globalThis.localStorage.setItem = () => { throw new Error("QuotaExceeded") }
  assert.doesNotThrow(() => saveInProgress("1", { current: 3 }))
})
