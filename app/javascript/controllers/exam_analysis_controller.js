// exam.silmu.kr — 학습 분석 대시보드 Stimulus 컨트롤러
import { Controller } from "@hotwired/stimulus"
import { getAllProgress, getWrongAnswerCount } from "../exam_progress"

const SUBJECTS = [
  { id: "1", title: "공공조달의 이해",    short: "1권", chapters: 7, color: "emerald" },
  { id: "2", title: "공공조달 계획분석",  short: "2권", chapters: 6, color: "blue" },
  { id: "3", title: "공공계약관리",       short: "3권", chapters: 6, color: "violet" },
  { id: "4", title: "공공조달 관리실무",  short: "4권", chapters: 8, color: "rose" }
]

const TOTAL_CHAPTERS = 27

const COLORS = {
  emerald: { bar: "bg-emerald-500", text: "text-emerald-600", light: "bg-emerald-50", border: "border-emerald-200", badge: "bg-emerald-100 text-emerald-700" },
  blue:    { bar: "bg-blue-500",    text: "text-blue-600",    light: "bg-blue-50",    border: "border-blue-200",    badge: "bg-blue-100 text-blue-700" },
  violet:  { bar: "bg-violet-500",  text: "text-violet-600",  light: "bg-violet-50",  border: "border-violet-200",  badge: "bg-violet-100 text-violet-700" },
  rose:    { bar: "bg-rose-500",    text: "text-rose-600",    light: "bg-rose-50",    border: "border-rose-200",    badge: "bg-rose-100 text-rose-700" }
}

export default class extends Controller {
  static targets = [
    "emptyState", "dashContent",
    "summaryCards", "chapterProgress", "quizHistory",
    "wrongAnalysis", "recommendations"
  ]

  connect() {
    const progress = getAllProgress()
    const wrongCount = getWrongAnswerCount()
    const visitedChapters = Object.keys(progress.chapters || {})
    const quizzes = progress.quizzes || {}

    const hasData = visitedChapters.length > 0 || Object.keys(quizzes).length > 0 || wrongCount > 0
    if (!hasData) return

    // 빈 상태 숨기고 대시보드 표시
    this.emptyStateTarget.classList.add("hidden")
    this.dashContentTarget.classList.remove("hidden")

    this.renderSummaryCards(visitedChapters.length, quizzes, wrongCount)
    this.renderChapterProgress(visitedChapters, quizzes)
    this.renderQuizHistory(quizzes)
    this.renderWrongAnalysis(quizzes, wrongCount)
    this.renderRecommendations(visitedChapters, quizzes, wrongCount)
  }

  // ── 종합 요약 카드 4개 ─────────────────────────────
  renderSummaryCards(visitedCount, quizzes, wrongCount) {
    const chapterPct = Math.round((visitedCount / TOTAL_CHAPTERS) * 100)
    const quizCount = Object.keys(quizzes).length
    const bestPct = quizCount > 0
      ? Math.max(...Object.values(quizzes).map(q => q.pct))
      : null

    const cards = [
      {
        icon: "school",
        color: "teal",
        label: "챕터 학습",
        value: `${visitedCount}<span class="text-slate-400 text-base font-normal">/${TOTAL_CHAPTERS}</span>`,
        sub: `전체 진도 ${chapterPct}%`
      },
      {
        icon: "emoji_events",
        color: "blue",
        label: "모의고사 최고점",
        value: bestPct !== null ? `${bestPct}<span class="text-slate-400 text-2xl font-normal">%</span>` : `<span class="text-slate-300 text-2xl">-</span>`,
        sub: bestPct !== null ? (bestPct >= 60 ? "합격권 도달!" : "60점 합격 목표") : "아직 응시 전"
      },
      {
        icon: "quiz",
        color: "violet",
        label: "응시 횟수",
        value: `${quizCount}<span class="text-slate-400 text-base font-normal">회</span>`,
        sub: quizCount > 0 ? "과목별 + 전체" : "첫 모의고사 도전!"
      },
      {
        icon: "error_outline",
        color: "rose",
        label: "오답 누적",
        value: `${wrongCount}<span class="text-slate-400 text-base font-normal">개</span>`,
        sub: wrongCount > 0 ? "오답 노트 복습 권장" : "오답 없음 (훌륭해요!)"
      }
    ]

    const colorMap = {
      teal:   "text-teal-600 bg-teal-50",
      blue:   "text-blue-600 bg-blue-50",
      violet: "text-violet-600 bg-violet-50",
      rose:   "text-rose-600 bg-rose-50"
    }

    this.summaryCardsTarget.innerHTML = cards.map(c => `
      <div class="bg-white rounded-2xl border border-slate-200 p-5">
        <div class="flex items-center gap-2 mb-3">
          <div class="w-8 h-8 ${colorMap[c.color]} rounded-lg flex items-center justify-center">
            <span class="material-symbols-outlined text-base">${c.icon}</span>
          </div>
          <span class="text-slate-500 text-xs font-medium">${c.label}</span>
        </div>
        <div class="text-3xl font-extrabold text-slate-800 mb-1">${c.value}</div>
        <div class="text-slate-400 text-xs">${c.sub}</div>
      </div>
    `).join("")
  }

