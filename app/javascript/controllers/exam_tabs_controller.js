import { Controller } from "@hotwired/stimulus"

// 챕터 학습 탭 컨트롤러
// 이론 요약 | 핵심 암기 | 문제 풀기 3단계 탭 전환
export default class extends Controller {
  static targets = ["tab", "panel", "tabLabel"]
  static values = { chapterId: String, active: { type: String, default: "theory" } }

  connect() {
    const saved = localStorage.getItem(`chapter-tab-${this.chapterIdValue}`)
    if (saved && ["theory", "memory", "practice"].includes(saved)) {
      this.activeValue = saved
    }
    this.showTab(this.activeValue)
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    if (!tab) return
    this.activeValue = tab
    localStorage.setItem(`chapter-tab-${this.chapterIdValue}`, tab)
    this.showTab(tab)
    // 탭 영역 상단으로 스크롤
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  showTab(name) {
    this.tabTargets.forEach(t => {
      const active = t.dataset.tab === name
      t.classList.toggle("tab-active", active)
      t.classList.toggle("tab-inactive", !active)
    })
    this.panelTargets.forEach(p => {
      p.classList.toggle("hidden", p.dataset.panel !== name)
    })
  }
}
