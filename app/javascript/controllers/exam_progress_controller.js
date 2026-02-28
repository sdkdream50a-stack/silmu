// exam.silmu.kr — 학습 진도 추적 Stimulus 컨트롤러
// 챕터 방문 기록, 과목 진도바, 모의고사 점수 표시
import { Controller } from "@hotwired/stimulus"
import { markChapterVisited, getVisitedChapters, getAllProgress, getStats } from "../exam_progress"

// 과목별 고정 색상 (Tailwind safelist에 포함된 클래스만 사용)
const SUBJECT_STYLE = {
  "1": { bar: "bg-emerald-500", text: "text-emerald-600", badge: "bg-emerald-100 text-emerald-800", card: "bg-emerald-50 border-emerald-200" },
  "2": { bar: "bg-blue-500",    text: "text-blue-600",    badge: "bg-blue-100 text-blue-800",    card: "bg-blue-50 border-blue-200" },
  "3": { bar: "bg-violet-500",  text: "text-violet-600",  badge: "bg-violet-100 text-violet-800",  card: "bg-violet-50 border-violet-200" },
  "4": { bar: "bg-rose-500",    text: "text-rose-600",    badge: "bg-rose-100 text-rose-800",    card: "bg-rose-50 border-rose-200" },
  "all": { bar: "bg-blue-500",  text: "text-blue-600",    badge: "bg-blue-100 text-blue-800",    card: "bg-blue-50 border-blue-200" }
}

export default class extends Controller {
  static values = {
    subjectId: Number,
    chapterNum: Number,
    total: Number
  }
  static targets = ["badge", "progressBar", "progressText", "scoreArea", "statsArea"]

  connect() {
    // 챕터 페이지: subjectId + chapterNum 값이 있으면 방문 기록
    if (this.hasSubjectIdValue && this.hasChapterNumValue) {
      this.trackChapter()
    }
    // 과목 상세 페이지: 챕터 체크마크 + 진행률 바
    if (this.hasProgressBarTarget) {
      this.displaySubjectProgress()
    }
    // 커리큘럼 목록 페이지: 과목별 진도 %
    const subjectCards = this.element.querySelectorAll("[data-subject-total]")
    if (subjectCards.length > 0) {
      this.displaySubjectsList(subjectCards)
    }
    // 모의고사 선택 페이지: 점수 기록
    if (this.hasScoreAreaTarget) {
      this.displayQuizScores()
    }
    // 홈 페이지: 전체 통계
    if (this.hasStatsAreaTarget) {
      this.displayHomeStats()
    }
  }

  // ── 챕터 방문 기록 ──────────────────────────────
  trackChapter() {
    markChapterVisited(this.subjectIdValue, this.chapterNumValue)
    if (this.hasBadgeTarget) {
      this.badgeTarget.innerHTML = `
        <div class="inline-flex items-center gap-1.5 bg-green-50 border border-green-200 text-green-700 text-sm font-semibold px-3 py-1.5 rounded-full">
          <span class="material-symbols-outlined text-base">check_circle</span>
          학습 완료
        </div>
      `
    }
  }