  // ── 과목별 챕터 진도 + 모의고사 점수 ───────────────
  renderChapterProgress(visitedChapters, quizzes) {
    this.chapterProgressTarget.innerHTML = SUBJECTS.map(s => {
      const done = visitedChapters.filter(k => k.startsWith(`${s.id}-`)).length
      const pct = Math.round((done / s.chapters) * 100)
      const c = COLORS[s.color]
      const quiz = quizzes[s.id]

      return `
        <div>
          <div class="flex items-center justify-between mb-1.5">
            <div class="flex items-center gap-2">
              <span class="text-xs font-bold ${c.text}">${s.short}</span>
              <span class="text-sm font-semibold text-slate-700">${s.title}</span>
            </div>
            <div class="flex items-center gap-2">
              ${quiz ? `<span class="text-xs ${c.badge} px-2 py-0.5 rounded-full font-semibold">모의고사 ${quiz.pct}%</span>` : ""}
              <span class="text-xs text-slate-500">${done}/${s.chapters}</span>
            </div>
          </div>
          <div class="w-full bg-slate-100 rounded-full h-2">
            <div class="${c.bar} h-2 rounded-full transition-all duration-500" style="width: ${pct}%"></div>
          </div>
        </div>
      `
    }).join("")
  }

  // ── 모의고사 기록 ─────────────────────────────────
  renderQuizHistory(quizzes) {
    const QUIZ_LABELS = {
      "1": { title: "1권 모의고사", short: "1권", color: "emerald" },
      "2": { title: "2권 모의고사", short: "2권", color: "blue" },
      "3": { title: "3권 모의고사", short: "3권", color: "violet" },
      "4": { title: "4권 모의고사", short: "4권", color: "rose" },
      "all": { title: "전체 모의고사", short: "전체", color: "blue" },
      "simulation": { title: "실전 시험 모드", short: "실전", color: "violet" }
    }

    const records = Object.entries(quizzes)
      .filter(([id]) => QUIZ_LABELS[id])
      .sort(([, a], [, b]) => b.pct - a.pct)

    if (records.length === 0) {
      this.quizHistoryTarget.innerHTML = `
        <p class="text-slate-400 text-sm text-center py-8">아직 모의고사 기록이 없습니다.</p>
      `
      return
    }

    this.quizHistoryTarget.innerHTML = records.map(([id, q]) => {
      const label = QUIZ_LABELS[id]
      const c = COLORS[label.color] || COLORS.blue
      const grade = q.pct >= 90 ? "최우수" : q.pct >= 80 ? "우수" : q.pct >= 60 ? "합격권" : "미달"
      const gradeColor = q.pct >= 60 ? "text-green-600 bg-green-50" : "text-red-600 bg-red-50"
      return `
        <div class="flex items-center gap-3 ${c.light} border ${c.border} rounded-xl px-4 py-3">
          <div class="flex-shrink-0">
            <span class="text-xs font-bold ${c.text} block">${label.short}</span>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-semibold text-slate-700">${label.title}</div>
            <div class="text-xs text-slate-400">${q.date} · ${q.score}/${q.total}문제</div>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs ${gradeColor} px-2 py-0.5 rounded-full font-semibold">${grade}</span>
            <span class="text-xl font-extrabold ${c.text}">${q.pct}%</span>
          </div>
        </div>
      `
    }).join("")
  }

