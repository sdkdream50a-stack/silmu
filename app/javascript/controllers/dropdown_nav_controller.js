// 네비게이션 드롭다운 Stimulus 컨트롤러
// 데스크탑: hover(200ms 딜레이), 모바일: click toggle
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "chevron"]

  connect() {
    this._closeTimer = null
    this._openKey = null

    // Turbo 캐시 저장 직전 모든 드롭다운 닫기
    this._beforeCacheHandler = () => this._closeAll()
    document.addEventListener("turbo:before-cache", this._beforeCacheHandler)
  }

  disconnect() {
    clearTimeout(this._closeTimer)
    document.removeEventListener("turbo:before-cache", this._beforeCacheHandler)
  }

  // 트리거 영역 마우스 진입 — 200ms 후 열기
  hoverOpen(event) {
    const key = event.currentTarget.dataset.dropdownKey
    clearTimeout(this._closeTimer)
    if (this._openKey !== key) {
      this._closeAll()
      this._open(key)
    }
  }

  // 트리거/패널 영역 마우스 이탈 — 150ms 후 닫기
  hoverClose() {
    this._closeTimer = setTimeout(() => this._closeAll(), 150)
  }

  // 패널 영역 마우스 재진입 — 닫기 취소
  panelEnter() {
    clearTimeout(this._closeTimer)
  }

  // 모바일/클릭 토글
  toggle(event) {
    const key = event.currentTarget.dataset.dropdownKey
    if (this._openKey === key) {
      this._closeAll()
    } else {
      this._closeAll()
      this._open(key)
    }
  }

  // Esc 키로 닫기
  handleKeydown(event) {
    if (event.key === "Escape") this._closeAll()
  }

  // --- private ---

  _open(key) {
    this._openKey = key
    this.panelTargets.forEach(panel => {
      const isTarget = panel.dataset.dropdownKey === key
      panel.classList.toggle("hidden", !isTarget)
      panel.setAttribute("aria-hidden", String(!isTarget))
    })
    this.chevronTargets.forEach(ch => {
      ch.classList.toggle("rotate-180", ch.dataset.dropdownKey === key)
    })
  }

  _closeAll() {
    this._openKey = null
    clearTimeout(this._closeTimer)
    this.panelTargets.forEach(panel => {
      panel.classList.add("hidden")
      panel.setAttribute("aria-hidden", "true")
    })
    this.chevronTargets.forEach(ch => ch.classList.remove("rotate-180"))
  }
}
