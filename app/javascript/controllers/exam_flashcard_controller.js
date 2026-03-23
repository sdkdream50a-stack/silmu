// exam.silmu.kr — 용어집 플래시카드 모드 Stimulus 컨트롤러
import { Controller } from "@hotwired/stimulus"
import { escapeHtml } from "../exam_utils"

const DONE_KEY = 'exam_flashcard_done'

function loadDone() {
  try { return JSON.parse(localStorage.getItem(DONE_KEY)) || [] } catch { return [] }
}

function saveDone(keyword) {
  const done = loadDone()
  if (!done.includes(keyword)) {
    done.push(keyword)
    try { localStorage.setItem(DONE_KEY, JSON.stringify(done)) } catch {}
  }
}

export default class extends Controller {
  static values = { cards: Array }
  static targets = [
    "overlay", "front", "back", "card",
    "progress", "learnedCount", "remainCount",
    "result", "flipHint"
  ]

  // 3대 핵심 법령 slug 키워드 필터 (국가계약법·시행령·조달사업법 관련)
  static CORE_LAW_KEYWORDS = [
    '국가계약법', '국계법', '시행령', '조달사업법', '지방계약법',
    '입찰', '낙찰', '계약보증금', '이행보증금', '지체상금',
    '수의계약', '다수공급자', '단가계약', '장기계속계약', '예정가격',
    '적격심사', '원가계산', '협상에 의한 계약', '설계변경', '물가변동'
  ]

  connect() {
    // 초기 상태 — 오버레이 숨김
    this.typingMode = false
  }

  disconnect() {
    this.close()
  }

  // 3대 법령 필수 덱 시작
  startMandatoryDeck() {
    const coreKeywords = this.constructor.CORE_LAW_KEYWORDS
    const filtered = this.cardsValue.filter(card =>
      coreKeywords.some(kw => (card.keyword || '').includes(kw) || (card.definition || '').includes(kw))
    )
    if (filtered.length === 0) {
      this.start()  // 필터 결과 없으면 전체로 대체
      return
    }
    this.typingMode = false
    this._startWithCards(filtered)
  }

  // 타이핑 모드 시작 (실기 대비)
  startTyping() {
    const all = this.cardsValue.filter(c => c.definition)
    if (all.length === 0) return
    this.typingMode = true
    this._startWithCards(all)
  }

  // 플래시카드 모드 시작
  start() {
    this.typingMode = false
    this._startWithCards(this.cardsValue)
  }

  // 내부 시작 헬퍼
  _startWithCards(cards) {
    const all = cards
    if (all.length === 0) return
    this.queue = [...all]
    this.learned = 0
    this.total = all.length
    this.flipped = false

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
      // 스크롤 방지
      document.body.style.overflow = "hidden"
    }
    this.showFront()

    // 키보드 단축키 등록
    this._fcKeyHandler = this._handleFlashcardKey.bind(this)
    document.addEventListener('keydown', this._fcKeyHandler)

