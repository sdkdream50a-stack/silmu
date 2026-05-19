// AI 실무 어시스턴트 Stimulus 컨트롤러
// ActionCable을 통해 AI 답변을 실시간 수신
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

export default class extends Controller {
  static targets = ["messages", "input", "submit", "loading", "remaining"]
  static values  = { topicSlug: String, sessionId: String }

  connect() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "AiAssistantChannel",
        session_id: this.sessionIdValue
      },
      {
        received: (data) => this.handleReceived(data)
      }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  send() {
    const question = this.inputTarget.value.trim()
    if (!question) return

    // 사용자 메시지 추가
    this.appendMessage("user", question)
    this.inputTarget.value = ""
    this.setLoading(true)

    this.subscription.perform("ask", {
      question: question,
      topic_slug: this.topicSlugValue
    })
  }

  setQuestion(event) {
    this.inputTarget.value = event.params.question
    this.inputTarget.focus()
  }

  handleReceived(data) {
    this.setLoading(false)

    if (data.type === "error") {
      this.appendMessage("error", data.message)
    } else if (data.type === "answer") {
      this.appendMessage("assistant", data.text, {
        complianceRate: data.term_compliance_rate,
        changesCount:   data.term_changes_count
      })
      if (data.remaining !== null && data.remaining !== undefined) {
        this.remainingTarget.textContent = `오늘 남은 질문 횟수: ${data.remaining}회`
      }
    }
  }

  appendMessage(role, text, meta = {}) {
    const wrapper = document.createElement("div")
    wrapper.className = "flex gap-3"

    if (role === "user") {
      wrapper.innerHTML = `
        <div class="flex-1"></div>
        <div class="bg-slate-100 rounded-2xl rounded-tr-none px-4 py-3 max-w-prose">
          <p class="text-sm text-slate-700">${this.escapeHtml(text)}</p>
        </div>
        <div class="w-8 h-8 rounded-full bg-slate-300 flex items-center justify-center flex-shrink-0">
          <span class="material-symbols-outlined text-slate-600 text-base">person</span>
        </div>
      `
    } else if (role === "assistant") {
      const badge = this.termBadgeHtml(meta.complianceRate, meta.changesCount)
      wrapper.innerHTML = `
        <div class="w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center flex-shrink-0">
          <span class="material-symbols-outlined text-white text-base">psychology</span>
        </div>
        <div class="bg-indigo-50 rounded-2xl rounded-tl-none px-4 py-3 max-w-prose flex-1">
          <div class="text-sm text-slate-700 prose prose-sm max-w-none">${this.simpleMarkdown(text)}</div>
          ${badge}
        </div>
      `
    } else {
      // error
      wrapper.innerHTML = `
        <div class="w-8 h-8 rounded-full bg-red-500 flex items-center justify-center flex-shrink-0">
          <span class="material-symbols-outlined text-white text-base">error</span>
        </div>
        <div class="bg-red-50 border border-red-100 rounded-2xl rounded-tl-none px-4 py-3 max-w-prose">
          <p class="text-sm text-red-700">${this.escapeHtml(text)}</p>
        </div>
      `
    }

    this.messagesTarget.appendChild(wrapper)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  setLoading(on) {
    this.loadingTarget.classList.toggle("hidden", !on)
    this.submitTarget.disabled = on
    if (on) this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/\n/g, "<br>")
  }

  // P3 Sprint 2 — 공통표준용어 후처리 배지
  termBadgeHtml(rate, count) {
    if (typeof rate !== "number") return ""
    const pct = Math.round(rate * 1000) / 10
    if (count > 0) {
      return `<div class="mt-2 inline-flex items-center gap-1 px-2 py-1 rounded text-xs bg-amber-50 border border-amber-200 text-amber-800">
        <span class="material-symbols-outlined" style="font-size:14px;">auto_fix_high</span>
        표준어 자동 교정 ${count}건 (준수율 ${pct}%)
      </div>`
    }
    return `<div class="mt-2 inline-flex items-center gap-1 px-2 py-1 rounded text-xs bg-emerald-50 border border-emerald-200 text-emerald-700">
      <span class="material-symbols-outlined" style="font-size:14px;">check_circle</span>
      표준어 준수율 100%
    </div>`
  }

  // 기본 마크다운(볼드, 코드블록, 줄바꿈) 처리
  simpleMarkdown(text) {
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/`(.+?)`/g, "<code class='bg-slate-200 px-1 rounded text-xs'>$1</code>")
      .replace(/\n/g, "<br>")
  }
}
