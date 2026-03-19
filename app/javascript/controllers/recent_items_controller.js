import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "silmu_recent_items"
const MAX_ITEMS = 6

export default class extends Controller {
  static targets = ["list", "container"]

  connect() {
    this.render()
  }

  // 현재 페이지를 최근 항목에 기록 (topics/show, tools에서 호출)
  record({ params: { title, url, type } }) {
    const items = this.getItems()
    const newItem = { title, url, type, visitedAt: Date.now() }
    const filtered = items.filter(i => i.url !== url)
    const updated = [newItem, ...filtered].slice(0, MAX_ITEMS)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated))
  }

  render() {
    const items = this.getItems()
    if (!this.hasContainerTarget) return

    if (items.length === 0) {
      this.containerTarget.style.display = "none"
      return
    }

    this.containerTarget.style.display = ""
    if (this.hasListTarget) {
      this.listTarget.innerHTML = items.map(item => `
        <a href="${item.url}" class="flex items-center gap-2.5 p-3 rounded-xl hover:bg-surface-100 transition-colors group">
          <span class="material-symbols-outlined text-slate-400 group-hover:text-indigo-500 shrink-0" style="font-size:18px">
            ${item.type === 'tool' ? 'construction' : item.type === 'guide' ? 'menu_book' : 'gavel'}
          </span>
          <span class="text-sm text-slate-700 group-hover:text-slate-900 truncate">${item.title}</span>
        </a>
      `).join("")
    }
  }

  getItems() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]")
    } catch {
      return []
    }
  }
}
