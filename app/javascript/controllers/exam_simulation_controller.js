// exam.silmu.kr — 실전 시험 모드 Stimulus 컨트롤러
// 120분 타이머 + 3과목 80문제 + 마지막에 일괄 채점
import { Controller } from "@hotwired/stimulus"
import { saveQuizScore, saveWrongAnswer, removeWrongAnswer } from "../exam_progress"

const EXAM_DURATION = 120 * 60  // 120분 (초 단위)

export default class extends Controller {
  static targets = [
    "startArea", "examArea", "resultArea",
    "timer", "timerBar", "currentNum", "totalNum", "progressBar",
    "questionBadge", "questionText", "optionsArea",
    "prevBtn", "nextBtn", "submitBtn",
    "navGrid"
  ]
  static values = {
    questions: Array,
    current: { type: Number, default: 0 }
  }

  connect() {
    // 랜덤 순서로 섞기
    this.questions = [...this.questionsValue].sort(() => Math.random() - 0.5)
    this.answers = new Array(this.questions.length).fill(null)  // null = 미답
    this.timerInterval = null
    this.remainingSeconds = EXAM_DURATION
    this.totalNumTarget.textContent = this.questions.length
    this.renderNavGrid()
  }

  disconnect() {
    this.stopTimer()
  }

  // ── 시험 시작 ──
  startExam() {
    this.startAreaTarget.classList.add("hidden")
    this.examAreaTarget.classList.remove("hidden")
    this.startTimer()
    this.showQuestion(0)
  }

