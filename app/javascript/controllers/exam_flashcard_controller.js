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

  connect() {
    // 초기 상태 — 오버레이 숨김
  }

  disconnect() {
    this.close()
  }

  // 플래시카드 모드 시작
  start() {
    const all = this.cardsValue
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
    this.updateProgress()
  }

  // 카드 뒤집기
  flip() {
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
    if (!this.flipped) { this.flip(); return }
    const card = this.queue.shift()
    saveDone(card.keyword)
    this.learned++
    this.showFront()
  }

  // 몰랐어 — 큐 끝에 다시 추가
  didntKnow() {
    if (!this.flipped) { this.flip(); return }
    const card = this.queue.shift()
    this.queue.push(card)
    this.showFront()
  }

  // 완주 화면
  showResult() {
    if (this.hasCardTarget) {
      this.cardTarget.closest('[data-card-area]')?.classList.add("hidden")
    }
    if (this.hasResultTarget) {
      this.resultTarget.classList.remove("hidden")
      this.resultTarget.innerHTML = `
        <div class="text-center py-8">
          <div class="w-20 h-20 bg-yellow-400/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <span class="material-symbols-outlined text-yellow-300 text-4xl">workspace_premium</span>
          </div>
          <div class="text-2xl font-bold text-white mb-2">완주!</div>
          <p class="text-white/70 text-sm mb-6">총 ${this.total}개 용어를 모두 학습했습니다.</p>
          <button data-action="click->exam-flashcard#restart"
                  class="inline-flex items-center gap-2 bg-indigo-500 text-white font-bold px-6 py-3 rounded-xl hover:bg-indigo-400 transition-colors">
            <span class="material-symbols-outlined">refresh</span>
            다시 하기
          </button>
        </div>
      `
    }
  }

  // 다시 하기
  restart() {
    this.start()
    if (this.hasResultTarget) {
      this.resultTarget.classList.add("hidden")
    }
    const cardArea = this.hasCardTarget && this.cardTarget.closest('[data-card-area]')
    if (cardArea) cardArea.classList.remove("hidden")
  }

  // 진도 업데이트
  updateProgress() {
    const remaining = this.queue.length
    if (this.hasLearnedCountTarget) this.learnedCountTarget.textContent = this.learned
    if (this.hasRemainCountTarget) this.remainCountTarget.textContent = remaining
    if (this.hasProgressTarget) {
      const pct = this.total > 0 ? Math.round((this.learned / this.total) * 100) : 0
      this.progressTarget.style.width = `${pct}%`
    }
    if (this.hasFlipHintTarget) {
      this.flipHintTarget.classList.remove("hidden")
    }
  }

  escapeHtml(str) { return escapeHtml(str) }
}