  // ── 오답 현황 및 취약 분야 ─────────────────────────
  renderWrongAnalysis(quizzes, wrongCount) {
    // 과목별 오답률 (모의고사 기록 기준)
    const subjectScores = SUBJECTS.map(s => {
      const q = quizzes[s.id]
      return { ...s, quiz: q, wrongRate: q ? 100 - q.pct : null }
    })

    const withScores = subjectScores.filter(s => s.quiz)
    const withoutScores = subjectScores.filter(s => !s.quiz)

    if (wrongCount === 0 && withScores.length === 0) {
      this.wrongAnalysisTarget.innerHTML = `
        <p class="text-slate-400 text-sm text-center py-6">아직 오답 데이터가 없습니다. 모의고사를 풀면 분석됩니다.</p>
      `
      return
    }

    let html = ""

    // 오답 노트 요약
    if (wrongCount > 0) {
      html += `
        <div class="flex items-center justify-between bg-orange-50 border border-orange-200 rounded-xl px-4 py-3 mb-4">
          <div class="flex items-center gap-3">
            <span class="material-symbols-outlined text-orange-500">error_outline</span>
            <div>
              <div class="font-semibold text-slate-800 text-sm">누적 오답 ${wrongCount}개</div>
              <div class="text-slate-500 text-xs">오답 노트에 저장된 문제를 복습하세요</div>
            </div>
          </div>
          <a href="/quiz/wrong"
             class="inline-flex items-center gap-1 bg-orange-500 hover:bg-orange-600 text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors">
            복습하기
            <span class="material-symbols-outlined text-sm">arrow_forward</span>
          </a>
        </div>
      `
    }

    // 과목별 정답률 막대
    if (withScores.length > 0) {
      html += `<div class="space-y-3">`
      const sorted = [...withScores].sort((a, b) => a.quiz.pct - b.quiz.pct)
      sorted.forEach(s => {
        const c = COLORS[s.color]
        const pct = s.quiz.pct
        const barColor = pct >= 80 ? "bg-green-500" : pct >= 60 ? "bg-amber-500" : "bg-red-500"
        const label = pct >= 80 ? "강점" : pct >= 60 ? "보통" : "취약"
        const labelColor = pct >= 80 ? "bg-green-100 text-green-700" : pct >= 60 ? "bg-amber-100 text-amber-700" : "bg-red-100 text-red-700"
        html += `
          <div>
            <div class="flex items-center justify-between mb-1">
              <div class="flex items-center gap-2">
                <span class="text-xs font-bold ${c.text}">${s.short}</span>
                <span class="text-sm text-slate-700">${s.title}</span>
                <span class="text-xs ${labelColor} px-2 py-0.5 rounded-full font-semibold">${label}</span>
              </div>
              <span class="text-sm font-bold text-slate-700">${pct}%</span>
            </div>
            <div class="w-full bg-slate-100 rounded-full h-2.5">
              <div class="${barColor} h-2.5 rounded-full transition-all duration-500" style="width: ${pct}%"></div>
            </div>
          </div>
        `
      })
      html += `</div>`
    }

    // 미응시 과목
    if (withoutScores.length > 0) {
      html += `
        <div class="mt-4 pt-4 border-t border-slate-100">
          <div class="text-xs text-slate-400 mb-2">미응시 과목</div>
          <div class="flex flex-wrap gap-2">
            ${withoutScores.map(s => {
              const c = COLORS[s.color]
              return `<span class="${c.badge} text-xs font-semibold px-3 py-1 rounded-full">${s.short} ${s.title}</span>`
            }).join("")}
          </div>
        </div>
      `
    }

    this.wrongAnalysisTarget.innerHTML = html
  }

