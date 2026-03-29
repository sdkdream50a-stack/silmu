// exam.silmu.kr — 모의고사 문제풀이 Stimulus 컨트롤러
import { Controller } from "@hotwired/stimulus"
import { saveQuizScore, saveChapterQuizDone, saveWrongAnswer, removeWrongAnswer, getWrongAnswerIds, saveStreakToday, toggleBookmark, isBookmarked, getBookmarkIds } from "../exam_progress"
import { escapeHtml, getCsrfToken } from "../exam_utils"

export default class extends Controller {
  static targets = [
    "progressArea", "progressBar", "currentNum", "totalNum", "scoreDisplay",
    "questionArea", "questionBadge", "questionText", "optionsArea",
    "feedbackArea", "nextArea", "nextBtn", "resultArea", "emptyArea",
    "chapterSummaryArea"
  ]
  static values = {
    questions: Array,
    current: { type: Number, default: 0 },
    score: { type: Number, default: 0 },
    answered: { type: Boolean, default: false },
    wrongMode: { type: Boolean, default: false },
    bookmarkMode: { type: Boolean, default: false },
    backPath: { type: String, default: "" },
    chapterMap: { type: Object, default: {} },
    topicMap: { type: Object, default: {} },
    signedIn: { type: Boolean, default: false },
    questionsApiUrl: { type: String, default: "" }
  }

  async connect() {
    // 챕터별 통계 초기화
    this.wrongByChapter = {}
    this.totalByChapter = {}
    // 난이도별 통계 초기화
    this.diffStats = { basic: { total: 0, wrong: 0 }, advanced: { total: 0, wrong: 0 } }

    // 키보드 단축키 등록
    this._keyHandler = this._handleKeydown.bind(this)
    document.addEventListener('keydown', this._keyHandler)

    if (this.wrongModeValue) {
      const wrongIds = getWrongAnswerIds()
      if (wrongIds.length === 0) {
        this.showEmpty()
        return
      }
      // API 기반 fetch (P0-2 최적화) 또는 pre-loaded 문제 필터링 (legacy fallback)
      if (this.questionsApiUrlValue) {
        const fetched = await this._fetchQuestionsByIds(wrongIds)
        if (fetched.length === 0) { this.showEmpty(); return }
        this.questionsValue = fetched
      } else {
        this.questionsValue = this.questionsValue.filter(q => wrongIds.includes(q.id))
        if (this.questionsValue.length === 0) { this.showEmpty(); return }
      }
      // 진행바 total 업데이트
      if (this.hasTotalNumTarget) this.totalNumTarget.textContent = this.questionsValue.length
      // 취약 챕터 요약 렌더링
      if (this.hasChapterSummaryAreaTarget) {
        this.chapterSummaryAreaTarget.innerHTML = this.buildWrongChapterSummary()
      }
    } else if (this.bookmarkModeValue) {
      const bookmarkIds = getBookmarkIds()
      if (bookmarkIds.length === 0) {
        this.showEmpty()
        return
      }
      // API 기반 fetch (P0-2 최적화) 또는 pre-loaded 문제 필터링 (legacy fallback)
      if (this.questionsApiUrlValue) {
        const fetched = await this._fetchQuestionsByIds(bookmarkIds)
        if (fetched.length === 0) { this.showEmpty(); return }
        this.questionsValue = fetched
      } else {
        this.questionsValue = this.questionsValue.filter(q => bookmarkIds.includes(q.id))
        if (this.questionsValue.length === 0) { this.showEmpty(); return }
      }
      // 진행바 total 업데이트
      if (this.hasTotalNumTarget) this.totalNumTarget.textContent = this.questionsValue.length
    }
    this.showQuestion()
  }

