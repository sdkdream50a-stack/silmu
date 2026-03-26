// 가이드 인라인 플래시카드 (exam 전체화면 버전의 경량 인라인 버전)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { cards: Array }
  static targets = ["front", "back", "card", "progress", "counter", "result"]

  connect() {
    this.idx = 0
    this.score = 0
    this.show()
  }

  show() {
    const card = this.cardsValue[this.idx]
    if (!card) return
    this.frontTarget.textContent = card.front
    this.backTarget.textContent = card.back
    this.cardTarget.style.transform = "rotateY(0deg)"
    this.flipped = false
    if (this.hasCounterTarget)
      this.counterTarget.textContent = `${this.idx + 1} / ${this.cardsValue.length}`
    if (this.hasProgressTarget)
      this.progressTarget.style.width = `${(this.idx / this.cardsValue.length) * 100}%`
  }

  flip() {
    if (this.flipped) return
    this.flipped = true
    this.cardTarget.style.transform = "rotateY(180deg)"
  }

  knew() {
    if (!this.flipped) { this.flip(); return }
    this.score++
    this.next()
  }

  again() {
    if (!this.flipped) { this.flip(); return }
    this.next()
  }

  next() {
    this.idx++
    if (this.idx >= this.cardsValue.length) {
      this.showResult()
    } else {
      this.show()
    }
  }

  showResult() {
    const pct = Math.round((this.score / this.cardsValue.length) * 100)
    if (this.hasResultTarget) {
      this.resultTarget.classList.remove("hidden")
      this.resultTarget.querySelector("[data-score]").textContent = `${pct}%`
      this.resultTarget.querySelector("[data-count]").textContent =
        `${this.score}/${this.cardsValue.length}`
    }
    this.cardTarget.closest("[data-card-area]")?.classList.add("hidden")
  }

  restart() {
    this.idx = 0
    this.score = 0
    this.cardTarget.closest("[data-card-area]")?.classList.remove("hidden")
    if (this.hasResultTarget) this.resultTarget.classList.add("hidden")
    this.show()
  }
}