    // 터치 이벤트 등록
    const cardArea = this.element.querySelector('[data-card-area]')
    if (cardArea) {
      this._touchStartX = 0
      this._touchStartY = 0
      this._touchHandler = (e) => {
        this._touchStartX = e.touches[0].clientX
        this._touchStartY = e.touches[0].clientY
      }
      this._touchEndHandler = (e) => {
        const dx = e.changedTouches[0].clientX - this._touchStartX
        const dy = e.changedTouches[0].clientY - this._touchStartY
        if (Math.abs(dy) > Math.abs(dx)) return  // 수직 스와이프 무시
        if (Math.abs(dx) < 30) { this.flip(); return }  // 탭 → flip
        if (dx > 50) this.knew()
        else if (dx < -50) this.didntKnow()
      }
      cardArea.addEventListener('touchstart', this._touchHandler, { passive: true })
      cardArea.addEventListener('touchend', this._touchEndHandler, { passive: true })
      this._cardArea = cardArea
    }
  }

  // 닫기
  close() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }

    // 키보드 단축키 해제
    if (this._fcKeyHandler) {
      document.removeEventListener('keydown', this._fcKeyHandler)
      this._fcKeyHandler = null
    }

    // 터치 이벤트 해제
    if (this._cardArea) {
      this._cardArea.removeEventListener('touchstart', this._touchHandler)
      this._cardArea.removeEventListener('touchend', this._touchEndHandler)
      this._cardArea = null
    }
  }

  // 키보드 단축키 핸들러
  _handleFlashcardKey(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return
    if (e.key === ' ' || e.key === 'Enter') {
      e.preventDefault()
      this.flip()
    } else if (e.key === 'ArrowRight') {
      e.preventDefault()
      this.knew()
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault()
      this.didntKnow()
    } else if (e.key === 'Escape') {
      this.close()
    }
  }

  // 카드 앞면 표시
  showFront() {
    if (this.queue.length === 0) {
      this.showResult()
      return
    }
    this.flipped = false
    const card = this.queue[0]

    if (this.hasCardTarget) {
      this.cardTarget.style.transform = "rotateY(0deg)"
    }

    if (this.typingMode) {
      // 타이핑 모드: 앞면에 용어 + 입력란
      if (this.hasFrontTarget) {
        this.frontTarget.innerHTML = `
          <div class="w-full">
            <div class="text-xs text-indigo-500 mb-2 font-semibold tracking-wide uppercase text-center">실기 대비 — 정의를 입력하세요</div>
            <div class="text-xl font-bold text-slate-900 leading-snug text-center mb-4">${this.escapeHtml(card.keyword)}</div>
            <div class="text-xs text-slate-400 text-center mb-3">${this.escapeHtml(card.chapter_title || '')}</div>
            <textarea id="fc-typing-input"
                      class="w-full border-2 border-slate-200 rounded-xl px-4 py-3 text-sm text-slate-700 focus:outline-none focus:border-indigo-400 resize-none"
                      rows="3" placeholder="정의를 직접 입력해보세요..."></textarea>
            <button onclick="this.closest('[data-controller]')?.['exam-flashcard']?.checkTyping?.()"
                    data-action="click->exam-flashcard#checkTyping"
                    class="mt-3 w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2.5 rounded-xl text-sm transition-colors">
              채점하기
            </button>
          </div>
        `
      }
      if (this.hasBackTarget) {
        this.backTarget.innerHTML = ''
      }
    } else {
      // 일반 플립 모드
      if (this.hasFrontTarget) {
        this.frontTarget.innerHTML = `
          <div class="text-center">
            <div class="text-xs text-slate-400 mb-3 font-semibold tracking-wide uppercase">용어</div>
            <div class="text-2xl font-bold text-slate-900 leading-snug">${this.escapeHtml(card.keyword)}</div>
            <div class="text-xs text-slate-400 mt-3">${this.escapeHtml(card.chapter_title || '')}</div>
          </div>
        `
      }
      if (this.hasBackTarget) {
        this.backTarget.innerHTML = `
          <div>
            <div class="text-xs text-slate-400 mb-2 font-semibold tracking-wide uppercase">정의</div>
            <p class="text-slate-800 text-base leading-relaxed mb-4">${this.escapeHtml(card.definition || '')}</p>
            <div class="text-xs text-slate-400 mb-1 font-semibold">실무 예시</div>
            <p class="text-slate-600 text-sm italic leading-relaxed bg-blue-50 rounded-lg px-3 py-2 border-l-2 border-blue-300">"${this.escapeHtml(card.example || '')}"</p>
          </div>
        `
      }
    }
    this.updateProgress()
  }

  // 타이핑 채점
  checkTyping() {
    const card = this.queue[0]
    if (!card) return
    const input = this.hasFrontTarget && this.frontTarget.querySelector('#fc-typing-input')
    if (!input) return
    const userAnswer = input.value.trim()
    if (!userAnswer) { input.focus(); return }

    const definition = (card.definition || '').trim()
    // 간단 채점: 정의의 핵심 명사(3글자 이상)가 몇 개 포함됐는지
    const keywords = definition.split(/[\s,·\.\(\)]+/).filter(w => w.length >= 3)
    const matchCount = keywords.filter(kw => userAnswer.includes(kw)).length
    const score = keywords.length > 0 ? Math.round((matchCount / keywords.length) * 100) : 0

    if (this.hasFrontTarget) {
      const scoreColor = score >= 60 ? 'text-green-600' : score >= 30 ? 'text-amber-600' : 'text-red-600'
      const scoreLabel = score >= 60 ? '잘 썼어요!' : score >= 30 ? '부분 일치' : '다시 봐요'
      this.frontTarget.innerHTML += `
        <div class="mt-4 p-4 bg-white rounded-xl border-2 ${score >= 60 ? 'border-green-300' : 'border-amber-300'}">
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-bold ${scoreColor}">${scoreLabel} (${score}%)</span>
          </div>
          <div class="text-xs text-slate-500 mb-1 font-semibold">정답 정의</div>
          <p class="text-sm text-slate-700 leading-relaxed">${this.escapeHtml(definition)}</p>
          <div class="flex gap-2 mt-3">
            <button data-action="click->exam-flashcard#knew"
                    class="flex-1 bg-green-500 text-white text-sm font-bold py-2 rounded-lg hover:bg-green-600 transition-colors">알았어</button>
            <button data-action="click->exam-flashcard#didntKnow"
                    class="flex-1 bg-red-500 text-white text-sm font-bold py-2 rounded-lg hover:bg-red-600 transition-colors">다시</button>
          </div>
        </div>
      `
      // 채점 후 채점 버튼 제거
      const checkBtn = this.frontTarget.querySelector('[data-action="click->exam-flashcard#checkTyping"]')
      if (checkBtn) checkBtn.remove()
      if (input) input.disabled = true
    }
  }

  // 카드 뒤집기 (타이핑 모드에서는 비활성)
  flip() {
    if (this.typingMode) return
    if (this.flipped) return
    this.flipped = true
    if (this.hasCardTarget) {
      this.cardTarget.style.transform = "rotateY(180deg)"
    }
    if (this.hasFlipHintTarget) {
      this.flipHintTarget.classList.add("hidden")
    }
  }

  // 알았어 — 큐에서 제거
  knew() {
    if (!this.typingMode && !this.flipped) { this.flip(); return }
    const card = this.queue.shift()
    saveDone(card.keyword)
    this.learned++
    this.showFront()
  }

  // 몰랐어 — 큐 끝에 다시 추가
  didntKnow() {
    if (!this.typingMode && !this.flipped) { this.flip(); return }
    const card = this.queue.shift()
    this.queue.push(card)
    this.showFront()
  }

  // 완주 화면 — 성취 축하 오버레이
  showResult() {
    if (this.hasCardTarget) {
      this.cardTarget.closest('[data-card-area]')?.classList.add("hidden")
    }
    if (this.hasResultTarget) {
      this.resultTarget.classList.remove("hidden")
      const learnedPct = this.total > 0 ? Math.round((this.learned / this.total) * 100) : 100
      const perfectRun = learnedPct >= 90
      this.resultTarget.innerHTML = `
        <div class="exam-celebration-card text-center py-10 px-6">
          <!-- 이모지 성취 배지 -->
          <div class="relative inline-flex items-center justify-center mb-5">
            <div class="w-24 h-24 rounded-full flex items-center justify-center
                        ${perfectRun ? 'bg-yellow-400/30' : 'bg-indigo-400/20'}">
              <span class="material-symbols-outlined text-5xl ${perfectRun ? 'text-yellow-300' : 'text-indigo-300'}">
                ${perfectRun ? 'emoji_events' : 'workspace_premium'}
              </span>
            </div>
          </div>

          <!-- 성취 메시지 -->
          <div class="text-3xl font-bold text-white mb-2">
            ${perfectRun ? '완벽 완주!' : '완주!'}
          </div>
          <p class="text-white/70 text-sm mb-1">
            총 <strong class="text-white">${this.total}개</strong> 용어를 모두 학습했습니다.
          </p>
          ${perfectRun
            ? '<p class="text-yellow-300 text-xs font-semibold mb-6">90% 이상 알고 있어요. 정말 잘했습니다!</p>'
            : `<p class="text-white/50 text-xs mb-6">${learnedPct}% 습득 — 모르는 카드를 다시 복습해보세요.</p>`
          }

          <!-- 다음 행동 버튼 -->
          <div class="flex flex-col gap-3">
            <button data-action="click->exam-flashcard#restart"
                    class="inline-flex items-center justify-center gap-2 bg-indigo-500 hover:bg-indigo-400
                           text-white font-bold px-8 py-3.5 rounded-xl transition-all duration-200
                           hover:-translate-y-0.5 hover:shadow-lg">
              <span class="material-symbols-outlined">refresh</span>
              다시 하기
            </button>
            <a href="/quiz" class="inline-flex items-center justify-center gap-2
                                   bg-white/10 hover:bg-white/20 text-white/80 hover:text-white
                                   font-semibold px-8 py-3 rounded-xl transition-colors text-sm">
              <span class="material-symbols-outlined text-base">quiz</span>
              모의고사로 확인하기
            </a>
          </div>
        </div>
      `
    }
  }

  // 다시 하기 (현재 모드 유지)
  restart() {
    const wasTypingMode = this.typingMode
    this._startWithCards(this.queue.length > 0 ? [...this.queue, ...Array.from({length: this.learned})] : this.cardsValue)
    this.typingMode = wasTypingMode
    if (this.hasResultTarget) {
      this.resultTarget.classList.add("hidden")
    }
    const cardArea = this.hasCardTarget && this.cardTarget.closest('[data-card-area]')
    if (cardArea) cardArea.classList.remove("hidden")
    this.showFront()
  }

  // 진도 업데이트 (진행바 트랜지션은 CSS .exam-progress-bar transition으로 처리)
  updateProgress() {
    const remaining = this.queue.length
    if (this.hasLearnedCountTarget) this.learnedCountTarget.textContent = this.learned
    if (this.hasRemainCountTarget) this.remainCountTarget.textContent = remaining
    if (this.hasProgressTarget) {
      const pct = this.total > 0 ? Math.round((this.learned / this.total) * 100) : 0
      this.progressTarget.style.width = `${pct}%`
    }
    if (this.hasFlipHintTarget) {
      this.flipHintTarget.classList.toggle("hidden", this.typingMode)
    }
  }

  escapeHtml(str) { return escapeHtml(str) }
}
