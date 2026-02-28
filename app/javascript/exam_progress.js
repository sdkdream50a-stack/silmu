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
