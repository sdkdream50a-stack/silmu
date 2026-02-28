// exam.silmu.kr — 모의고사 문제풀이 Stimulus 컨트롤러
import { Controller } from "@hotwired/stimulus"
import { saveQuizScore, saveWrongAnswer, removeWrongAnswer, getWrongAnswerIds } from "../exam_progress"

export default class extends Controller {
  static targets = [
    "progressArea", "progressBar", "currentNum", "scoreDisplay",
    "questionArea", "questionBadge", "questionText", "optionsArea",
    "feedbackArea", "nextArea", "nextBtn", "resultArea", "emptyArea"
  ]
  static values = {
    questions: Array,
    current: { type: Number, default: 0 },
    score: { type: Number, default: 0 },
    answered: { type: Boolean, default: false },
    wrongMode: { type: Boolean, default: false }
  }

  connect() {
    if (this.wrongModeValue) {
      const wrongIds = getWrongAnswerIds()
      if (wrongIds.length === 0) {
        this.showEmpty()
        return
      }
      // 오답 ID에 해당하는 문제만 필터링
      this.questionsValue = this.questionsValue.filter(q => wrongIds.includes(q.id))
      if (this.questionsValue.length === 0) {
        this.showEmpty()
        return
      }
      // 진행바 total 업데이트
      this.progressAreaTarget.querySelector("strong:last-of-type").textContent = this.questionsValue.length
    }
    this.showQuestion()
  }

  // 오답 없음 상태 표시
  showEmpty() {
    if (this.hasQuestionAreaTarget) this.questionAreaTarget.classList.add("hidden")
    if (this.hasProgressAreaTarget) this.progressAreaTarget.classList.add("hidden")
    if (this.hasEmptyAreaTarget) this.emptyAreaTarget.classList.remove("hidden")
  }

  // 현재 문제 렌더링
  showQuestion() {
    const q = this.questionsValue[this.currentValue]
    if (!q) return

    const total = this.questionsValue.length
    const idx = this.currentValue

    // 진행바 업데이트
    this.progressBarTarget.style.width = `${(idx / total) * 100}%`
    this.currentNumTarget.textContent = idx + 1

    // 문제 배지 & 텍스트
    this.questionBadgeTarget.textContent = `문제 ${idx + 1}`
    this.questionTextTarget.textContent = q.question

    // 선택지 렌더링
    const labels = ["①", "②", "③", "④"]
    this.optionsAreaTarget.innerHTML = q.options.map((opt, i) => `
      <button
        class="option-btn w-full text-left px-5 py-3.5 rounded-xl border-2 border-slate-200 hover:border-blue-400 hover:bg-blue-50 transition-all text-slate-700 text-sm font-medium"
        data-index="${i}"
        data-action="click->exam-quiz#selectAnswer">
        <span class="font-bold text-slate-400 mr-2 text-base">${labels[i]}</span>${opt}
      </button>
    `).join("")

    // 피드백/다음 버튼 숨기기
    this.feedbackAreaTarget.classList.add("hidden")
    this.feedbackAreaTarget.innerHTML = ""
    this.nextAreaTarget.classList.add("hidden")
    this.answeredValue = false
  }

