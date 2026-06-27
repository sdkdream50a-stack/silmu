import { Controller } from "@hotwired/stimulus"

// 계약 흐름도 Stimulus 컨트롤러
// 인라인 JS에서 분리 — Turbo 호환 lifecycle 자동 관리
export default class extends Controller {
  static values = {
    steps: Object  // stepData JSON은 data-contract-flow-steps-value로 전달
  }

  connect() {
    this._initKeyboard()
  }

  disconnect() {
    this.closeDetail()
  }

  // ── 탭 전환 ──
  showFlow(event) {
    const tab = event.currentTarget.dataset.tab
    this.element.querySelectorAll('.flow-tab').forEach(t => {
      const isActive = t.dataset.tab === tab
      t.classList.toggle('active', isActive)
      t.setAttribute('aria-selected', isActive ? 'true' : 'false')
    })
    this.element.querySelectorAll('.flow-container').forEach(c => {
      c.classList.remove('active')
    })
    this.element.querySelector('#flow-' + tab).classList.add('active')
    this.closeDetail()
  }

  // ── 단계 카드 토글 ──
  toggleStep(event) {
    const el = event.currentTarget
    const stepKey = el.dataset.step
    const data = this.stepsValue[stepKey]
    if (!data) return

    const type = stepKey.split('-')[0]
    const container = this.element.querySelector('#step-detail-' + type)
    const wasSelected = el.classList.contains('selected')

    // 같은 흐름도 내 모든 카드 선택 해제
    el.closest('.flow-steps').querySelectorAll('.flow-step').forEach(s => {
      s.classList.remove('selected')
    })

    if (wasSelected) {
      container.innerHTML = ''
      el.closest('.flow-steps').querySelectorAll('.step-detail-inline').forEach(p => p.remove())
      return
    }

    el.classList.add('selected')
    const panelHtml = this._buildDetailPanel(data)

    if (window.innerWidth < 768) {
      el.closest('.flow-steps').querySelectorAll('.step-detail-inline').forEach(p => p.remove())
      container.innerHTML = ''
      const inlinePanel = document.createElement('div')
      inlinePanel.className = 'step-detail-inline'
      inlinePanel.style.cssText = 'grid-column: 1 / -1; margin-bottom: 8px;'
      inlinePanel.innerHTML = panelHtml
      const nextEl = el.nextElementSibling
      if (nextEl && nextEl.classList.contains('flow-arrow')) {
        nextEl.insertAdjacentElement('afterend', inlinePanel)
      } else {
        el.insertAdjacentElement('afterend', inlinePanel)
      }
      inlinePanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    } else {
      container.innerHTML = panelHtml
      container.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }

  // ── 상세 패널 닫기 ──
  closeDetail() {
    this.element.querySelectorAll('.flow-step.selected').forEach(s => {
      s.classList.remove('selected')
    })
    this.element.querySelectorAll('[id^="step-detail-"]').forEach(c => {
      c.innerHTML = ''
    })
    this.element.querySelectorAll('.step-detail-inline').forEach(p => {
      p.remove()
    })
  }

  // ── 키보드 접근성 ──
  stepKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.toggleStep(event)
    }
  }

  // ── Turbo 캐시 저장 전 상태 초기화 ──
  beforeCache() {
    this.closeDetail()
  }

  // ── private ──
  _initKeyboard() {
    this.element.querySelectorAll('.flow-step').forEach(step => {
      step.setAttribute('role', 'button')
      step.setAttribute('tabindex', '0')
    })
  }

  _buildDetailPanel(data) {
    const itemsHtml = data.items.map(item =>
      '<li><span class="material-symbols-outlined">check_circle</span>' + item + '</li>'
    ).join('')
    const docsHtml = this._buildDocsHtml(data.docs)
    const finalDocsHtml = this._buildFinalDocsHtml(data.final_docs)
    let smallHtml = ''
    if (data.small) {
      smallHtml = '<div class="small-box"><span class="material-symbols-outlined">info</span><div><span class="small-label">소액</span><br>' + data.small + '</div></div>'
    }
    let lawsHtml = ''
    if (data.laws) {
      const lawItemsHtml = data.laws.map(law => {
        const lawText = '<strong>' + law.ref + '</strong> — ' + law.desc
        return law.href ? '<div><a href="' + law.href + '">' + lawText + '</a></div>' : '<div>' + lawText + '</div>'
      }).join('')
      lawsHtml = '<div class="small-box"><span class="material-symbols-outlined">gavel</span><div><span class="small-label">근거 법령</span><br>' + lawItemsHtml + '</div></div>'
    }
    return '<div class="step-detail-panel">' +
      '<div class="step-detail-top">' +
        '<div class="step-detail-num">' + data.num + '</div>' +
        '<div><h4>' + data.title + '</h4></div>' +
        '<button class="step-detail-close" data-action="click->contract-flow#closeDetail"><span class="material-symbols-outlined">close</span></button>' +
      '</div>' +
      '<div class="step-detail-content">' +
        '<ul>' + itemsHtml + '</ul>' +
        docsHtml +
        finalDocsHtml +
        '<div class="tip-box"><span class="material-symbols-outlined">lightbulb</span>' + data.tip + '</div>' +
        smallHtml +
        lawsHtml +
      '</div>' +
    '</div>'
  }

  _buildDocsHtml(docs) {
    if (!docs || docs.length === 0) return ''

    const docItemsHtml = docs.map(doc =>
      '<li><span class="material-symbols-outlined">task_alt</span>' + this._formatDocText(doc) + '</li>'
    ).join('')

    return '<div class="small-box"><span class="material-symbols-outlined">folder_copy</span><div><span class="small-label">필요 서류</span><br><ul>' + docItemsHtml + '</ul></div></div>'
  }

  _buildFinalDocsHtml(finalDocs) {
    if (!finalDocs) return ''

    const alwaysHtml = this._buildChecklistItems(finalDocs.always)
    const conditionalHtml = this._buildChecklistItems(finalDocs.conditional)

    return '<div class="small-box"><span class="material-symbols-outlined">fact_check</span><div>' +
      '<span class="small-label">📋 최종 완비 서류 체크리스트</span><br>' +
      '<strong>상시</strong><ul>' + alwaysHtml + '</ul>' +
      '<strong>[해당 시]</strong><ul>' + conditionalHtml + '</ul>' +
    '</div></div>'
  }

  _buildChecklistItems(items) {
    if (!items || items.length === 0) return ''

    return items.map(item =>
      '<li><span aria-hidden="true">&#9633;</span>' + this._formatDocText(item) + '</li>'
    ).join('')
  }

  _formatDocText(text) {
    const escapedText = this._escapeHtml(text)
    return escapedText
      .replace(/^(\([^)]+\))/, '<strong>$1</strong>')
      .replace(/(\[[^\]]+\])/g, '<span class="small-label">$1</span>')
  }

  _escapeHtml(value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
  }
}
