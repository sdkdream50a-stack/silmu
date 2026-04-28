import { Controller } from "@hotwired/stimulus"

// Sprint #2-C — 토픽 행동 이벤트 3종 추적 (Krug + Editorial Ops 권위자 검증)
//
// 측정:
// - scroll_depth: 25/50/75/100% 도달 시 (한 번씩만 보고)
// - time_on_page: 15/30/60/120초 도달 시
// - faq_open: details/summary 클릭 시 인덱스 기록
//
// 전송: 페이지 떠날 때 sendBeacon 으로 batch POST. 1요청에 최대 20건.
export default class extends Controller {
  static values = {
    topicSlug: String
  }

  connect() {
    if (!this.topicSlugValue) return

    this.events = []
    this.scrollMarks = new Set()
    this.timeMarks = new Set()
    this.startTime = Date.now()

    // 1. Scroll depth
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.scrollHandler, { passive: true })

    // 2. Time on page (interval 마크)
    this.timeIntervals = [15, 30, 60, 120]
    this.timeTimer = setInterval(() => this.handleTime(), 5000)

    // 3. FAQ open (details/summary)
    this.faqHandler = this.handleFaqOpen.bind(this)
    document.querySelectorAll("details").forEach((d, i) => {
      d.addEventListener("toggle", (e) => this.handleFaqOpen(e, i))
    })

    // 페이지 떠날 때 beacon 전송
    this.beaconHandler = this.flush.bind(this)
    window.addEventListener("pagehide", this.beaconHandler)
    window.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden") this.flush()
    })
  }

  disconnect() {
    window.removeEventListener("scroll", this.scrollHandler)
    window.removeEventListener("pagehide", this.beaconHandler)
    if (this.timeTimer) clearInterval(this.timeTimer)
  }

  handleScroll() {
    const scrolled = window.scrollY + window.innerHeight
    const total = document.documentElement.scrollHeight
    if (total <= window.innerHeight) return
    const pct = Math.round((scrolled / total) * 100)

    ;[25, 50, 75, 100].forEach((mark) => {
      if (pct >= mark && !this.scrollMarks.has(mark)) {
        this.scrollMarks.add(mark)
        this.queue("scroll_depth", mark)
      }
    })
  }

  handleTime() {
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000)
    this.timeIntervals.forEach((mark) => {
      if (elapsed >= mark && !this.timeMarks.has(mark)) {
        this.timeMarks.add(mark)
        this.queue("time_on_page", mark)
      }
    })
  }

  handleFaqOpen(event, index) {
    if (event.target.open) {
      this.queue("faq_open", index)
    }
  }

  queue(type, value) {
    this.events.push({
      topic_slug: this.topicSlugValue,
      event_type: type,
      event_value: value
    })
    // 최대 20건까지만 (batch 한도)
    if (this.events.length >= 20) this.flush()
  }

  flush() {
    if (this.events.length === 0) return
    const payload = JSON.stringify({ events: this.events })
    this.events = []

    // navigator.sendBeacon 우선 (페이지 떠날 때 안전)
    if (navigator.sendBeacon) {
      const blob = new Blob([payload], { type: "application/json" })
      navigator.sendBeacon("/topic_events", blob)
    } else {
      fetch("/topic_events", {
        method: "POST",
        keepalive: true,
        headers: { "Content-Type": "application/json" },
        body: payload
      }).catch(() => {})
    }
  }
}