  // ID 배열로 서버에서 문제 fetch
  async _fetchQuestionsByIds(ids) {
    try {
      const url = new URL(this.questionsApiUrlValue, window.location.origin)
      ids.forEach(id => url.searchParams.append('ids[]', id))
      const res = await fetch(url, { headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' } })
      if (!res.ok) return []
      const data = await res.json()
      return data.questions || []
    } catch (e) {
      console.error('문제 fetch 오류:', e)
      return []
    }
  }

  // 오답 노트 취약 챕터 요약 (진입 시 표시)
  buildWrongChapterSummary() {
    const chapterMap = this.chapterMapValue
    const countByChapter = {}
    this.questionsValue.forEach(q => {
      if (!q.subject_id || !q.chapter_num) return
      const key = `${q.subject_id}-${q.chapter_num}`
      countByChapter[key] = (countByChapter[key] || 0) + 1
    })

    const entries = Object.entries(countByChapter)
    if (entries.length === 0) return ""

    const sorted = entries
      .map(([key, count]) => {
        const info = chapterMap[key] || {}
        return {
          key,
          count,
          title: info.title || `제${key.split("-")[1]}장`,
          subjectNumber: info.subject_number || `${key.split("-")[0]}권`
        }
      })
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)

    const rows = sorted.map(c => {
      const [subId, chapNum] = c.key.split("-")
      const chapterUrl = `/subjects/${subId}/chapters/${chapNum}`
      return `
        <div class="flex items-center justify-between py-2 border-b border-slate-100 last:border-0">
          <div class="flex-1 min-w-0">
            <span class="text-xs font-bold text-slate-400 mr-1">${c.subjectNumber}</span>
            <span class="text-sm font-medium text-slate-700">${c.title}</span>
          </div>
          <div class="flex items-center gap-1.5 flex-shrink-0 ml-3">
            <span class="text-xs font-bold bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full">${c.count}문제</span>
            <a href="${chapterUrl}"
               class="text-xs font-bold bg-[#00464a] text-white px-2 py-0.5 rounded-full hover:bg-[#005558] transition-colors">
              학습 →
            </a>
          </div>
        </div>`
    }).join("")

    return `
      <div class="bg-orange-50 border border-orange-200 rounded-2xl p-5">
        <h3 class="font-bold text-orange-800 mb-1 flex items-center gap-2 text-sm">
          <span class="material-symbols-outlined text-orange-500 text-lg">bar_chart</span>
          취약 챕터 현황 — 오답 ${this.questionsValue.length}문제
        </h3>
        <p class="text-orange-600 text-xs mb-3">오답이 많은 챕터부터 집중 복습하세요.</p>
        ${rows}
      </div>`
  }

  disconnect() {
    document.removeEventListener('keydown', this._keyHandler)
  }

  _handleKeydown(e) {
    // 입력 필드에 포커스 있으면 무시
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return

    if (['1','2','3','4'].includes(e.key) && !this.answeredValue) {
      const idx = parseInt(e.key) - 1
      const btn = this.optionsAreaTarget.querySelectorAll('.option-btn')[idx]
      if (btn) btn.click()
    } else if ((e.key === 'Enter' || e.key === ' ') && !this.nextAreaTarget.classList.contains('hidden')) {
      e.preventDefault()
      this.nextQuestion()
    } else if (e.key === 'b' || e.key === 'B') {
      // 현재 문제 북마크 토글
      const bBtn = this.questionBadgeTarget.querySelector('[data-action*="bookmarkQuestion"]')
      if (bBtn) bBtn.click()
    }
  }

  // 오답 없음 상태 표시
  showEmpty() {
    if (this.hasQuestionAreaTarget) this.questionAreaTarget.classList.add("hidden")
    if (this.hasProgressAreaTarget) this.progressAreaTarget.classList.add("hidden")
    if (this.hasEmptyAreaTarget) this.emptyAreaTarget.classList.remove("hidden")
  }

  // 문제 ID + 난이도 기반 의사랜덤 정답률 계산
  calcSuccessRate(questionId, difficulty) {
    const seed = (questionId * 2654435761) >>> 0
    const rand = (seed % 1000) / 1000
    if (difficulty === 'advanced') {
      return Math.round(40 + rand * 20)  // 40~60%
    }
    return Math.round(65 + rand * 20)  // 65~85%
  }

  // 북마크 토글
  bookmarkQuestion(event) {
    const btn = event.currentTarget
    const qId = parseInt(btn.dataset.questionId)
    const added = toggleBookmark(qId)
    const icon = btn.querySelector('.bookmark-icon')
    if (icon) {
      icon.textContent = added ? 'bookmark' : 'bookmark_border'
      icon.style.color = added ? '#64748b' : '#cbd5e1'
    }
  }

  // 현재 문제 렌더링
  showQuestion() {
    const q = this.questionsValue[this.currentValue]
    if (!q) return

    const total = this.questionsValue.length
    const idx = this.currentValue

    // 진행바 업데이트 (트랜지션은 CSS .exam-progress-bar로 처리)
    this.progressBarTarget.style.width = `${(idx / total) * 100}%`
    this.currentNumTarget.textContent = idx + 1

    // 문제 배지 & 텍스트 (챕터 정보 포함)
    const chapterKey = q.subject_id && q.chapter_num ? `${q.subject_id}-${q.chapter_num}` : null
    const chapterInfo = chapterKey ? (this.chapterMapValue[chapterKey] || {}) : {}
    const chapterBadgeHtml = chapterInfo.title
      ? `<span class="inline-flex items-center gap-1 bg-slate-100 text-slate-500 text-xs px-2.5 py-1 rounded-full">
           <span class="font-bold text-slate-400">${chapterInfo.subject_number}</span>
           ${chapterInfo.title}
         </span>`
      : ""
    // 난이도 뱃지
    const diffBadgeHtml = q.difficulty === "advanced"
      ? `<span class="inline-flex items-center gap-0.5 bg-rose-100 text-rose-700 text-xs font-bold px-2.5 py-1 rounded-full">
           <span class="material-symbols-outlined text-xs" style="font-size:13px">local_fire_department</span>심화
         </span>`
      : `<span class="inline-flex items-center gap-0.5 bg-emerald-100 text-emerald-700 text-xs font-bold px-2.5 py-1 rounded-full">
           <span class="material-symbols-outlined text-xs" style="font-size:13px">star</span>기초
         </span>`
    const successRate = this.calcSuccessRate(q.id, q.difficulty)
    const rateBadgeHtml = `<span class="inline-flex items-center gap-0.5 bg-slate-100 text-slate-500 text-xs px-2.5 py-1 rounded-full">정답률 ${successRate}%</span>`
    const bookmarked = isBookmarked(q.id)
    const bookmarkBtnHtml = `
      <button data-action="click->exam-quiz#bookmarkQuestion" data-question-id="${q.id}"
              class="ml-auto p-1.5 rounded-full hover:bg-slate-100 transition-colors flex-shrink-0"
              title="북마크">
        <span class="material-symbols-outlined bookmark-icon text-xl" style="color:${bookmarked ? '#64748b' : '#cbd5e1'}">${bookmarked ? 'bookmark' : 'bookmark_border'}</span>
      </button>
    `
    this.questionBadgeTarget.innerHTML = `<span class="inline-flex items-center gap-1 bg-[#d9f4f5] text-[#00464a] text-xs font-bold px-3 py-1 rounded-full">문제 ${idx + 1}</span>${chapterBadgeHtml}${diffBadgeHtml}${rateBadgeHtml}${bookmarkBtnHtml}`
    this.questionTextTarget.textContent = q.question

    // 선택지 렌더링
    const labels = ["①", "②", "③", "④"]
    this.optionsAreaTarget.innerHTML = q.options.map((opt, i) => `
      <button
        class="option-btn w-full flex items-center gap-2 text-left px-5 py-3.5 rounded-xl bg-[#f2f4f4] hover:bg-[#eceeee] transition-all text-slate-700 text-sm font-medium"
        data-index="${i}"
        data-action="click->exam-quiz#selectAnswer">
        <span class="font-bold text-slate-400 mr-1 text-base flex-shrink-0">${labels[i]}</span>
        <span class="flex-1">${this.escapeHtml(opt)}</span>
      </button>
    `).join("")

    // 피드백/다음 버튼 숨기기
    this.feedbackAreaTarget.classList.add("hidden")
    this.feedbackAreaTarget.innerHTML = ""
    this.nextAreaTarget.classList.add("hidden")
    this.answeredValue = false
  }

  // #6 서버 동기화
  async syncToServer(quizCompleted = false, quizScore = 0, quizTotal = 0) {
    try {
      const progress = JSON.parse(localStorage.getItem('exam_progress') || '{}')
      const wrongAnswers = JSON.parse(localStorage.getItem('exam_wrong_answers') || '[]')
      const bookmarks = JSON.parse(localStorage.getItem('exam_bookmarks') || '[]')
      const streak = JSON.parse(localStorage.getItem('exam_streak') || '{}')

      const csrfToken = getCsrfToken()
      if (!csrfToken) return

      await fetch('/sync', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({
          chapters: progress.chapters || {},
          quizzes: progress.quizzes || {},
          chapter_quizzes: progress.chapterQuizzes || {},
          wrong_answers: wrongAnswers,
          bookmarks: bookmarks,
          streak_count: streak.count || 0,
          streak_last_date: streak.lastDate || null,
          streak_history: streak.history || [],
          quiz_completed: quizCompleted ? "1" : "",
          quiz_score: quizCompleted ? quizScore : 0,
          quiz_total: quizCompleted ? quizTotal : 0
        })
      })
    } catch(e) {}
  }

