// exam.silmu.kr 학습 진도 localStorage 유틸리티
const KEY = 'exam_progress'

function load() {
  try {
    return JSON.parse(localStorage.getItem(KEY)) || { chapters: {}, quizzes: {} }
  } catch {
    return { chapters: {}, quizzes: {} }
  }
}

function persist(data) {
  try { localStorage.setItem(KEY, JSON.stringify(data)) } catch { /* 저장 실패 무시 */ }
}

// 챕터 방문 기록
export function markChapterVisited(subjectId, chapterNum) {
  const data = load()
  const key = `${subjectId}-${chapterNum}`
  if (!data.chapters[key]) {
    data.chapters[key] = { visitedAt: new Date().toISOString() }
    persist(data)
  }
}

export function isChapterVisited(subjectId, chapterNum) {
  return !!load().chapters[`${subjectId}-${chapterNum}`]
}

export function getVisitedChapters() {
  return load().chapters
}

// 모의고사 점수 저장 (최고점 기록)
export function saveQuizScore(subjectId, score, total) {
  const data = load()
  const id = String(subjectId)
  const pct = Math.round((score / total) * 100)
  const existing = data.quizzes[id]
  if (!existing || pct >= existing.pct) {
    data.quizzes[id] = {
      score, total, pct,
      date: new Date().toLocaleDateString('ko-KR', { month: 'long', day: 'numeric' })
    }
    persist(data)
  }
}

export function getQuizScore(subjectId) {
  return load().quizzes[String(subjectId)] || null
}

export function getAllProgress() {
  return load()
}

// ─── 오답 노트 ─────────────────────────────────
const WRONG_KEY = 'exam_wrong_answers'

function loadWrong() {
  try { return JSON.parse(localStorage.getItem(WRONG_KEY)) || [] } catch { return [] }
}

export function saveWrongAnswer(questionId) {
  const ids = loadWrong()
  if (!ids.includes(questionId)) {
    ids.push(questionId)
    try { localStorage.setItem(WRONG_KEY, JSON.stringify(ids)) } catch { /* 저장 실패 무시 */ }
  }
}

export function removeWrongAnswer(questionId) {
  const ids = loadWrong().filter(id => id !== questionId)
  try { localStorage.setItem(WRONG_KEY, JSON.stringify(ids)) } catch { /* 저장 실패 무시 */ }
}

export function getWrongAnswerIds() {
  return loadWrong()
}

export function getWrongAnswerCount() {
  return loadWrong().length
}

export function clearAllWrongAnswers() {
  try { localStorage.removeItem(WRONG_KEY) } catch { /* 무시 */ }
}

// ─── 챕터 퀴즈 완주 배지 ─────────────────────────────
export function saveChapterQuizDone(subjectId, chapterNum, pct) {
  const data = load()
  if (!data.chapterQuizzes) data.chapterQuizzes = {}
  const key = `${subjectId}-${chapterNum}`
  const existing = data.chapterQuizzes[key]
  if (!existing || pct >= existing.pct) {
    data.chapterQuizzes[key] = { pct, date: new Date().toLocaleDateString('ko-KR', { month: 'long', day: 'numeric' }) }
    persist(data)
  }
}

export function getChapterQuizDones() {
  return load().chapterQuizzes || {}
}

// ─── 학습 스트릭 (연속 학습일) ─────────────────────────────
const STREAK_KEY = 'exam_streak'

function todayStr() {
  return new Date().toLocaleDateString('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit' })
    .replace(/\. /g, '-').replace('.', '')
}

function yesterday() {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return d.toLocaleDateString('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit' })
    .replace(/\. /g, '-').replace('.', '')
}

function loadStreak() {
  try { return JSON.parse(localStorage.getItem(STREAK_KEY)) || { count: 0, lastDate: null, history: [] } }
  catch { return { count: 0, lastDate: null, history: [] } }
}

// 오늘 학습 기록 (모의고사 완료 시 호출)
export function saveStreakToday() {
  const streak = loadStreak()
  const today = todayStr()
  if (streak.lastDate === today) return // 오늘 이미 기록됨

  const isConsecutive = streak.lastDate === yesterday()
  const newCount = isConsecutive ? streak.count + 1 : 1
  const history = isConsecutive ? [...(streak.history || []).slice(-29), today] : [today]

  const updated = { count: newCount, lastDate: today, history }
  try { localStorage.setItem(STREAK_KEY, JSON.stringify(updated)) } catch { /* 무시 */ }
}

export function getStreak() {
  const streak = loadStreak()
  const today = todayStr()
  // 어제 또는 오늘 마지막 학습일이 아니면 스트릭 소멸
  if (streak.lastDate !== today && streak.lastDate !== yesterday()) {
    return { count: 0, lastDate: null, history: [] }
  }
  return streak
}

export function getStreakCount() {
  return getStreak().count
}

// 전체 통계
export function getStats() {
  const data = load()
  const visitedCount = Object.keys(data.chapters).length
  const totalChapters = 27
  const quizCount = Object.keys(data.quizzes).length
  const bestPct = quizCount > 0
    ? Math.max(...Object.values(data.quizzes).map(q => q.pct))
    : null
  return { visitedCount, totalChapters, quizCount, bestPct }
}
