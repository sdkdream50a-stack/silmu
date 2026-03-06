import { Controller } from "@hotwired/stimulus"

const ALL_QUIZ_DATA = [
  { category: "예산회계", question: "다음 중 예산의 이월에 해당하지 않는 것은?", options: ["명시이월", "사고이월", "계속비이월", "예비비이월"], answer: 3, explanation: "예비비이월은 존재하지 않는 개념입니다." },
  { category: "예산회계", question: "다음 중 세출예산의 이용에 해당하는 것은?", options: ["장 간의 상호융통", "관 간의 상호융통", "항 간의 상호융통", "세항 간의 상호융통"], answer: 2, explanation: "이용은 입법과목인 '항' 간의 상호융통을 말합니다." },
  { category: "예산회계", question: "예비비 사용 후 국회 승인을 받아야 하는 기한은?", options: ["다음 연도 정기회 개회 전", "다음 연도 정기회 중", "사용 후 3개월 이내", "사용 후 6개월 이내"], answer: 1, explanation: "예비비 사용 후 다음 연도 정기회 중에 국회의 승인을 받아야 합니다." },
  { category: "예산회계", question: "사고이월의 요건이 아닌 것은?", options: ["연도 내 지출원인행위", "불가피한 사유", "세입세출예산에 명시", "연도 내 지출하지 못한 경비"], answer: 2, explanation: "세입세출예산에 명시하는 것은 명시이월의 요건입니다." },
  { category: "예산회계", question: "예산의 전용이란?", options: ["회계연도 간 이월", "항 간의 상호융통", "세항·목 간의 상호융통", "예비비 사용"], answer: 2, explanation: "전용은 행정과목인 세항·목 간의 상호융통을 말합니다." },
  { category: "계약", question: "물품 구매 시 1인 견적 수의계약이 가능한 추정가격(부가세 별도) 기준은?", options: ["1천만원 이하", "2천만원 이하", "3천만원 이하", "5천만원 이하"], answer: 1, explanation: "물품·용역의 경우 추정가격 2천만원 이하일 때 1인 견적 수의계약이 가능합니다." },
  { category: "계약", question: "나라장터 전자입찰 시 입찰공고 기간은 최소 며칠인가?", options: ["5일", "7일", "10일", "14일"], answer: 1, explanation: "전자입찰의 경우 입찰공고 기간은 최소 7일 이상입니다." },
  { category: "계약", question: "계약보증금의 원칙적인 비율은?", options: ["계약금액의 5%", "계약금액의 10%", "계약금액의 15%", "계약금액의 20%"], answer: 1, explanation: "계약보증금은 계약금액의 10% 이상으로 납부해야 합니다." },
  { category: "계약", question: "선금의 지급 한도는?", options: ["계약금액의 50%", "계약금액의 60%", "계약금액의 70%", "계약금액의 80%"], answer: 2, explanation: "선금은 계약금액의 70% 이내에서 지급할 수 있습니다." },
  { category: "계약", question: "복수예비가격 작성 개수는?", options: ["10개", "15개", "20개", "25개"], answer: 1, explanation: "복수예비가격은 15개를 작성합니다." },
  { category: "복무", question: "공무원의 병가 일수는 연간 최대 며칠인가?", options: ["30일", "60일", "90일", "120일"], answer: 1, explanation: "공무원의 병가는 연 60일 이내입니다." },
  { category: "복무", question: "재직기간 1년 미만 공무원의 연가 일수는?", options: ["8일", "11일", "14일", "15일"], answer: 1, explanation: "재직기간 1년 미만 공무원의 연가 일수는 11일입니다." },
  { category: "복무", question: "배우자 출산휴가 일수는?", options: ["5일", "10일", "15일", "20일"], answer: 3, explanation: "배우자 출산휴가는 20일입니다. (2025년 공무원복무규정 개정)" },
  { category: "문서", question: "공문서의 보존기간 중 '영구'에 해당하는 것은?", options: ["일반 통계자료", "조례·규칙", "단순 민원서류", "일일업무보고"], answer: 1, explanation: "조례, 규칙 등 법규문서는 영구 보존 대상입니다." },
  { category: "민원", question: "정보공개 청구에 대한 결정 기한은?", options: ["5일 이내", "7일 이내", "10일 이내", "14일 이내"], answer: 2, explanation: "정보공개 청구를 받은 날부터 10일 이내에 공개 여부를 결정해야 합니다." },
  { category: "감사", question: "일상감사 대상이 아닌 것은?", options: ["계약", "예산 전용", "국고보조금 교부", "일반 민원처리"], answer: 3, explanation: "일반 민원처리는 일상감사 대상이 아닙니다." },
  { category: "인사", question: "5급 공무원의 정년은?", options: ["58세", "60세", "62세", "65세"], answer: 1, explanation: "일반직 공무원의 정년은 60세입니다." },
  { category: "계약", question: "지체상금률의 상한은?", options: ["계약금액의 10%", "계약금액의 15%", "계약금액의 20%", "계약금액의 30%"], answer: 0, explanation: "지체상금은 계약금액의 10%를 초과할 수 없습니다." },
  { category: "예산회계", question: "지방자치단체의 출납폐쇄일은?", options: ["12월 31일", "다음 연도 1월 31일", "다음 연도 2월 말일", "다음 연도 3월 31일"], answer: 2, explanation: "지방자치단체의 출납폐쇄일은 다음 연도 2월 말일입니다." },
  { category: "복무", question: "시간외근무수당 지급 단가 산정 시 사용하는 분모는?", options: ["174시간", "209시간", "226시간", "243시간"], answer: 1, explanation: "시간외근무수당은 월 봉급액을 209시간으로 나눈 금액을 기준으로 산정합니다." }
]

