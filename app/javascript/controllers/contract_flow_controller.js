import { Controller } from "@hotwired/stimulus"

// 계약 흐름도 Stimulus 컨트롤러
// 인라인 JS에서 분리 — Turbo 호환 lifecycle 자동 관리
export default class extends Controller {
  static values = {
    steps: Object,    // stepData JSON은 data-contract-flow-steps-value로 전달
    bindings: Object  // P2 — 단계별 «지금 쓸 자산». config/workflow_bindings.yml 이 정본
  }

  // 그룹 → 화면 표기. 「눌러서 일을 진행하는 것」과 「읽을거리」를 섞지 않는다.
  static GROUP_LABELS = {
    tools: "이 단계에서 쓸 도구",
    review_lab: "문서 검증",
    forms: "서식",
    topics: "근거·설명",
    guides: "작성법",
    audit_cases: "이렇게 하면 지적된다"
  }
  static GROUP_ORDER = ["tools", "review_lab", "forms", "topics", "guides", "audit_cases"]

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
    const panelHtml = this._buildDetailPanel(data, stepKey)

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

  _buildDetailPanel(data, stepKey) {
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
        this._buildBindingsHtml(stepKey) +
        this._buildNextStepHtml(stepKey) +
      '</div>' +
    '</div>'
  }

  // ── P2 — 이 단계에서 쓸 자산 ──
  // 결속이 없는 단계는 아무것도 그리지 않는다. 빈 상자를 그리면 «있는데 비었다» 로 읽힌다.
  _buildBindingsHtml(stepKey) {
    const groups = this.hasBindingsValue ? this.bindingsValue[stepKey] : null
    if (!groups) return ''

    const ctor = this.constructor
    const sections = ctor.GROUP_ORDER.filter(g => Array.isArray(groups[g]) && groups[g].length > 0).map(group => {
      const items = groups[group].map(item => this._buildBindingLink(stepKey, item)).join('')
      return '<div class="flow-binding-group">' +
        '<span class="small-label">' + this._escapeHtml(ctor.GROUP_LABELS[group]) + '</span>' +
        '<ul class="flow-binding-list">' + items + '</ul>' +
      '</div>'
    }).join('')
    if (!sections) return ''

    return '<div class="small-box flow-bindings">' +
      '<span class="material-symbols-outlined">alt_route</span>' +
      '<div><span class="small-label">다음 행동</span>' + sections + '</div>' +
    '</div>'
  }

  _buildBindingLink(stepKey, item) {
    const href = this._escapeHtml(item.path)
    // slot 에 단계와 도착지를 함께 싣는다 — 새 GA4 이벤트를 만들지 않고 workflow_stage 를 얻는다.
    const slot = this._escapeHtml(stepKey + ':' + item.path)
    const label = this._escapeHtml(item.label)
    const why = item.why ? '<span class="flow-binding-why">' + this._escapeHtml(item.why) + '</span>' : ''
    // 학교 적용 차이는 config/tool_trust.yml 의 기존 판정에서 온다(여기서 만들지 않는다).
    const note = item.school_note
      ? '<span class="flow-binding-note"><strong>학교 적용 전 확인</strong> ' + this._escapeHtml(item.school_note) + '</span>'
      : ''
    return '<li><a href="' + href + '" data-action="click->next-action#track" ' +
      'data-next-action-slot-param="' + slot + '">' + label + '</a>' + why + note + '</li>'
  }

  // ── P2 — 다음 단계 ──
  // 데이터로 적지 않는다. 단계 번호에서 파생한다(goods-3 다음은 goods-4).
  _buildNextStepHtml(stepKey) {
    const parts = String(stepKey).split('-')
    const num = parseInt(parts[parts.length - 1], 10)
    if (!Number.isInteger(num)) return ''
    const nextKey = parts.slice(0, -1).join('-') + '-' + (num + 1)
    const next = this.stepsValue[nextKey]
    if (!next) {
      return '<div class="flow-next-step flow-next-step-end">이 흐름의 마지막 단계입니다.</div>'
    }
    return '<div class="flow-next-step">' +
      '<span class="small-label">다음 단계</span> ' +
      '<button type="button" class="flow-next-step-btn" data-next-step-key="' + this._escapeHtml(nextKey) + '" ' +
      'data-action="click->contract-flow#goToStep">' +
      (num + 1) + '. ' + this._escapeHtml(next.title) +
      '</button>' +
    '</div>'
  }

  // 다음 단계 카드를 열어 준다 — 메뉴로 돌아가지 않게 하는 것이 이 작업의 목적이다.
  goToStep(event) {
    event.stopPropagation()
    const target = event.currentTarget.dataset.nextStepKey
    const card = this.element.querySelector('.flow-step[data-step="' + target + '"]')
    if (!card) return
    this.closeDetail()
    card.click()
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