  // 선택지 클릭 처리
  selectAnswer(event) {
    if (this.answeredValue) return
    this.answeredValue = true

    const selected = parseInt(event.currentTarget.dataset.index)
    const q = this.questionsValue[this.currentValue]
    const correct = q.correct
    const isCorrect = selected === correct

    if (isCorrect) {
      this.scoreValue++
      this.scoreDisplayTarget.textContent = this.scoreValue
      removeWrongAnswer(q.id)  // 맞히면 오답 노트에서 제거
    } else {
      saveWrongAnswer(q.id)    // 틀리면 오답 노트에 추가
    }

    // 선택지 색상 업데이트
    this.optionsAreaTarget.querySelectorAll(".option-btn").forEach((btn, i) => {
      btn.disabled = true
      btn.classList.remove("hover:border-blue-400", "hover:bg-blue-50")
      if (i === correct) {
        btn.classList.add("border-green-500", "bg-green-50", "text-green-800")
      } else if (i === selected) {
        btn.classList.add("border-red-400", "bg-red-50", "text-red-700")
      } else {
        btn.classList.add("opacity-50")
      }
    })

    // 피드백 표시
    const icon = isCorrect
      ? `<span class="material-symbols-outlined text-green-600 text-2xl">check_circle</span>`
      : `<span class="material-symbols-outlined text-red-500 text-2xl">cancel</span>`

    this.feedbackAreaTarget.innerHTML = `
      <div class="${isCorrect ? "bg-green-50 border-green-200" : "bg-red-50 border-red-200"} border rounded-xl p-4">
        <div class="flex items-start gap-3">
          ${icon}
          <div>
            <p class="font-bold ${isCorrect ? "text-green-700" : "text-red-600"} mb-1">
              ${isCorrect ? "정답입니다!" : "오답입니다"}
            </p>
            <p class="text-slate-600 text-sm leading-relaxed">${q.explanation}</p>
          </div>
        </div>
      </div>
    `
    this.feedbackAreaTarget.classList.remove("hidden")

    // 다음 버튼 텍스트 설정
    const isLast = this.currentValue === this.questionsValue.length - 1
    this.nextBtnTarget.innerHTML = isLast
      ? `결과 보기 <span class="material-symbols-outlined">emoji_events</span>`
      : `다음 문제 <span class="material-symbols-outlined">arrow_forward</span>`
    this.nextAreaTarget.classList.remove("hidden")
  }

  // 다음 문제로 이동
  nextQuestion() {
    this.currentValue++
    if (this.currentValue >= this.questionsValue.length) {
      this.showResults()
    } else {
      this.showQuestion()
    }
  }

  // 결과 화면 표시
  showResults() {
    const total = this.questionsValue.length
    const score = this.scoreValue
    const pct = Math.round((score / total) * 100)

    // 일반 모드에서만 점수 저장
    if (!this.wrongModeValue) {
      const subjectId = this.element.dataset.examQuizSubjectIdValue || "all"
      saveQuizScore(subjectId, score, total)
    }

    // 등급 결정
    let grade, gradeColor, gradeIcon, gradeBg
    if (pct >= 90) {
      grade = "최우수"; gradeColor = "text-yellow-600"; gradeIcon = "workspace_premium"; gradeBg = "bg-yellow-50 border-yellow-200"
    } else if (pct >= 80) {
      grade = "우수"; gradeColor = "text-green-600"; gradeIcon = "emoji_events"; gradeBg = "bg-green-50 border-green-200"
    } else if (pct >= 60) {
      grade = "합격권"; gradeColor = "text-blue-600"; gradeIcon = "thumb_up"; gradeBg = "bg-blue-50 border-blue-200"
    } else {
      grade = "추가 학습 필요"; gradeColor = "text-slate-600"; gradeIcon = "school"; gradeBg = "bg-slate-50 border-slate-200"
    }

    // 진행바 100%
    this.progressBarTarget.style.width = "100%"
    this.currentNumTarget.textContent = total

    // 문제 영역 숨기기
    this.questionAreaTarget.classList.add("hidden")

    // 오답 모드 결과 vs 일반 모드 결과
    const wrongRemaining = getWrongAnswerIds().length
    const actionButtons = this.wrongModeValue
      ? `
        <a href="/quiz/wrong"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-orange-500 hover:bg-orange-600 text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">refresh</span>
          오답 다시 풀기 ${wrongRemaining > 0 ? `<span class="bg-white/30 text-white text-xs font-bold px-2 py-0.5 rounded-full ml-1">${wrongRemaining}</span>` : ""}
        </a>
        <a href="/quiz"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-blue-400 text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">apps</span>
          모의고사 선택
        </a>
      `
      : `
        <button data-action="click->exam-quiz#retryQuiz"
                class="flex-1 inline-flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">refresh</span>
          다시 풀기
        </button>
        ${wrongRemaining > 0 ? `
        <a href="/quiz/wrong"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-orange-50 border-2 border-orange-300 hover:border-orange-400 text-orange-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">error_outline</span>
          오답 노트 <span class="bg-orange-500 text-white text-xs font-bold px-2 py-0.5 rounded-full ml-1">${wrongRemaining}</span>
        </a>` : `
        <a href="/quiz"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-blue-400 text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">apps</span>
          다른 과목 선택
        </a>`}
      `

    // 결과 화면 렌더링
    this.resultAreaTarget.innerHTML = `
      <!-- 점수 카드 -->
      <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-8 text-center mb-6">
        <div class="w-20 h-20 ${gradeBg.split(" ")[0]} rounded-full flex items-center justify-center mx-auto mb-4">
          <span class="material-symbols-outlined ${gradeColor} text-4xl">${gradeIcon}</span>
        </div>
        <div class="text-6xl font-extrabold text-slate-800 mb-1">${pct}<span class="text-3xl text-slate-400">%</span></div>
        <div class="text-2xl font-bold ${gradeColor} mb-2">${grade}</div>
        <div class="text-slate-500 text-sm">${total}문제 중 ${score}문제 정답</div>
        ${this.wrongModeValue && score > 0 ? `<div class="text-green-600 text-sm mt-2 font-semibold">${score}개 문제가 오답 노트에서 제거되었습니다 ✓</div>` : ""}
      </div>

      <!-- 학습 가이드 -->
      ${this.buildReview()}

      <!-- 액션 버튼 -->
      <div class="flex flex-col sm:flex-row gap-3 mt-6">
        ${actionButtons}
      </div>
    `
    this.resultAreaTarget.classList.remove("hidden")
  }