// 날짜 seed 기반 결정론적 Fisher-Yates shuffle (편향 없음)
function seededShuffle(arr, seed) {
  const result = [...arr]
  let s = seed
  for (let i = result.length - 1; i > 0; i--) {
    // LCG: next seed
    s = (s * 1664525 + 1013904223) >>> 0
    const j = s % (i + 1)
    ;[result[i], result[j]] = [result[j], result[i]]
  }
  return result
}

function getDailyQuiz() {
  const today = new Date()
  const seed = today.getFullYear() * 10000 + (today.getMonth() + 1) * 100 + today.getDate()
  return seededShuffle(ALL_QUIZ_DATA, seed).slice(0, 5)
}

export default class extends Controller {
  static targets = [
    "progress", "category", "question", "options",
    "result", "resultMessage", "resultExplanation",
    "submit", "final", "finalScore", "footer"
  ]

  connect() {
    this.quizData = getDailyQuiz()
    this.currentQuestion = 0
    this.score = 0
    this.selectedOption = null
    this.answered = false
    this.renderQuestion()
  }

  renderQuestion() {
    const q = this.quizData[this.currentQuestion]
    this.progressTarget.textContent = `문제 ${this.currentQuestion + 1}/5`
    this.categoryTarget.textContent = q.category
    this.questionTarget.textContent = q.question
    this.optionsTarget.innerHTML = q.options.map((opt, i) => `
      <button data-index="${i}" data-action="click->home-quiz#selectOption" class="quiz-option w-full text-left p-4 rounded-xl bg-slate-800/50 hover:bg-slate-700/50 border border-white/5 text-slate-200 text-sm transition-all cursor-pointer flex items-center gap-3">
        <span class="w-7 h-7 rounded-full border border-white/20 flex items-center justify-center text-xs font-medium shrink-0">${String.fromCharCode(65 + i)}</span>
        <span>${opt}</span>
      </button>
    `).join("")
    this.selectedOption = null
    this.answered = false
    this.resultTarget.classList.add("hidden")
    this.resultTarget.classList.remove("bg-emerald-500/20", "bg-red-500/20")
    this.resultMessageTarget.classList.remove("text-emerald-300", "text-red-300")
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "정답 확인"
  }

  selectOption(event) {
    if (this.answered) return
    this.optionsTarget.querySelectorAll(".quiz-option").forEach(o => {
      o.classList.remove("bg-indigo-600/30", "border-indigo-400")
      o.classList.add("bg-slate-800/50", "border-white/5")
    })
    const btn = event.currentTarget
    btn.classList.remove("bg-slate-800/50", "border-white/5")
    btn.classList.add("bg-indigo-600/30", "border-indigo-400")
    this.selectedOption = btn
    this.submitTarget.disabled = false
  }

  submit() {
    if (!this.selectedOption) return
    if (!this.answered) {
      this.answered = true
      const q = this.quizData[this.currentQuestion]
      const si = parseInt(this.selectedOption.dataset.index)
      const correct = si === q.answer
      if (correct) this.score++
      this.optionsTarget.querySelectorAll(".quiz-option").forEach(o => {
        o.classList.add("cursor-not-allowed")
        const idx = parseInt(o.dataset.index)
        if (idx === q.answer) {
          o.classList.remove("bg-slate-800/50", "bg-indigo-600/30")
          o.classList.add("bg-emerald-600/30", "border-emerald-400")
        } else if (o === this.selectedOption && !correct) {
          o.classList.remove("bg-indigo-600/30")
          o.classList.add("bg-red-500/30", "border-red-400")
        }
      })
      this.resultTarget.classList.remove("hidden")
      if (correct) {
        this.resultTarget.classList.add("bg-emerald-500/20")
        this.resultMessageTarget.textContent = "정답입니다!"
        this.resultMessageTarget.classList.add("text-emerald-300")
      } else {
        this.resultTarget.classList.add("bg-red-500/20")
        this.resultMessageTarget.textContent = "오답입니다."
        this.resultMessageTarget.classList.add("text-red-300")
      }
      this.resultExplanationTarget.textContent = q.explanation
      this.submitTarget.textContent = this.currentQuestion < this.quizData.length - 1 ? "다음 문제 →" : "결과 보기"
    } else {
      if (this.currentQuestion < this.quizData.length - 1) {
        this.currentQuestion++
        this.renderQuestion()
      } else {
        this.questionTarget.classList.add("hidden")
        this.optionsTarget.classList.add("hidden")
        this.resultTarget.classList.add("hidden")
        this.footerTarget.classList.add("hidden")
        this.finalTarget.classList.remove("hidden")
        this.finalScoreTarget.textContent = this.score
      }
    }
  }

  restart() {
    this.currentQuestion = 0
    this.score = 0
    this.questionTarget.classList.remove("hidden")
    this.optionsTarget.classList.remove("hidden")
    this.footerTarget.classList.remove("hidden")
    this.finalTarget.classList.add("hidden")
    this.renderQuestion()
  }
}