  // 선택지 클릭 처리
  selectAnswer(event) {
    if (this.answeredValue) return
    this.answeredValue = true

    const selected = parseInt(event.currentTarget.dataset.index)
    const q = this.questionsValue[this.currentValue]
    const correct = q.correct
    const isCorrect = selected === correct

    // 챕터별 통계 누적
    const chapterKey = `${q.subject_id}-${q.chapter_num}`
    if (chapterKey !== 'undefined-undefined') {
      this.totalByChapter[chapterKey] = (this.totalByChapter[chapterKey] || 0) + 1
      if (!isCorrect) {
        this.wrongByChapter[chapterKey] = (this.wrongByChapter[chapterKey] || 0) + 1
      }
    }
    // 난이도별 통계 누적
    const diff = q.difficulty || "basic"
    this.diffStats[diff].total++
    if (!isCorrect) this.diffStats[diff].wrong++

    if (isCorrect) {
      this.scoreValue++
      this.scoreDisplayTarget.textContent = this.scoreValue
      removeWrongAnswer(q.id)  // 맞히면 오답 노트에서 제거
    } else {
      saveWrongAnswer(q.id)    // 틀리면 오답 노트에 추가
    }

    // 선택지 색상 + 아이콘 업데이트 (색각 이상 접근성 — 색상 + 아이콘 이중 표현)
    this.optionsAreaTarget.querySelectorAll(".option-btn").forEach((btn, i) => {
      btn.disabled = true
      btn.classList.remove("hover:bg-[#eceeee]")
      // 기존 결과 아이콘 제거
      btn.querySelector('.result-icon')?.remove()
      const icon = document.createElement('span')
      icon.className = 'material-symbols-outlined result-icon text-base ml-auto flex-shrink-0'
      if (i === correct) {
        btn.classList.add("border-green-500", "bg-green-50", "text-green-800")
        icon.textContent = 'check_circle'
        icon.classList.add('text-green-600')
        btn.appendChild(icon)
        // 정답 버튼 pulse 애니메이션
        btn.classList.add('exam-answer-correct')
      } else if (i === selected) {
        btn.classList.add("border-red-400", "bg-red-50", "text-red-700")
        icon.textContent = 'cancel'
        icon.classList.add('text-red-500')
        btn.appendChild(icon)
        // 오답 버튼 shake 애니메이션
        btn.classList.add('exam-answer-wrong')
      } else {
        btn.classList.add("opacity-50")
      }
    })

    // 피드백 표시
    const icon = isCorrect
      ? `<span class="material-symbols-outlined text-green-600 text-2xl">check_circle</span>`
      : `<span class="material-symbols-outlined text-red-500 text-2xl">cancel</span>`

    // #7 AI 해설 버튼 (오답일 때만)
    const aiBtn = !isCorrect ? `
      <button data-action="click->exam-quiz#fetchAiExplanation"
              data-question-id="${q.id}"
              data-selected-index="${selected}"
              class="ai-explain-btn mt-3 inline-flex items-center gap-2 bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-semibold px-3 py-2 rounded-lg hover:bg-indigo-100 transition-colors">
        <span class="material-symbols-outlined text-sm">psychology</span>
        AI 추가 해설 보기
      </button>
      <div class="ai-explanation-area hidden mt-3 text-sm text-slate-700 bg-indigo-50 rounded-lg p-3 leading-relaxed border-l-2 border-indigo-400"></div>
    ` : ''

    // #10 Q&A 영역 (자동 펼침)
    const commentForm = this.signedInValue
      ? `<form class="qa-form flex gap-2 mt-2" data-action="submit->exam-quiz#submitComment">
          <input type="hidden" name="question_id" value="${q.id}">
          <input type="hidden" name="question_text" value="${(q.question || '').replace(/"/g, '&quot;')}">
          <input type="text" name="body" placeholder="5자 이상 질문이나 의견을 남겨보세요..."
                 class="flex-1 text-sm border border-slate-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
          <button type="submit" class="bg-[#00464a] text-white text-xs font-bold px-3 py-2 rounded-lg hover:bg-[#005558] whitespace-nowrap">등록</button>
        </form>
        <p class="text-xs text-slate-400">AI가 댓글 품질을 자동으로 검토합니다.</p>`
      : `<div class="bg-[#d9f4f5] border border-[#a6eff3] rounded-lg px-4 py-3 text-sm text-[#00464a] flex items-center gap-2 mt-2">
          <span class="material-symbols-outlined text-base">login</span>
          <span><a href="/users/sign_in" class="font-bold underline hover:no-underline">로그인</a>하면 댓글을 남길 수 있습니다.</span>
        </div>`
    const qaBtn = `
      <button data-action="click->exam-quiz#toggleQA"
              data-question-id="${q.id}"
              data-question-text="${(q.question || '').replace(/"/g, '&quot;')}"
              class="mt-3 inline-flex items-center gap-2 text-slate-500 text-xs hover:text-slate-700 transition-colors">
        <span class="material-symbols-outlined text-sm">chat_bubble_outline</span>
        이 문제 토론
        <span class="material-symbols-outlined text-sm qa-toggle-icon">expand_less</span>
      </button>
      <div class="qa-area mt-3 bg-slate-50 rounded-xl border border-slate-200 p-4 space-y-3">
        <div class="qa-comments space-y-2 text-sm text-slate-500">불러오는 중...</div>
        ${commentForm}
      </div>
    `

    // #오류신고 버튼 (항상 표시)
    const reportBtn = `
      <button data-action="click->exam-quiz#toggleReport"
              data-question-id="${q.id}"
              class="mt-2 inline-flex items-center gap-1 text-slate-400 hover:text-orange-500 text-xs transition-colors">
        <span class="material-symbols-outlined text-sm">flag</span>
        문제 오류 신고
      </button>
      <div class="report-area hidden mt-2 bg-orange-50 border border-orange-200 rounded-xl p-3">
        <p class="text-xs text-orange-700 font-semibold mb-2">어떤 오류가 있나요?</p>
        <textarea class="report-body w-full text-sm border border-orange-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-orange-400 resize-none" rows="2" placeholder="오류 내용을 5자 이상 설명해주세요..."></textarea>
        <div class="flex justify-end gap-2 mt-2">
          <button class="text-xs text-slate-500 hover:text-slate-700 px-2 py-1" data-action="click->exam-quiz#closeReport">취소</button>
          <button class="text-xs font-bold bg-orange-500 text-white px-3 py-1 rounded-lg hover:bg-orange-600" data-action="click->exam-quiz#submitReport" data-question-id="${q.id}">제보하기</button>
        </div>
      </div>
    `

    // 챕터별 관련 법령 가이드 링크 (silmu.kr 연결) — topicMapValue에서 챕터별 slug 조회
    const SLUG_TITLES = {
      'public-procurement-overview': '공공조달 개요',
      'private-contract': '수의계약',
      'bidding': '입찰 가이드',
      'bid-qualification': '입찰 참가자격',
      'e-procurement-guide': '전자조달 가이드',
      'e-bidding': '전자입찰',
      'mas-contract': '다수공급자계약',
      'national-vs-local-contract-law': '국가·지방계약법',
      'bid-participation-restriction': '입찰 참가제한',
      'estimated-price': '예정가격',
      'dual-quote': '이중입찰',
      'qualification-failure': '적격심사',
      'price-negotiation': '가격협상',
      'contract-guarantee-deposit': '계약보증금',
      'lowest-bid-rate': '최저가 낙찰률',
      'late-penalty': '지체상금',
      'payment': '대가지급',
      'design-change': '설계변경',
      'contract-termination': '계약해지',
      'goods-vs-service-contract': '물품·용역 계약',
      'goods-selection-committee': '물품선정위원회',
      'inspection': '검사·검수',
      'unit-price-contract': '단가계약',
      'subcontract': '하도급',
      'price-escalation': '물가변동',
      'defect-warranty': '하자담보',
      'cost-calculation-guide': '원가계산 가이드',
      'contract': '계약 실무',
      'budget': '예산 편성',
      'expense': '지출 실무'
    }
    const topicChapterKey = q.subject_id && q.chapter_num ? `${q.subject_id}-${q.chapter_num}` : null
    const slugs = topicChapterKey ? (this.topicMapValue[topicChapterKey] || []) : []
    const relatedTopics = slugs.map(slug => ({
      title: SLUG_TITLES[slug] || slug,
      url: `https://silmu.kr/topics/${slug}`
    }))
    const relatedLawHtml = relatedTopics.length > 0 ? `
      <div class="mt-3 pt-3 border-t border-slate-100">
        <p class="text-xs text-slate-400 font-semibold mb-2 flex items-center gap-1">
          <span class="material-symbols-outlined text-sm">menu_book</span>
          관련 법령 가이드 (실무.kr)
        </p>
        <div class="flex flex-wrap gap-2">
          ${relatedTopics.map(t => `
            <a href="${t.url}" target="_blank" rel="noopener"
               class="inline-flex items-center gap-1 text-xs text-[#00464a] bg-[#d9f4f5] hover:bg-[#a6eff3]/30 border border-[#a6eff3] px-2.5 py-1 rounded-full transition-colors">
              <span class="material-symbols-outlined text-xs">open_in_new</span>
              ${t.title}
            </a>
          `).join('')}
        </div>
      </div>
    ` : ''

    this.feedbackAreaTarget.innerHTML = `
      <div class="${isCorrect ? "bg-green-50 border-green-200" : "bg-red-50 border-red-200"} border rounded-xl p-4">
        <div class="flex items-start gap-3">
          ${icon}
          <div class="flex-1">
            <p class="font-bold ${isCorrect ? "text-green-700" : "text-red-600"} mb-1">
              ${isCorrect ? "정답입니다!" : "오답입니다"}
            </p>
            <p class="text-slate-600 text-sm leading-relaxed">${this.escapeHtml(q.explanation)}</p>
            ${aiBtn}
            ${relatedLawHtml}
          </div>
        </div>
      </div>
      ${qaBtn}
      ${reportBtn}
    `
    this.feedbackAreaTarget.classList.remove("hidden")

    // QA 댓글 자동 로드
    const qaArea = this.feedbackAreaTarget.querySelector('.qa-area')
    if (qaArea) this.loadComments(q.id, qaArea)

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
    if (!this.wrongModeValue && !this.bookmarkModeValue) {
      const subjectId = this.element.dataset.examQuizSubjectIdValue || "all"
      saveQuizScore(subjectId, score, total)
      // 챕터 퀴즈 완주 배지 저장
      const chapterNum = parseInt(this.element.dataset.examQuizChapterNumValue || "0")
      if (chapterNum > 0) {
        saveChapterQuizDone(subjectId, chapterNum, pct)
      }
      // 학습 스트릭 업데이트
      saveStreakToday()
      this._updateNavStreakBadge()
      // #6 서버 동기화 (quiz_completed=true, 정답수·전체수 전송)
      this.syncToServer(true, score, total)
    }

    // 등급 결정
    let grade, gradeColor, gradeIcon, gradeBg
    if (pct >= 90) {
      grade = "최우수"; gradeColor = "text-yellow-600"; gradeIcon = "workspace_premium"; gradeBg = "bg-yellow-50 border-yellow-200"
    } else if (pct >= 80) {
      grade = "우수"; gradeColor = "text-green-600"; gradeIcon = "emoji_events"; gradeBg = "bg-green-50 border-green-200"
    } else if (pct >= 60) {
      grade = "합격권"; gradeColor = "text-[#00464a]"; gradeIcon = "thumb_up"; gradeBg = "bg-[#d9f4f5] border-[#a6eff3]"
    } else {
      grade = "추가 학습 필요"; gradeColor = "text-slate-600"; gradeIcon = "school"; gradeBg = "bg-slate-50 border-slate-200"
    }

    // 진행바 100%
    this.progressBarTarget.style.width = "100%"
    this.currentNumTarget.textContent = total

    // 문제 영역 숨기기
    this.questionAreaTarget.classList.add("hidden")

    // 다음 챕터 URL 계산
    const chapterNum = parseInt(this.element.dataset.examQuizChapterNumValue || "0")
    const subjectId = this.element.dataset.examQuizSubjectIdValue || ""
    const SUBJECT_CHAPTERS = { "1": 7, "2": 6, "3": 6, "4": 8 }
    const maxChapters = SUBJECT_CHAPTERS[subjectId] || 0
    const hasNextChapter = chapterNum > 0 && subjectId && chapterNum < maxChapters
    const nextChapterUrl = hasNextChapter ? `/subjects/${subjectId}/chapters/${chapterNum + 1}` : null

    // 오답 모드 결과 vs 일반 모드 결과
    const wrongRemaining = getWrongAnswerIds().length
    const actionButtons = this.bookmarkModeValue
      ? `
        <a href="/quiz/bookmarks"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-indigo-500 hover:bg-indigo-600 text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">refresh</span>
          북마크 다시 풀기
        </a>
        <a href="/quiz"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-indigo-400 text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">apps</span>
          모의고사 선택
        </a>
      `
      : this.wrongModeValue
      ? `
        <a href="/quiz/wrong"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-orange-500 hover:bg-orange-600 text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">refresh</span>
          오답 다시 풀기 ${wrongRemaining > 0 ? `<span class="bg-white/30 text-white text-xs font-bold px-2 py-0.5 rounded-full ml-1">${wrongRemaining}</span>` : ""}
        </a>
        <a href="/quiz"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-[#a6eff3] text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">apps</span>
          모의고사 선택
        </a>
      `
      : `
        <button data-action="click->exam-quiz#retryQuiz"
                class="flex-1 inline-flex items-center justify-center gap-2 bg-[#00464a] hover:bg-[#005558] text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">refresh</span>
          다시 풀기
        </button>
        ${this.backPathValue ? `
        <a href="${this.backPathValue}"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-[#a6eff3] text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">arrow_back</span>
          챕터로 돌아가기
        </a>
        ${nextChapterUrl ? `
        <a href="${nextChapterUrl}"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">arrow_forward</span>
          다음 챕터 학습
        </a>` : ''}
        ` : wrongRemaining > 0 ? `
        <a href="/quiz/wrong"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-orange-50 border-2 border-orange-300 hover:border-orange-400 text-orange-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
          <span class="material-symbols-outlined">error_outline</span>
          오답 노트 <span class="bg-orange-500 text-white text-xs font-bold px-2 py-0.5 rounded-full ml-1">${wrongRemaining}</span>
        </a>` : `
        <a href="/quiz"
           class="flex-1 inline-flex items-center justify-center gap-2 bg-white border-2 border-slate-200 hover:border-[#a6eff3] text-slate-700 font-bold px-6 py-3.5 rounded-xl transition-colors">
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

      <!-- 난이도별 정답률 -->
      ${this.buildDifficultyStats()}

      <!-- 취약 챕터 분석 -->
      ${this.buildChapterAnalysis()}

      <!-- 학습 가이드 -->
      ${this.buildReview()}

      <!-- 액션 버튼 -->
      <div class="flex flex-col sm:flex-row gap-3 mt-6">
        ${actionButtons}
      </div>

      <!-- 결과 공유 -->
      <div class="mt-4 flex justify-center">
        <button data-action="click->exam-quiz#shareResult"
                data-pct="${pct}" data-score="${score}" data-total="${total}"
                class="inline-flex items-center gap-2 text-slate-500 hover:text-slate-700 text-sm border border-slate-200 rounded-lg px-4 py-2 hover:bg-slate-50 transition-colors">
          <span class="material-symbols-outlined text-base">open_in_new</span>
          결과 공유하기
        </button>
      </div>
    `
    this.resultAreaTarget.classList.remove("hidden")

    // 60점 이상 시 실기 대비 전환 팝업
    if (pct >= 60 && !this.wrongModeValue && !this.bookmarkModeValue) {
      this.showPracticalTransitionPopup(pct)
    }
  }

  // 실기 대비 전환 팝업 (60점+ 달성 시)
  showPracticalTransitionPopup(pct) {
    const existing = document.getElementById('practical-transition-popup')
    if (existing) return

    const overlay = document.createElement('div')
    overlay.id = 'practical-transition-popup'
    overlay.className = 'fixed inset-0 z-[9998] flex items-end sm:items-center justify-center p-4'
    overlay.style.background = 'rgba(0,0,0,0.5)'
    overlay.innerHTML = `
      <div class="bg-white rounded-2xl shadow-2xl max-w-sm w-full p-6 animate-[slideUp_0.3s_ease]">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-12 h-12 bg-indigo-100 rounded-2xl flex items-center justify-center flex-shrink-0">
            <span class="material-symbols-outlined text-indigo-600 text-2xl">edit_note</span>
          </div>
          <div>
            <div class="font-bold text-slate-800 text-base">${pct}% — 필기 합격권 달성!</div>
            <div class="text-slate-500 text-xs mt-0.5">실기 대비도 지금 시작하세요</div>
          </div>
        </div>
        <p class="text-slate-600 text-sm mb-5 leading-relaxed">
          필기 합격 후 <strong class="text-red-600">단 32일</strong> 안에 실기(필답형)가 있습니다.
          플래시카드 <strong>타이핑 모드</strong>로 지금 바로 실기 대비를 시작하세요.
        </p>
        <div class="flex gap-2">
          <a href="/keywords"
             class="flex-1 inline-flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-4 py-2.5 rounded-xl text-sm transition-colors">
            <span class="material-symbols-outlined text-base">edit_note</span>
            실기 대비 시작
          </a>
          <button onclick="document.getElementById('practical-transition-popup').remove()"
                  class="px-4 py-2.5 text-slate-500 hover:text-slate-700 text-sm font-medium transition-colors rounded-xl hover:bg-slate-50">
            나중에
          </button>
        </div>
      </div>
    `
    document.body.appendChild(overlay)
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove()
    })
  }

  // 챕터별 취약 분석 빌드
  buildChapterAnalysis() {
    const entries = Object.entries(this.wrongByChapter)
    if (entries.length === 0) return ""

    const chapterMap = this.chapterMapValue
    const weakChapters = entries
      .map(([key, wrongCount]) => {
        const total = this.totalByChapter[key] || 1
        const info = chapterMap[key] || {}
        return {
          key,
          wrongCount,
          total,
          pct: Math.round((wrongCount / total) * 100),
          title: info.title || `제${key.split("-")[1]}장`,
          subjectNumber: info.subject_number || `${key.split("-")[0]}권`
        }
      })
      .sort((a, b) => b.pct - a.pct || b.wrongCount - a.wrongCount)
      .slice(0, 5)

    const rows = weakChapters.map(c => {
      const badgeColor = c.pct >= 60
        ? "text-red-700 bg-red-50 border border-red-200"
        : "text-orange-700 bg-orange-50 border border-orange-200"
      const [subId, chapNum] = c.key.split("-")
      const chapterUrl = `/subjects/${subId}/chapters/${chapNum}`
      return `
        <div class="flex items-center justify-between py-2.5 border-b border-slate-100 last:border-0">
          <div class="flex-1 min-w-0">
            <span class="text-xs font-bold text-slate-400 mr-1">${c.subjectNumber}</span>
            <span class="text-sm font-medium text-slate-700">${c.title}</span>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0 ml-3">
            <span class="text-xs text-slate-400">${c.wrongCount}/${c.total}</span>
            <span class="text-xs font-bold ${badgeColor} px-2 py-0.5 rounded-full">${c.pct}% 오답</span>
            <a href="${chapterUrl}"
               class="text-xs font-bold bg-[#00464a] text-white px-2 py-0.5 rounded-full hover:bg-[#005558] transition-colors whitespace-nowrap">
              복습 →
            </a>
          </div>
        </div>`
    }).join("")

    const topChapter = weakChapters[0]
    return `
      <div class="bg-white rounded-2xl shadow-sm border border-orange-200 p-6 mb-6">
        <h3 class="font-bold text-slate-800 mb-1 flex items-center gap-2">
          <span class="material-symbols-outlined text-orange-500">warning</span>
          취약 챕터 분석
        </h3>
        <p class="text-slate-500 text-xs mb-4">
          <strong class="text-orange-600">${topChapter.subjectNumber} ${topChapter.title}</strong>이 가장 취약합니다. 해당 챕터를 집중 복습하세요.
        </p>
        ${rows}
      </div>`
  }

  // 난이도별 정답률 섹션
  buildDifficultyStats() {
    const b = this.diffStats.basic
    const a = this.diffStats.advanced
    if (b.total === 0 && a.total === 0) return ""

    const bPct = b.total > 0 ? Math.round(((b.total - b.wrong) / b.total) * 100) : null
    const aPct = a.total > 0 ? Math.round(((a.total - a.wrong) / a.total) * 100) : null

    const bBar = bPct !== null
      ? `<div class="w-full bg-slate-100 rounded-full h-1.5 mt-1">
           <div class="bg-emerald-400 h-1.5 rounded-full" style="width:${bPct}%"></div>
         </div>`
      : ""
    const aBar = aPct !== null
      ? `<div class="w-full bg-slate-100 rounded-full h-1.5 mt-1">
           <div class="bg-rose-400 h-1.5 rounded-full" style="width:${aPct}%"></div>
         </div>`
      : ""

    return `
      <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 mb-6">
        <h3 class="font-bold text-slate-800 mb-3 flex items-center gap-2 text-sm">
          <span class="material-symbols-outlined text-indigo-500 text-lg">tune</span>
          난이도별 정답률
        </h3>
        <div class="grid grid-cols-2 gap-4">
          ${b.total > 0 ? `
          <div class="bg-emerald-50 rounded-xl p-3">
            <div class="flex items-center gap-1 mb-1">
              <span class="material-symbols-outlined text-emerald-600" style="font-size:14px">star</span>
              <span class="text-xs font-bold text-emerald-700">기초 문제</span>
            </div>
            <div class="text-xl font-extrabold text-emerald-700">${bPct}%</div>
            <div class="text-xs text-emerald-600">${b.total - b.wrong}/${b.total} 정답</div>
            ${bBar}
          </div>` : ""}
          ${a.total > 0 ? `
          <div class="bg-rose-50 rounded-xl p-3">
            <div class="flex items-center gap-1 mb-1">
              <span class="material-symbols-outlined text-rose-600" style="font-size:14px">local_fire_department</span>
              <span class="text-xs font-bold text-rose-700">심화 문제</span>
            </div>
            <div class="text-xl font-extrabold text-rose-700">${aPct}%</div>
            <div class="text-xs text-rose-600">${a.total - a.wrong}/${a.total} 정답</div>
            ${aBar}
          </div>` : ""}
        </div>
      </div>`
  }

  // 학습 가이드 빌드
  buildReview() {
    return `
      <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
        <h3 class="font-bold text-slate-800 mb-4 flex items-center gap-2">
          <span class="material-symbols-outlined text-[#00464a]">checklist</span>
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

  // #7 AI 추가 해설 불러오기
  async fetchAiExplanation(event) {
    const btn = event.currentTarget
    const questionId = btn.dataset.questionId
    const selectedIndex = btn.dataset.selectedIndex
    const area = btn.nextElementSibling

    btn.disabled = true
    btn.innerHTML = '<span class="material-symbols-outlined text-sm animate-spin inline-block">refresh</span> AI 분석 중...'

    try {
      const csrfToken = getCsrfToken()
      const res = await fetch('/quiz/explain', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ question_id: questionId, selected_index: selectedIndex })
      })
      const data = await res.json()
      if (area) {
        area.textContent = data.explanation
        area.classList.remove('hidden')
      }
      btn.classList.add('hidden')
    } catch(e) {
      btn.innerHTML = '<span class="material-symbols-outlined text-sm">error</span> 잠시 후 다시 시도해 주세요'
      btn.disabled = false
    }
  }

  // #10 댓글 HTML 렌더링 헬퍼
  renderComment(c) {
    if (c.pending_review) {
      return `
        <div class="bg-amber-50 border border-amber-200 rounded-lg p-3" data-comment-id="${c.id}">
          <div class="flex items-center gap-2 mb-1">
            <span class="text-xs font-bold text-amber-700">내 댓글</span>
            <span class="text-xs bg-amber-200 text-amber-800 px-2 py-0.5 rounded-full font-semibold">AI 검토 중</span>
          </div>
          <p class="text-sm text-amber-700 break-words opacity-75">${this.escapeHtml(c.body)}</p>
          <p class="text-xs text-amber-500 mt-1">잠시 후 게시되거나 가이드라인 검토 후 숨겨질 수 있습니다.</p>
        </div>`
    }
    const likedKey = `qa_liked_${c.id}`
    const reportedKey = `qa_reported_${c.id}`
    const liked = localStorage.getItem(likedKey) === '1'
    const reported = localStorage.getItem(reportedKey) === '1'
    const deleteBtn = c.mine
      ? `<button onclick="examQuizDeleteComment(${c.id}, this)" class="text-xs text-red-400 hover:text-red-600 transition-colors ml-1">삭제</button>`
      : ''
    const reportBtn = !c.mine && !reported
      ? `<button onclick="examQuizReportComment(${c.id}, this)" class="text-xs text-slate-300 hover:text-orange-400 transition-colors ml-1">신고</button>`
      : ''
    return `
      <div class="bg-white border border-slate-200 rounded-lg p-3" data-comment-id="${c.id}">
        <div class="flex items-start justify-between gap-2">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1 flex-wrap">
              <span class="text-xs font-bold text-slate-700">${this.escapeHtml(c.author)}</span>
              <span class="text-xs text-slate-400">${c.created_at}</span>
            </div>
            <p class="text-sm text-slate-600 break-words">${this.escapeHtml(c.body)}</p>
          </div>
        </div>
        <div class="flex items-center gap-3 mt-2">
          <button onclick="examQuizLikeComment(${c.id}, this)"
                  class="flex items-center gap-1 text-xs ${liked ? 'text-blue-500 font-semibold' : 'text-slate-400 hover:text-blue-500'} transition-colors">
            <span class="material-symbols-outlined text-sm">${liked ? 'thumb_up' : 'thumb_up'}</span>
            <span class="like-count">${c.likes_count}</span>
          </button>
          ${deleteBtn}${reportBtn}
        </div>
      </div>`
  }

  escapeHtml(str) { return escapeHtml(str) }

  // 인라인 토스트 알림 — alert() 대체 (학습 흐름을 끊지 않음)
  showToast(message, type = 'error') {
    const existing = document.getElementById('exam-quiz-toast')
    if (existing) existing.remove()

    const colors = {
      error:   'bg-red-600 text-white',
      success: 'bg-green-600 text-white',
      info:    'bg-blue-600 text-white',
      warning: 'bg-amber-500 text-white'
    }
    const icons = {
      error: 'error', success: 'check_circle', info: 'info', warning: 'warning'
    }

    const toast = document.createElement('div')
    toast.id = 'exam-quiz-toast'
    toast.className = `fixed bottom-6 left-1/2 -translate-x-1/2 z-[9999] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-xl text-sm font-semibold max-w-xs w-max transition-all duration-300 ${colors[type] || colors.error}`
    toast.innerHTML = `
      <span class="material-symbols-outlined text-base flex-shrink-0">${icons[type] || 'error'}</span>
      <span>${this.escapeHtml(message)}</span>
    `
    document.body.appendChild(toast)

    // 3초 후 자동 제거
    setTimeout(() => {
      toast.style.opacity = '0'
      toast.style.transform = 'translateX(-50%) translateY(8px)'
      setTimeout(() => toast.remove(), 300)
    }, 3000)
  }

  // 댓글 로드 헬퍼
  async loadComments(questionId, qaArea) {
    try {
      const res = await fetch(`/questions/${questionId}/comments`, {
        headers: { 'Accept': 'application/json' }
      })
      const comments = await res.json()
      const commentsArea = qaArea.querySelector('.qa-comments')
      if (!commentsArea) return

      if (comments.length === 0) {
        commentsArea.innerHTML = '<p class="text-slate-400 text-xs">아직 댓글이 없습니다. 첫 번째 댓글을 남겨보세요!</p>'
      } else {
        commentsArea.innerHTML = comments.map(c => this.renderComment(c)).join('')
      }
    } catch(e) {
      const commentsArea = qaArea.querySelector('.qa-comments')
      if (commentsArea) commentsArea.innerHTML = '<p class="text-red-400 text-xs">댓글을 불러오지 못했습니다.</p>'
    }
  }

  // #10 Q&A 토글 (댓글은 이미 자동 로드됨)
  toggleQA(event) {
    const btn = event.currentTarget
    const qaArea = btn.nextElementSibling
    if (!qaArea) return

    const isHidden = qaArea.classList.contains('hidden')
    qaArea.classList.toggle('hidden', !isHidden)

    // 아이콘 방향 전환
    const icon = btn.querySelector('.qa-toggle-icon')
    if (icon) icon.textContent = isHidden ? 'expand_less' : 'expand_more'
  }

  // #10 댓글 등록 (AI 모더레이션 포함)
  async submitComment(event) {
    event.preventDefault()
    const form = event.currentTarget
    const questionId = form.querySelector('[name="question_id"]')?.value
    const questionText = form.querySelector('[name="question_text"]')?.value || ''
    const bodyInput = form.querySelector('[name="body"]')
    const submitBtn = form.querySelector('[type="submit"]')
    const body = bodyInput?.value?.trim()
    if (!body || body.length < 5) {
      this.showToast('5자 이상 입력해 주세요.', 'warning')
      bodyInput?.focus()
      return
    }

    if (submitBtn) { submitBtn.disabled = true; submitBtn.textContent = 'AI 검토 중...' }

    try {
      const csrfToken = getCsrfToken()
      const res = await fetch(`/questions/${questionId}/comments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
        body: JSON.stringify({ body, question_text: questionText })
      })
      const data = await res.json()

      if (data.login_required) {
        this.showToast('댓글 작성은 로그인이 필요합니다.', 'info')
        return
      }
      if (data.error) {
        this.showToast(data.error, 'error')
        return
      }

      // 새 댓글 추가
      const commentsArea = form.closest('.qa-area')?.querySelector('.qa-comments')
      if (commentsArea) {
        commentsArea.querySelector('p.text-slate-400')?.remove()
        const el = document.createElement('div')
        el.innerHTML = this.renderComment(data)
        commentsArea.prepend(el.firstElementChild)
      }
      if (bodyInput) bodyInput.value = ''
    } catch(e) {
      this.showToast('잠시 후 다시 시도해 주세요.', 'error')
    } finally {
      if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = '등록' }
    }
  }

  // 오류 신고 토글
  toggleReport(event) {
    const btn = event.currentTarget
    const area = btn.nextElementSibling
    if (area) area.classList.toggle('hidden')
  }

  // 오류 신고 닫기
  closeReport(event) {
    const area = event.currentTarget.closest('.report-area')
    if (area) area.classList.add('hidden')
  }

  // 오류 신고 제출
  async submitReport(event) {
    const btn = event.currentTarget
    const questionId = btn.dataset.questionId
    const area = btn.closest('.report-area')
    const body = area?.querySelector('.report-body')?.value?.trim()
    if (!body || body.length < 5) { this.showToast('오류 내용을 5자 이상 설명해 주세요.', 'warning'); return }
    try {
      const csrfToken = getCsrfToken()
      const res = await fetch(`/questions/${questionId}/reports`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
        body: JSON.stringify({ body })
      })
      const data = await res.json()
      if (data.success) {
        if (area) area.innerHTML = '<p class="text-xs text-orange-700 font-semibold py-1">✓ 제보해 주셔서 감사합니다!</p>'
      } else {
        this.showToast(data.error || '제보에 실패했습니다. 잠시 후 다시 시도해 주세요.', 'error')
      }
    } catch(e) { this.showToast('잠시 후 다시 시도해 주세요.', 'error') }
  }

  // 결과 공유
  async shareResult(event) {
    const btn = event.currentTarget
    const pct = btn.dataset.pct
    const score = btn.dataset.score
    const total = btn.dataset.total
    const text = `공공조달관리사 모의고사에서 ${pct}% 달성했어요! (${score}/${total}문제) 함께 준비해요 🏆`
    const url = 'https://exam.silmu.kr'

    if (navigator.share) {
      try {
        await navigator.share({ title: '공공조달관리사 모의고사 결과', text, url })
      } catch(e) {}
    } else {
      // 클립보드 복사 fallback
      try {
        await navigator.clipboard.writeText(`${text}\n${url}`)
        btn.innerHTML = '<span class="material-symbols-outlined text-base text-green-500">check_circle</span> 복사됨!'
        setTimeout(() => {
          btn.innerHTML = '<span class="material-symbols-outlined text-base">open_in_new</span> 결과 공유하기'
        }, 2000)
      } catch(e) {
        // 수동 트위터 공유
        window.open(`https://twitter.com/intent/tweet?text=${encodeURIComponent(text + '\n' + url)}`, '_blank')
      }
    }
  }

  // 다시 풀기
  retryQuiz() {
    this.currentValue = 0
    this.scoreValue = 0
    this.answeredValue = false
    this.wrongByChapter = {}
    this.totalByChapter = {}
    this.diffStats = { basic: { total: 0, wrong: 0 }, advanced: { total: 0, wrong: 0 } }
    this.scoreDisplayTarget.textContent = "0"
    this.resultAreaTarget.classList.add("hidden")
    this.questionAreaTarget.classList.remove("hidden")
    this.showQuestion()
  }

  // nav 스트릭 배지 즉시 갱신
  _updateNavStreakBadge() {
    try {
      const streak = JSON.parse(localStorage.getItem('exam_streak')) || {}
      const badge = document.getElementById('nav-streak-badge')
      const countEl = document.getElementById('nav-streak-count')
      if (badge && countEl && streak.count > 0) {
        countEl.textContent = streak.count
        badge.classList.remove('hidden')
      }
    } catch { /* 무시 */ }
  }
}
