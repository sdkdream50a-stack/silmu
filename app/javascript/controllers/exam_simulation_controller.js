// exam.silmu.kr — 실전 시험 모드 Stimulus 컨트롤러
// 120분 타이머 + 3과목 80문제 + 마지막에 일괄 채점
import { Controller } from "@hotwired/stimulus"
import { saveQuizScore, saveWrongAnswer, removeWrongAnswer } from "../exam_progress"
import { escapeHtml } from "../exam_utils"

const EXAM_DURATION = 120 * 60  // 120분 (초 단위)

export default class extends Controller {
  static targets = [
    "startArea", "examArea", "resultArea",
    "timer", "timerBar", "currentNum", "totalNum", "progressBar",
    "questionBadge", "questionText", "optionsArea",
    "prevBtn", "nextBtn", "submitBtn",
    "navGrid", "navGridMobile"
  ]
  static values = {
    questions: Array,
    current: { type: Number, default: 0 }
  }

  connect() {
    // Fisher-Yates 셔플 — 균등한 랜덤 순서 보장
    this.questions = [...this.questionsValue]
    for (let i = this.questions.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [this.questions[i], this.questions[j]] = [this.questions[j], this.questions[i]]
    }
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
    this.timerTarget.textContent = `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`

    // 타이머 바 업데이트
    this.timerBarTarget.style.width = `${(this.remainingSeconds / EXAM_DURATION) * 100}%`

    // 10분 이하: 빨간색 전환 (한 번만 실행)
    if (this.remainingSeconds <= 600 && !this._timerRed) {
      this._timerRed = true
      this.timerTarget.classList.add("text-red-500", "font-extrabold")
      this.timerTarget.classList.remove("text-white")
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
        ? "border-[#004ac6] bg-[#dbe1ff]/40 text-[#004ac6] font-semibold"
        : "bg-[#eff4ff] hover:bg-[#dde9ff]"
      const borderCls = isSelected ? "border-2" : ""
      return `
        <button
          class="sim-option w-full text-left px-5 py-3.5 rounded-xl ${borderCls} ${selectedCls} transition-all text-slate-700 text-sm font-medium"
          data-index="${i}"
          data-action="click->exam-simulation#selectAnswer">
          <span class="font-bold text-slate-400 mr-2 text-base">${labels[i]}</span>${this.escapeHtml(opt)}
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
      btn.classList.remove(
        "border-2", "border-[#004ac6]", "bg-[#dbe1ff]/40", "text-[#004ac6]", "font-semibold",
        "bg-[#eff4ff]", "hover:bg-[#dde9ff]"
      )
      if (i === selected) {
        btn.classList.add("border-2", "border-[#004ac6]", "bg-[#dbe1ff]/40", "text-[#004ac6]", "font-semibold")
      } else {
        btn.classList.add("bg-[#eff4ff]", "hover:bg-[#dde9ff]")
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
    const html = this.questions.map((_, i) => `
      <button
        class="nav-num w-8 h-8 rounded-lg text-xs font-bold border border-[#c3c6d7] bg-white text-slate-500 hover:border-[#004ac6] hover:text-[#004ac6] transition-colors"
        data-index="${i}"
        data-action="click->exam-simulation#jumpTo">
        ${i + 1}
      </button>
    `).join("")
    if (this.hasNavGridTarget) this.navGridTarget.innerHTML = html
    if (this.hasNavGridMobileTarget) this.navGridMobileTarget.innerHTML = html
  }

  // 네비게이션 그리드 — 변경된 셀만 업데이트 (80문제 x 2벌 = 160 DOM 조작 -> 최대 4~6개)
  updateNavGrid() {
    const prev = this._prevNavIdx ?? -1
    const curr = this.currentValue
    // 업데이트가 필요한 인덱스만 수집 (이전 위치, 현재 위치, 방금 답한 문제)
    const toUpdate = new Set([prev, curr])

    const update = (container) => {
      if (!container) return
      const buttons = container.querySelectorAll(".nav-num")
      toUpdate.forEach(i => {
        if (i < 0 || i >= buttons.length) return
        const btn = buttons[i]
        btn.classList.remove(
          "border-[#004ac6]", "bg-[#004ac6]", "text-white",
          "border-[#62df7d]", "bg-[#62df7d]/20", "text-[#005320]",
          "border-[#c3c6d7]", "bg-white", "text-slate-500"
        )
        if (i === curr) {
          btn.classList.add("border-[#004ac6]", "bg-[#004ac6]", "text-white")
        } else if (this.answers[i] !== null) {
          btn.classList.add("border-[#62df7d]", "bg-[#62df7d]/20", "text-[#005320]")
        } else {
          btn.classList.add("border-[#c3c6d7]", "bg-white", "text-slate-500")
        }
      })
    }
    if (this.hasNavGridTarget) update(this.navGridTarget)
    if (this.hasNavGridMobileTarget) update(this.navGridMobileTarget)
    this._prevNavIdx = curr
  }

  jumpTo(event) {
    const idx = parseInt(event.currentTarget.dataset.index)
    this.showQuestion(idx)
  }

  // ── 시험 제출 ──
  submitExam(timeUp = false) {
    if (!timeUp) {
      const unanswered = this.answers.filter(a => a === null).length
      if (unanswered > 0) {
        // 네이티브 confirm 대신 인라인 확인 UI 표시
        this._showSubmitConfirm(unanswered)
        return
      }
    }
    this._doSubmit(timeUp)
  }

  _showSubmitConfirm(unansweredCount) {
    // 기존 확인창 제거
    document.getElementById('sim-submit-confirm')?.remove()

    const modal = document.createElement('div')
    modal.id = 'sim-submit-confirm'
    modal.className = 'fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 px-4'
    modal.innerHTML = `
      <div class="bg-white rounded-2xl shadow-2xl max-w-sm w-full p-6 text-center">
        <div class="w-14 h-14 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <span class="material-symbols-outlined text-amber-500 text-3xl">warning</span>
        </div>
        <h3 class="text-lg font-bold text-slate-800 mb-2">미응답 문제가 있습니다</h3>
        <p class="text-slate-500 text-sm mb-6">
          아직 <strong class="text-amber-600">${unansweredCount}문제</strong>에 답하지 않았습니다.<br>
          미응답 문제는 <strong>0점</strong> 처리됩니다.
        </p>
        <div class="flex gap-3">
          <button id="sim-confirm-cancel"
                  class="flex-1 px-4 py-3 border-2 border-slate-200 text-slate-600 font-semibold rounded-xl hover:bg-slate-50 transition-colors text-sm">
            계속 풀기
          </button>
          <button id="sim-confirm-submit"
                  class="flex-1 px-4 py-3 bg-gradient-to-br from-[#004ac6] to-[#2563eb] text-white font-bold rounded-xl transition-all text-sm shadow-sm">
            그래도 제출
          </button>
        </div>
      </div>
    `
    document.body.appendChild(modal)

    document.getElementById('sim-confirm-cancel').addEventListener('click', () => modal.remove())
    document.getElementById('sim-confirm-submit').addEventListener('click', () => {
      modal.remove()
      this._doSubmit(false)
    })
    modal.addEventListener('click', (e) => { if (e.target === modal) modal.remove() })
  }

  _doSubmit(timeUp = false) {
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
    // Tailwind 동적 보간 방지 — 전체 클래스 문자열 사용
    const subjectTextColors = { 1: "text-emerald-600", 2: "text-blue-600", 3: "text-violet-600" }
    const subjectBgColors = { 1: "bg-emerald-500", 2: "bg-blue-500", 3: "bg-violet-500" }

    const subjectRows = [1, 2, 3].filter(esid => examSubjectStats[esid]).map(esid => {
      const stat = examSubjectStats[esid]
      const spct = Math.round((stat.correct / stat.total) * 100)
      return `
        <div class="flex items-center gap-3">
          <div class="text-xs ${subjectTextColors[esid]} font-bold w-16 flex-shrink-0">${esid}과목</div>
          <div class="flex-1 bg-slate-100 rounded-full h-2">
            <div class="${subjectBgColors[esid]} h-2 rounded-full" style="width:${spct}%"></div>
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
                <p class="text-slate-700 text-sm font-medium leading-snug">${this.escapeHtml(r.q.question)}</p>
              </div>
              <div class="text-xs text-slate-500 mb-1">
                내 답: <span class="text-red-600 font-semibold">${r.selected !== null ? labels[r.selected] + " " + this.escapeHtml(r.q.options[r.selected]) : "미응답"}</span>
                &nbsp;→&nbsp; 정답: <span class="text-green-600 font-semibold">${labels[r.q.correct]} ${this.escapeHtml(r.q.options[r.q.correct])}</span>
              </div>
              <p class="text-xs text-slate-500 leading-relaxed">${this.escapeHtml(r.q.explanation)}</p>
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
                class="flex-1 inline-flex items-center justify-center gap-2 bg-gradient-to-br from-[#004ac6] to-[#2563eb] hover:opacity-90 text-white font-bold px-6 py-3.5 rounded-xl transition-all shadow-sm">
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

  escapeHtml(str) { return escapeHtml(str) }
}