  // 학습 가이드 빌드
  buildReview() {
    return `
      <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
        <h3 class="font-bold text-slate-800 mb-4 flex items-center gap-2">
          <span class="material-symbols-outlined text-blue-500">checklist</span>
          학습 가이드
        </h3>
        <p class="text-slate-600 text-sm mb-4">
          틀린 문제는 커리큘럼 페이지에서 해당 챕터를 복습하세요.
        </p>
        <div class="grid grid-cols-2 gap-3">
          <a href="/subjects/1" class="flex items-center gap-2 p-3 bg-emerald-50 border border-emerald-200 rounded-xl hover:bg-emerald-100 transition-colors">
            <span class="material-symbols-outlined text-emerald-600 text-lg">public</span>
            <div>
              <div class="text-xs text-emerald-600 font-semibold">1권</div>
              <div class="text-slate-700 text-sm font-medium">공공조달의 이해</div>
            </div>
          </a>
          <a href="/subjects/2" class="flex items-center gap-2 p-3 bg-blue-50 border border-blue-200 rounded-xl hover:bg-blue-100 transition-colors">
            <span class="material-symbols-outlined text-blue-600 text-lg">analytics</span>
            <div>
              <div class="text-xs text-blue-600 font-semibold">2권</div>
              <div class="text-slate-700 text-sm font-medium">공공조달 계획분석</div>
            </div>
          </a>
          <a href="/subjects/3" class="flex items-center gap-2 p-3 bg-violet-50 border border-violet-200 rounded-xl hover:bg-violet-100 transition-colors">
            <span class="material-symbols-outlined text-violet-600 text-lg">contract</span>
            <div>
              <div class="text-xs text-violet-600 font-semibold">3권</div>
              <div class="text-slate-700 text-sm font-medium">공공계약관리</div>
            </div>
          </a>
          <a href="/subjects/4" class="flex items-center gap-2 p-3 bg-rose-50 border border-rose-200 rounded-xl hover:bg-rose-100 transition-colors">
            <span class="material-symbols-outlined text-rose-600 text-lg">settings</span>
            <div>
              <div class="text-xs text-rose-600 font-semibold">4권</div>
              <div class="text-slate-700 text-sm font-medium">공공조달 관리실무</div>
            </div>
          </a>
        </div>
      </div>
    `
  }

  // 다시 풀기
  retryQuiz() {
    this.currentValue = 0
    this.scoreValue = 0
    this.answeredValue = false
    this.scoreDisplayTarget.textContent = "0"
    this.resultAreaTarget.classList.add("hidden")
    this.questionAreaTarget.classList.remove("hidden")
    this.showQuestion()
  }
}