  // ── 타이머 ──
  startTimer() {
    this.updateTimerDisplay()
    this.timerInterval = setInterval(() => {
      this.remainingSeconds--
      this.updateTimerDisplay()
      if (this.remainingSeconds <= 0) {
        this.stopTimer()
        this.submitExam(true)  // 시간 초과 자동 제출
      }
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  updateTimerDisplay() {
    const m = Math.floor(this.remainingSeconds / 60)
    const s = this.remainingSeconds % 60
    const text = `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
    this.timerTarget.textContent = text

    // 타이머 색상 (10분 이하: 빨간색)
    if (this.remainingSeconds <= 600) {
      this.timerTarget.classList.add("text-red-500", "font-extrabold")
      this.timerTarget.classList.remove("text-white")
    } else {
      this.timerTarget.classList.remove("text-red-500", "font-extrabold")
      this.timerTarget.classList.add("text-white")
    }

    // 타이머 바
    const pct = (this.remainingSeconds / EXAM_DURATION) * 100
    this.timerBarTarget.style.width = `${pct}%`
    if (this.remainingSeconds <= 600) {
      this.timerBarTarget.classList.add("bg-red-400")
      this.timerBarTarget.classList.remove("bg-yellow-300")
    }
  }

  // ── 문제 표시 ──
  showQuestion(idx) {
    this.currentValue = idx
    const q = this.questions[idx]
    const total = this.questions.length

    // 진행 표시
    this.currentNumTarget.textContent = idx + 1
    this.progressBarTarget.style.width = `${((idx + 1) / total) * 100}%`

    // 문제 배지·텍스트
    this.questionBadgeTarget.textContent = `문제 ${idx + 1}`
    this.questionTextTarget.textContent = q.question

    // 선택지 렌더링
    const labels = ["①", "②", "③", "④"]
    const currentAnswer = this.answers[idx]
    this.optionsAreaTarget.innerHTML = q.options.map((opt, i) => {
      const isSelected = currentAnswer === i
      const selectedCls = isSelected
        ? "border-blue-500 bg-blue-50 text-blue-800"
        : "border-slate-200 hover:border-blue-400 hover:bg-blue-50"
      return `
        <button
          class="sim-option w-full text-left px-5 py-3.5 rounded-xl border-2 ${selectedCls} transition-all text-slate-700 text-sm font-medium"
          data-index="${i}"
          data-action="click->exam-simulation#selectAnswer">
          <span class="font-bold text-slate-400 mr-2 text-base">${labels[i]}</span>${opt}
        </button>
      `
    }).join("")

    // 이전/다음 버튼
    this.prevBtnTarget.disabled = idx === 0
    if (idx === total - 1) {
      this.nextBtnTarget.classList.add("hidden")
      this.submitBtnTarget.classList.remove("hidden")
    } else {
      this.nextBtnTarget.classList.remove("hidden")
      this.submitBtnTarget.classList.add("hidden")
    }

    // 네비게이션 그리드 현재 위치 표시
    this.updateNavGrid()
  }

  // ── 답 선택 ──
  selectAnswer(event) {
    const selected = parseInt(event.currentTarget.dataset.index)
    this.answers[this.currentValue] = selected

    // 선택 UI 업데이트
    this.optionsAreaTarget.querySelectorAll(".sim-option").forEach((btn, i) => {
      btn.classList.remove("border-blue-500", "bg-blue-50", "text-blue-800",
        "border-slate-200", "hover:border-blue-400", "hover:bg-blue-50")
      if (i === selected) {
        btn.classList.add("border-blue-500", "bg-blue-50", "text-blue-800")
      } else {
        btn.classList.add("border-slate-200", "hover:border-blue-400", "hover:bg-blue-50")
      }
    })

    // 네비게이션 그리드 업데이트
    this.updateNavGrid()
  }

  // ── 이전/다음 이동 ──
  prevQuestion() {
    if (this.currentValue > 0) this.showQuestion(this.currentValue - 1)
  }

  nextQuestion() {
    if (this.currentValue < this.questions.length - 1) {
      this.showQuestion(this.currentValue + 1)
    }
  }

  // ── 문제 번호 네비게이션 ──
  renderNavGrid() {
    if (!this.hasNavGridTarget) return
    this.navGridTarget.innerHTML = this.questions.map((_, i) => `
      <button
        class="nav-num w-8 h-8 rounded-lg text-xs font-bold border-2 border-slate-200 text-slate-500 hover:border-blue-400 transition-colors"
        data-index="${i}"
        data-action="click->exam-simulation#jumpTo">
        ${i + 1}
      </button>
    `).join("")
  }

  updateNavGrid() {
    if (!this.hasNavGridTarget) return
    this.navGridTarget.querySelectorAll(".nav-num").forEach((btn, i) => {
      btn.classList.remove("border-blue-500", "bg-blue-500", "text-white",
        "border-green-400", "bg-green-50", "text-green-700",
        "border-slate-200", "text-slate-500")
      if (i === this.currentValue) {
        btn.classList.add("border-blue-500", "bg-blue-500", "text-white")
      } else if (this.answers[i] !== null) {
        btn.classList.add("border-green-400", "bg-green-50", "text-green-700")
      } else {
        btn.classList.add("border-slate-200", "text-slate-500")
      }
    })
  }

  jumpTo(event) {
    const idx = parseInt(event.currentTarget.dataset.index)
    this.showQuestion(idx)
  }

  // ── 시험 제출 ──
  submitExam(timeUp = false) {
    // 미답 확인 (시간 초과 아닌 경우)
    if (!timeUp) {
      const unanswered = this.answers.filter(a => a === null).length
      if (unanswered > 0) {
        const confirmed = confirm(`아직 ${unanswered}문제가 미응답입니다. 제출하시겠습니까?`)
        if (!confirmed) return
      }
    }

    this.stopTimer()
    this.showResults(timeUp)
  }

  // ── 결과 표시 (일괄 채점) ──
  showResults(timeUp = false) {
    let score = 0
    const total = this.questions.length
    const reviewItems = []

    this.questions.forEach((q, i) => {
      const selected = this.answers[i]
      const isCorrect = selected === q.correct

      if (isCorrect) {
        score++
        removeWrongAnswer(q.id)
      } else {
        saveWrongAnswer(q.id)
      }

      reviewItems.push({ q, selected, isCorrect, idx: i })
    })

    const pct = Math.round((score / total) * 100)
    saveQuizScore("sim", score, total)

    // 등급
    let grade, gradeColor, gradeIcon, gradeBg
    if (pct >= 90) {
      grade = "최우수 합격"; gradeColor = "text-yellow-600"; gradeIcon = "workspace_premium"; gradeBg = "from-yellow-400 to-amber-500"
    } else if (pct >= 80) {
      grade = "우수 합격"; gradeColor = "text-green-600"; gradeIcon = "emoji_events"; gradeBg = "from-green-500 to-emerald-500"
    } else if (pct >= 60) {
      grade = "합격권"; gradeColor = "text-blue-600"; gradeIcon = "thumb_up"; gradeBg = "from-blue-500 to-indigo-500"
    } else {
      grade = "불합격 — 재도전"; gradeColor = "text-slate-600"; gradeIcon = "school"; gradeBg = "from-slate-500 to-slate-600"
    }

    const timeUsed = EXAM_DURATION - this.remainingSeconds
    const timeUsedMin = Math.floor(timeUsed / 60)
    const timeUsedSec = timeUsed % 60

    // 과목별 분석 (3과목 기준: subject_id 1→1과목, 2→2과목, 3·4→3과목)
    const examSubjectMap = { 1: 1, 2: 2, 3: 3, 4: 3 }
    const examSubjectStats = {}
    this.questions.forEach((q, i) => {
      const esid = examSubjectMap[q.subject_id] || q.subject_id
      if (!examSubjectStats[esid]) examSubjectStats[esid] = { total: 0, correct: 0 }
      examSubjectStats[esid].total++
      if (this.answers[i] === q.correct) examSubjectStats[esid].correct++
    })

    const subjectNames = { 1: "법제도의 이해", 2: "조달계획 수립 및 분석", 3: "계약 관리" }
    const subjectColors = { 1: "emerald", 2: "blue", 3: "violet" }

    const subjectRows = [1, 2, 3].filter(esid => examSubjectStats[esid]).map(esid => {
      const stat = examSubjectStats[esid]
      const spct = Math.round((stat.correct / stat.total) * 100)
      const c = subjectColors[esid]
      return `
        <div class="flex items-center gap-3">
          <div class="text-xs text-${c}-600 font-bold w-16 flex-shrink-0">${esid}과목</div>
          <div class="flex-1 bg-slate-100 rounded-full h-2">
            <div class="bg-${c}-500 h-2 rounded-full" style="width:${spct}%"></div>
          </div>
          <div class="text-xs font-bold text-slate-700 w-20 text-right">${stat.correct}/${stat.total} (${spct}%)</div>
        </div>
      `
    }).join("")

    // 오답 리뷰 (틀린 문제)
    const wrongItems = reviewItems.filter(r => !r.isCorrect)
    const wrongReview = wrongItems.length > 0
      ? wrongItems.slice(0, 10).map(r => {
          const labels = ["①", "②", "③", "④"]
          return `
            <div class="border border-red-100 rounded-xl p-4 bg-red-50">
              <div class="flex items-start gap-2 mb-2">
                <span class="material-symbols-outlined text-red-400 text-base flex-shrink-0 mt-0.5">cancel</span>
                <p class="text-slate-700 text-sm font-medium leading-snug">${r.q.question}</p>
              </div>
              <div class="text-xs text-slate-500 mb-1">
                내 답: <span class="text-red-600 font-semibold">${r.selected !== null ? labels[r.selected] + " " + r.q.options[r.selected] : "미응답"}</span>
                &nbsp;→&nbsp; 정답: <span class="text-green-600 font-semibold">${labels[r.q.correct]} ${r.q.options[r.q.correct]}</span>
              </div>
              <p class="text-xs text-slate-500 leading-relaxed">${r.q.explanation}</p>
            </div>
          `
        }).join("") + (wrongItems.length > 10 ? `<p class="text-center text-slate-400 text-sm py-2">... 외 ${wrongItems.length - 10}문제 (오답 노트에서 확인)</p>` : "")
      : `<p class="text-center text-green-600 font-semibold py-4">오답 없음 — 완벽합니다!</p>`

    this.examAreaTarget.classList.add("hidden")
    this.resultAreaTarget.innerHTML = `
      <!-- 점수 헤더 -->
      <div class="bg-gradient-to-r ${gradeBg} rounded-2xl p-8 text-white text-center mb-6 shadow-lg">
        <span class="material-symbols-outlined text-5xl mb-3 block">${gradeIcon}</span>
        <div class="text-6xl font-extrabold mb-1">${pct}<span class="text-3xl opacity-70">%</span></div>
        <div class="text-xl font-bold mb-2">${grade}</div>
        <div class="opacity-80 text-sm">${total}문제 중 ${score}문제 정답</div>
        ${timeUp ? '<div class="mt-2 text-sm bg-white/20 rounded-full px-3 py-1 inline-block">⏰ 시간 초과 자동 제출</div>' : `<div class="mt-2 text-sm opacity-70">소요 시간 ${timeUsedMin}분 ${timeUsedSec}초</div>`}
      </div>

      <!-- 과목별 분석 -->
      <div class="bg-white rounded-2xl border border-slate-200 p-6 mb-6">
        <h3 class="font-bold text-slate-800 mb-4 flex items-center gap-2">
          <span class="material-symbols-outlined text-blue-500">analytics</span>
          과목별 성취도
        </h3>
        <div class="space-y-3">
          ${subjectRows}
        </div>
      </div>

      <!-- 오답 리뷰 -->
      <div class="bg-white rounded-2xl border border-slate-200 p-6 mb-6">
        <h3 class="font-bold text-slate-800 mb-4 flex items-center gap-2">
          <span class="material-symbols-outlined text-red-500">fact_check</span>
          오답 리뷰 ${wrongItems.length > 0 ? `<span class="text-sm text-slate-400 font-normal">(${wrongItems.length}문제)</span>` : ""}
        </h3>
        <div class="space-y-4">
          ${wrongReview}
        </div>
      </div>

      <!-- 액션 버튼 -->
      <div class="flex flex-col sm:flex-row gap-3">
        <button onclick="location.reload()"
                class="flex-1 inline-flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">refresh</span>
          다시 시험 보기
        </button>
        <a href="/quiz/wrong"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-orange-50 border-2 border-orange-300 hover:border-orange-400 text-orange-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">error_outline</span>
          오답 노트
        </a>
        <a href="/quiz"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-slate-400 text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">apps</span>
          모의고사 선택
        </a>
      </div>
    `
    this.resultAreaTarget.classList.remove("hidden")
  }
}
