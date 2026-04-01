// 도구 페이지 필터·뷰전환·검색 Stimulus 컨트롤러
// 기존 인라인 filterTools() 대체
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "tab", "domainTab", "searchInput", "gridContainer", "gridBtn", "listBtn", "listContainer", "countBadge"]

  connect() {
    this.activeCategory = "전체"
    this.activeDomain = "전체"
    this.currentView = localStorage.getItem("silmu_tools_view") || "grid"

    this._applyView(this.currentView, false)
    this._restoreFromHash()
  }

  disconnect() {
    // Turbo 캐시 복원 시 상태 초기화 — 모든 카드 표시, 탭 전체 선택
    this.cardTargets.forEach(card => card.style.display = "")
  }

  // 유형 탭 (자동화/계산기/문서/체크리스트)
  filterCategory(event) {
    this.activeCategory = event.currentTarget.dataset.cat
    this._updateTabActive(this.tabTargets, this.activeCategory, "cat")
    this._filterCards()
    this._updateCount()
  }

  // 업무 분야 탭 (계약/예산/인사/여비/기타)
  filterDomain(event) {
    this.activeDomain = event.currentTarget.dataset.domain
    this._updateTabActive(this.domainTabTargets, this.activeDomain, "domain")
    this._filterCards()
    this._updateHash()
    this._updateCount()
  }

  // 실시간 검색
  search() {
    this._filterCards()
    this._updateCount()
  }

  // 그리드 뷰
  showGrid() {
    this._applyView("grid")
  }

  // 리스트 뷰
  showList() {
    this._applyView("list")
  }

  // --- private ---

  _filterCards() {
    const query = this.hasSearchInputTarget ? this.searchInputTarget.value.trim().toLowerCase() : ""

    this.cardTargets.forEach(card => {
      const catMatch = this.activeCategory === "전체" || card.dataset.category === this.activeCategory
      const domainMatch = this.activeDomain === "전체" || card.dataset.domain === this.activeDomain
      const searchMatch = !query || card.dataset.title.toLowerCase().includes(query) || (card.dataset.desc || "").toLowerCase().includes(query)
      card.style.display = (catMatch && domainMatch && searchMatch) ? "" : "none"
    })
  }

  _updateTabActive(tabs, activeValue, dataKey) {
    tabs.forEach(tab => {
      const isActive = tab.dataset[dataKey] === activeValue
      tab.classList.toggle("bg-indigo-600", isActive)
      tab.classList.toggle("text-white", isActive)
      tab.classList.toggle("bg-slate-100", !isActive)
      tab.classList.toggle("text-slate-700", !isActive)
    })
  }

  _applyView(view, save = true) {
    this.currentView = view
    if (save) localStorage.setItem("silmu_tools_view", view)

    const isGrid = view === "grid"

    if (this.hasGridContainerTarget) this.gridContainerTarget.classList.toggle("hidden", !isGrid)
    if (this.hasListContainerTarget) this.listContainerTarget.classList.toggle("hidden", isGrid)

    if (this.hasGridBtnTarget) {
      this.gridBtnTarget.classList.toggle("bg-indigo-600", isGrid)
      this.gridBtnTarget.classList.toggle("text-white", isGrid)
      this.gridBtnTarget.classList.toggle("bg-slate-100", !isGrid)
      this.gridBtnTarget.classList.toggle("text-slate-600", !isGrid)
    }
    if (this.hasListBtnTarget) {
      this.listBtnTarget.classList.toggle("bg-indigo-600", !isGrid)
      this.listBtnTarget.classList.toggle("text-white", !isGrid)
      this.listBtnTarget.classList.toggle("bg-slate-100", isGrid)
      this.listBtnTarget.classList.toggle("text-slate-600", isGrid)
    }
  }

  _updateCount() {
    if (!this.hasCountBadgeTarget) return
    const visible = this.cardTargets.filter(c => c.style.display !== "none").length
    this.countBadgeTarget.textContent = `${visible}개 도구`
  }

  _updateHash() {
    if (this.activeDomain !== "전체") {
      history.replaceState(null, "", `#${this.activeDomain}`)
    } else {
      history.replaceState(null, "", location.pathname)
    }
  }

  _restoreFromHash() {
    const hash = location.hash.replace("#", "")
    if (!hash) return

    const domainTab = this.domainTabTargets.find(t => t.dataset.domain === hash)
    if (domainTab) {
      this.activeDomain = hash
      this._updateTabActive(this.domainTabTargets, this.activeDomain, "domain")
      this._filterCards()
      this._updateCount()
    }
  }
}
