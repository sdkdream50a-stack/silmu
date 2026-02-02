import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  show(event) {
    const selectedTab = event.currentTarget.dataset.tab

    // 탭 스타일 업데이트
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === selectedTab) {
        tab.classList.remove("text-gray-500", "hover:text-gray-700")
        tab.classList.add("text-indigo-600", "border-b-2", "border-indigo-600")
      } else {
        tab.classList.remove("text-indigo-600", "border-b-2", "border-indigo-600")
        tab.classList.add("text-gray-500", "hover:text-gray-700")
      }
    })

    // 패널 표시/숨김
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tab === selectedTab) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