  // ── 학습 추천 ─────────────────────────────────────
  renderRecommendations(visitedChapters, quizzes, wrongCount) {
    const recs = []
    const visitedCount = visitedChapters.length

    // 오답 복습 추천
    if (wrongCount >= 5) {
      recs.push({
        icon: "error_outline",
        color: "rose",
        title: "오답 노트 집중 복습",
        desc: `${wrongCount}개의 오답이 쌓였습니다. 오답 노트에서 취약 문제를 반복 학습하세요.`,
        link: "/quiz/wrong",
        linkText: "오답 노트 열기"
      })
    }

    // 미응시 과목 추천
    const unattempted = SUBJECTS.filter(s => !quizzes[s.id])
    if (unattempted.length > 0) {
      const s = unattempted[0]
      recs.push({
        icon: "quiz",
        color: "blue",
        title: `${s.short} 모의고사 응시`,
        desc: `${s.title} 과목은 아직 모의고사를 풀지 않았습니다. 실력을 점검해 보세요.`,
        link: `/quiz/${s.id}`,
        linkText: "모의고사 시작"
      })
    }

    // 취약 과목 추천
    const weakSubject = SUBJECTS
      .filter(s => quizzes[s.id] && quizzes[s.id].pct < 70)
      .sort((a, b) => quizzes[a.id].pct - quizzes[b.id].pct)[0]

    if (weakSubject) {
      const pct = quizzes[weakSubject.id].pct
      recs.push({
        icon: "school",
        color: "amber",
        title: `${weakSubject.short} 커리큘럼 복습`,
        desc: `${weakSubject.title} 모의고사 점수가 ${pct}%입니다. 해당 챕터를 다시 학습해 보세요.`,
        link: `/subjects/${weakSubject.id}`,
        linkText: "커리큘럼 보기"
      })
    }

    // 챕터 학습 미완료 추천
    if (visitedCount < TOTAL_CHAPTERS) {
      const remaining = TOTAL_CHAPTERS - visitedCount
      recs.push({
        icon: "menu_book",
        color: "teal",
        title: "챕터 학습 계속하기",
        desc: `아직 ${remaining}개 챕터가 남았습니다. 꾸준한 학습이 합격의 지름길입니다.`,
        link: "/subjects/1",
        linkText: "학습 계속하기"
      })
    }

    // 실전 시험 모드 추천 (전체 퀴즈 기록이 있을 때)
    if (quizzes["all"] || Object.keys(quizzes).length >= 2) {
      if (!quizzes["simulation"]) {
        recs.push({
          icon: "timer",
          color: "purple",
          title: "실전 시험 모드 도전",
          desc: "실제 시험과 동일한 100분 타이머 환경에서 최종 실력을 점검해 보세요.",
          link: "/quiz/simulation",
          linkText: "실전 시험 시작"
        })
      }
    }

    const colorMap = {
      rose:   "text-rose-600 bg-rose-50",
      blue:   "text-blue-600 bg-blue-50",
      amber:  "text-amber-600 bg-amber-50",
      teal:   "text-teal-600 bg-teal-50",
      purple: "text-purple-600 bg-purple-50"
    }
    const linkColorMap = {
      rose:   "bg-rose-500 hover:bg-rose-600",
      blue:   "bg-blue-500 hover:bg-blue-600",
      amber:  "bg-amber-500 hover:bg-amber-600",
      teal:   "bg-teal-500 hover:bg-teal-600",
      purple: "bg-purple-500 hover:bg-purple-600"
    }

    if (recs.length === 0) {
      this.recommendationsTarget.innerHTML = `
        <div class="flex items-center gap-3 bg-green-50 border border-green-200 rounded-xl px-4 py-4">
          <span class="material-symbols-outlined text-green-500 text-2xl">check_circle</span>
          <div>
            <div class="font-semibold text-slate-800">아주 잘하고 있어요!</div>
            <div class="text-slate-500 text-sm">모든 학습을 성실히 진행 중입니다. 실전 시험 모드로 최종 점검을 해보세요.</div>
          </div>
        </div>
      `
      return
    }

    this.recommendationsTarget.innerHTML = recs.slice(0, 3).map(r => `
      <div class="flex items-start gap-4 bg-slate-50 border border-slate-200 rounded-xl px-4 py-4">
        <div class="w-9 h-9 ${colorMap[r.color]} rounded-xl flex items-center justify-center flex-shrink-0 mt-0.5">
          <span class="material-symbols-outlined text-base">${r.icon}</span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="font-semibold text-slate-800 text-sm mb-0.5">${r.title}</div>
          <div class="text-slate-500 text-xs leading-relaxed">${r.desc}</div>
        </div>
        <a href="${r.link}"
           class="flex-shrink-0 inline-flex items-center gap-1 ${linkColorMap[r.color]} text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors mt-0.5">
          ${r.linkText}
          <span class="material-symbols-outlined text-sm">arrow_forward</span>
        </a>
      </div>
    `).join("")
  }
}