  // ── 과목 상세: 챕터 체크마크 + 진행률 바 ──────────
  displaySubjectProgress() {
    const visited = getVisitedChapters()
    const total = this.totalValue || 0
    let done = 0

    this.element.querySelectorAll("[data-chapter-key]").forEach(el => {
      if (visited[el.dataset.chapterKey]) {
        done++
        const spot = el.querySelector("[data-chapter-status]")
        if (spot) {
          spot.innerHTML = `<span class="material-symbols-outlined text-green-500 text-xl">check_circle</span>`
        }
      }
    })

    const pct = total > 0 ? Math.round((done / total) * 100) : 0
    this.progressBarTarget.style.width = `${pct}%`
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${done}/${total} 완료`
    }
  }

  // ── 커리큘럼 목록: 과목별 진도 % ─────────────────
  displaySubjectsList(cards) {
    const visited = getVisitedChapters()
    cards.forEach(el => {
      const subjectId = el.dataset.subjectId
      const total = parseInt(el.dataset.subjectTotal) || 0
      const done = Object.keys(visited).filter(k => k.startsWith(`${subjectId}-`)).length
      const pct = total > 0 ? Math.round((done / total) * 100) : 0

      const bar = el.querySelector("[data-progress-bar]")
      const text = el.querySelector("[data-progress-text]")
      if (bar) bar.style.width = `${pct}%`
      if (text) text.textContent = pct > 0 ? `${done}/${total} 완료` : ""
    })
  }

  // ── 모의고사 점수 기록 ───────────────────────────
  displayQuizScores() {
    const { quizzes } = getAllProgress()
    const subjects = [
      { id: "1", title: "1권", sub: "공공조달의 이해" },
      { id: "2", title: "2권", sub: "공공조달 계획분석" },
      { id: "3", title: "3권", sub: "공공계약관리" },
      { id: "4", title: "4권", sub: "공공조달 관리실무" },
      { id: "all", title: "전체", sub: "전체 모의고사" }
    ]

    const records = subjects.filter(s => quizzes[s.id])
    if (records.length === 0) {
      this.scoreAreaTarget.innerHTML = `
        <p class="text-slate-400 text-sm text-center py-6 flex items-center justify-center gap-2">
          <span class="material-symbols-outlined text-slate-300">quiz</span>
          아직 풀이 기록이 없습니다. 모의고사를 풀어보세요!
        </p>
      `
      return
    }

    this.scoreAreaTarget.innerHTML = records.map(s => {
      const q = quizzes[s.id]
      const style = SUBJECT_STYLE[s.id]
      const grade = q.pct >= 90 ? "최우수" : q.pct >= 80 ? "우수" : q.pct >= 60 ? "합격권" : "재도전"
      return `
        <div class="flex items-center justify-between ${style.card} border rounded-xl px-4 py-3">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-0.5">
              <span class="text-xs font-bold ${style.text}">${s.title} 모의고사</span>
              <span class="text-xs ${style.badge} px-2 py-0.5 rounded-full">${grade}</span>
            </div>
            <div class="text-slate-500 text-xs">${q.date} · ${q.score}/${q.total}문제 정답</div>
          </div>
          <div class="text-2xl font-extrabold ${style.text} ml-3">${q.pct}%</div>
        </div>
      `
    }).join("")
  }

  // ── 홈 전체 통계 ────────────────────────────────
  displayHomeStats() {
    const { visitedCount, totalChapters, bestPct } = getStats()
    if (visitedCount === 0 && bestPct === null) return  // 진도 없으면 숨김 유지

    const pct = Math.round((visitedCount / totalChapters) * 100)
    this.statsAreaTarget.classList.remove("hidden")
    this.statsAreaTarget.innerHTML = `
      <div class="bg-white/10 backdrop-blur-sm rounded-2xl px-6 py-4 border border-white/20">
        <div class="flex items-center gap-2 mb-3">
          <span class="material-symbols-outlined text-yellow-300 text-base">trending_up</span>
          <span class="text-white/90 text-sm font-semibold">나의 학습 현황</span>
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <div class="text-xs text-white/60 mb-1">챕터 학습</div>
            <div class="w-full bg-white/20 rounded-full h-1.5 mb-1">
              <div class="bg-yellow-300 h-1.5 rounded-full transition-all" style="width: ${pct}%"></div>
            </div>
            <div class="text-white text-sm font-bold">${visitedCount}<span class="text-white/60 font-normal">/${totalChapters} 완료</span></div>
          </div>
          ${bestPct !== null ? `
          <div>
            <div class="text-xs text-white/60 mb-1">모의고사 최고점</div>
            <div class="text-white text-2xl font-extrabold leading-tight">${bestPct}<span class="text-white/60 text-base font-normal">%</span></div>
          </div>` : ""}
        </div>
      </div>
    `
  }
}
