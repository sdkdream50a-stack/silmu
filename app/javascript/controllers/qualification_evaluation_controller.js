// Created: 2026-02-22, Updated: 2026-03-05 (종심제 지원 추가)
// 적격심사·종합심사낙찰제 입찰률 확인 Stimulus Controller (가격평점은 예규 별표 산식이라 미산출)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "bidderFields", "result",
    "floorRateContainer", "floorRateNote",
    "projectTypeSection",
    "qualificationInfo", "comprehensiveInfo",
    "modeTab",
    "priceBanner",
    "submitBtnText"
  ]

  connect() {
    this.mode = "qualification"
    // 초기 안내도 같은 경로로 정한다. ERB 기본 문구를 그대로 두면 단일 출처가 아니게 된다.
    this._setFloorRateNote(false)
    this.updateBidderFields()
  }

  // 모드 탭 클릭 핸들러
  switchMode(event) {
    const newMode = event.currentTarget.dataset.mode
    this._applyMode(newMode)
  }

  // 300억 배너의 "종심제로 전환" 버튼
  switchModeToComprehensive() {
    this._applyMode("comprehensive")
  }

  _applyMode(newMode) {
    // 같은 탭 재클릭은 모드 변경이 아니다. 구분하지 않으면 입력해 둔 공고문 값이 지워진다.
    const modeChanged = newMode !== this.mode
    this.mode = newMode
    const isComprehensive = newMode === "comprehensive"

    // 탭 스타일 업데이트
    this.modeTabTargets.forEach(tab => {
      const active = tab.dataset.mode === newMode
      if (active) {
        tab.className = "flex-1 py-3 px-4 text-sm font-bold rounded-lg cursor-pointer transition-colors " +
          (isComprehensive ? "bg-purple-600 text-white" : "bg-forest-600 text-white")
      } else {
        tab.className = "flex-1 py-3 px-4 text-sm font-bold rounded-lg bg-gray-100 text-gray-600 cursor-pointer transition-colors hover:bg-gray-200"
      }
    })

    // 설명 섹션 토글
    if (this.hasQualificationInfoTarget) {
      this.qualificationInfoTarget.classList.toggle("hidden", isComprehensive)
    }
    if (this.hasComprehensiveInfoTarget) {
      this.comprehensiveInfoTarget.classList.toggle("hidden", !isComprehensive)
    }

    // 사업 종류 선택 (종심제는 항상 공사 → 숨김)
    if (this.hasProjectTypeSectionTarget) {
      this.projectTypeSectionTarget.classList.toggle("hidden", isComprehensive)
    }

    // 낙찰하한율은 모드마다 공고문 값이 다르다. 이전 모드 값이 남으면 확인 없이 그대로 제출된다 → 비운다.
    if (modeChanged) {
      const floorRateInput = this.floorRateContainerTarget?.querySelector("input")
      if (floorRateInput) floorRateInput.value = ""
    }
    this._setFloorRateNote(isComprehensive)

    // 제출 버튼 텍스트
    if (this.hasSubmitBtnTextTarget) {
      this.submitBtnTextTarget.textContent = isComprehensive ? "종심제 입찰률 확인" : "적격심사 입찰률 확인"
    }

    // 배너는 무조건 숨기면 적격심사로 돌아왔을 때 300억 경고가 사라진 채로 남는다 → 현재 입력으로 다시 판정한다.
    this.checkThreshold()

    // 모드가 그대로면 입력을 다시 그리지 않는다. 다시 그리면 입력해 둔 업체 정보가 전부 지워진다.
    if (modeChanged) {
      this._invalidateResult()
      this.updateBidderFields()
    }
  }

  // 산출 조건이 바뀌면 앞선 결과는 더 이상 그 조건의 결과가 아니다.
  // 남겨두면 사용자가 지금 선택과 다른 모드·사업종류의 판정을 보고 판단하게 된다.
  _invalidateResult() {
    // 이미 날아간 요청의 응답이 나중에 도착해 지운 결과를 되살리면, 바뀐 조건에 옛 판정이 붙는다.
    // 세대 번호를 올려 그 응답을 버린다.
    this._resultGeneration = (this._resultGeneration || 0) + 1
    if (!this.hasResultTarget) return
    this.resultTarget.innerHTML = ""
    this.resultTarget.classList.add("hidden")
  }

  // 금액·업체값 변경도 산출 조건 변경이다. 폼 레벨 input 이벤트로 동적 업체 입력까지 함께 잡는다.
  inputChanged() {
    this._invalidateResult()
  }

  // 낙찰하한율 안내는 모드와 사업 종류 양쪽에 달려 있다.
  // 두 곳에서 따로 쓰면 모드 복귀 때 용역인데 공사 참고값을 안내하는 식으로 갈라진다 → 한 곳에서만 정한다.
  _setFloorRateNote(isComprehensive) {
    if (!this.hasFloorRateNoteTarget) return

    // 공사 낙찰하한율은 추정가격 구간별로 갈린다(10억 미만 89.745 / 10억~50억 88.745 /
    // 50억~100억 87.495 / 100억~300억 81.995). 한 값을 참고값으로 제시하면 다른 구간 사용자가
    // 그대로 넣어 하한가와 미달 판정이 틀린다 → 숫자를 권하지 않고 공고문 값을 받는다.
    if (isComprehensive) {
      this.floorRateNoteTarget.textContent = "종심제: 공고문의 낙찰하한율을 입력하세요"
      return
    }

    const projectType = this.element.querySelector('[name="project_type"]')?.value || "construction"
    this.floorRateNoteTarget.textContent = projectType === "construction"
      ? "공사: 공고문의 낙찰하한율을 입력하세요 (추정가격 구간별로 다릅니다)"
      : "용역: 공고문의 낙찰하한율을 입력하세요 (계약 종류·금액구간별로 다름)"
  }

  // 비가격 배점 구조 업데이트 (적격심사 사업종류 변경 시)
  updateScoreStructure() {
    // 종류가 바뀌면 이전 종류의 공고문 값이 남으면 안 된다.
    const floorRateInput = this.floorRateContainerTarget?.querySelector("input")
    if (floorRateInput) floorRateInput.value = ""

    this._setFloorRateNote(this.mode === "comprehensive")
    // 종심제 대상은 공사 한정이라 사업 종류가 바뀌면 배너 판정도 다시 해야 한다.
    this.checkThreshold()
    this._invalidateResult()
    this.updateBidderFields()
  }

  // 300억 임계값 감지 — 기준은 추정가격이고, 종심제는 공사 대상이므로 용역에는 띄우지 않는다.
  checkThreshold() {
    const THRESHOLD = 30_000_000_000 // 추정가격 300억
    const presumed = parseFloat(this.element.querySelector('[name="presumed_price"]')?.value) || 0
    const projectType = this.element.querySelector('[name="project_type"]')?.value || "construction"

    if (this.hasPriceBannerTarget) {
      const applies = presumed >= THRESHOLD && projectType === "construction" && this.mode !== "comprehensive"
      this.priceBannerTarget.classList.toggle("hidden", !applies)
    }
  }

  // 업체 수 변경 시 재렌더링
  updateBidderFields() {
    const bidderCount = parseInt(this.element.querySelector('[name="bidder_count"]')?.value) || 3
    // 입력란을 다시 그리면 앞선 결과는 그 입력 구성의 결과가 아니다.
    this._invalidateResult()
    // 다시 그리면서 입력해 둔 값을 버리면 업체 수만 바꿔도 전부 다시 넣어야 한다 → 그대로 되살린다.
    const previous = this._currentBidderValues()

    if (this.mode === "comprehensive") {
      this._renderComprehensiveBidderFields(bidderCount, previous)
    } else {
      const projectType = this.element.querySelector('[name="project_type"]')?.value || "construction"
      const nonPriceMax = projectType === "construction" ? 40 : 30
      this._renderQualificationBidderFields(bidderCount, nonPriceMax, previous)
    }
  }

  _currentBidderValues() {
    const values = {}
    const nodes = this.element.querySelectorAll ? this.element.querySelectorAll('[name^="bidder_"]') : []
    for (const el of nodes) {
      if (/^bidder_\d+_/.test(el.name)) values[el.name] = el.value
    }
    return values
  }

  // 되살린 값은 속성값으로 들어가므로 따옴표·꺾쇠를 그대로 두면 마크업이 깨진다.
  _attr(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;").replace(/"/g, "&quot;")
      .replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  _renderQualificationBidderFields(bidderCount, nonPriceMax, previous = {}) {
    let html = '<div class="space-y-4">'
    for (let i = 1; i <= bidderCount; i++) {
      html += `
        <div class="border border-gray-300 rounded-lg p-4">
          <h4 class="font-bold text-gray-900 mb-3">업체 ${i}</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">업체명</label>
              <input type="text" name="bidder_${i}_name" placeholder="예: (주)ABC건설"
                     value="${this._attr(previous[`bidder_${i}_name`])}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">입찰가격 (원)</label>
              <input type="number" name="bidder_${i}_price" placeholder="예: 450000000"
                     value="${this._attr(previous[`bidder_${i}_price`])}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">비가격점수 (${nonPriceMax}점 만점)</label>
              <input type="number" name="bidder_${i}_non_price" placeholder="예: 35"
                     step="0.01" min="0" max="${nonPriceMax}"
                     value="${this._attr(previous[`bidder_${i}_non_price`])}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 text-sm">
            </div>
          </div>
        </div>
      `
    }
    html += '</div>'
    this.bidderFieldsTarget.innerHTML = html
  }

  _renderComprehensiveBidderFields(bidderCount, previous = {}) {
    let html = '<div class="space-y-4">'
    for (let i = 1; i <= bidderCount; i++) {
      html += `
        <div class="border border-purple-200 bg-purple-50 rounded-lg p-4">
          <h4 class="font-bold text-gray-900 mb-3">업체 ${i}</h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">업체명</label>
              <input type="text" name="bidder_${i}_name" placeholder="예: (주)ABC건설"
                     value="${this._attr(previous[`bidder_${i}_name`])}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">입찰가격 (원)</label>
              <input type="number" name="bidder_${i}_price" placeholder="예: 35000000000"
                     value="${this._attr(previous[`bidder_${i}_price`])}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
          </div>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                시공실적 <span class="text-gray-400">(참고 20점)</span>
              </label>
              <input type="number" name="bidder_${i}_construction"
                     placeholder="공고문 배점 기준" step="0.01" min="0" max="100"
                     value="${this._attr(previous[`bidder_${i}_construction`])}"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                시공능력 <span class="text-gray-400">(참고 15점)</span>
              </label>
              <input type="number" name="bidder_${i}_capacity"
                     placeholder="공고문 배점 기준" step="0.01" min="0" max="100"
                     value="${this._attr(previous[`bidder_${i}_capacity`])}"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                경영상태 <span class="text-gray-400">(참고 10점)</span>
              </label>
              <input type="number" name="bidder_${i}_management"
                     placeholder="공고문 배점 기준" step="0.01" min="0" max="100"
                     value="${this._attr(previous[`bidder_${i}_management`])}"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                사회적책임 <span class="text-gray-400">(참고 5점)</span>
              </label>
              <input type="number" name="bidder_${i}_social"
                     placeholder="공고문 배점 기준" step="0.01" min="0" max="100"
                     value="${this._attr(previous[`bidder_${i}_social`])}"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
          </div>
          <p class="text-xs text-purple-600 mt-2">배점(시공실적20·시공능력15·경영상태10·사회적책임5)은 참고값입니다 — 발주기관·공사유형별로 다를 수 있으니 공고문의 심사기준표를 확인하세요</p>
        </div>
      `
    }
    html += '</div>'
    this.bidderFieldsTarget.innerHTML = html
  }

  async submit(event) {
    event.preventDefault()
    // 새 제출은 앞선 요청을 폐기한다. 입력 변경 없이 연속 제출해 응답 순서가 뒤집혀도 최신 요청만 그린다.
    this._invalidateResult()
    const generation = this._resultGeneration || 0
    const form = event.target
    const formData = new FormData(form)
    const url = this.mode === "comprehensive"
      ? "/qualification-evaluations/comprehensive"
      : form.action

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: formData
      })
      const data = await response.json()
      // 응답을 기다리는 동안 입력·모드·사업종류·업체수가 바뀌었으면 지금 조건의 결과가 아니다.
      if ((this._resultGeneration || 0) !== generation) return
      // 422는 서버가 산출을 차단한 경우다. 본문을 결과로 넘기면 차단 사유가 화면에 뜨지 않아
      // 사용자는 아무 반응이 없는 것으로 본다 → 차단 메시지를 그대로 보여준다.
      if (!response.ok) {
        this._displayError(data.error)
        return
      }
      this.displayResult(data)
    } catch (error) {
      console.error("Error:", error)
      alert("계산 중 오류가 발생했습니다. 다시 시도해주세요.")
    }
  }

  _displayError(message) {
    this.resultTarget.innerHTML = `
      <div class="bg-red-50 border border-red-200 rounded-lg p-6">
        <h3 class="text-lg font-bold text-red-900 mb-2">⚠️ 산출할 수 없습니다</h3>
        <p class="text-sm text-red-800 leading-relaxed">${message || "입력값을 확인해주세요."}</p>
      </div>
    `
    this.resultTarget.classList.remove("hidden")
    this.resultTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  displayResult(data) {
    if (data.mode === "comprehensive") {
      this._displayComprehensiveResult(data)
    } else {
      this._displayQualificationResult(data)
    }
  }

  _displayQualificationResult(data) {
    const { bidders, winner, metadata } = data

    let html = `
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 class="text-2xl font-bold text-gray-900 mb-6">📊 적격심사 결과</h3>

        ${data.score_unavailable ? `
          <div class="bg-amber-50 border-2 border-amber-400 rounded-lg p-4 mb-6 text-sm text-amber-900">
            <strong class="block mb-1">점수는 산출하지 않습니다</strong>
            ${data.notice || ""}
          </div>
        ` : ""}

        <div class="bg-gray-50 p-4 rounded-lg mb-6">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <span class="text-gray-600">사업 종류</span>
              <strong class="block mt-1">${metadata.project_type === "construction" ? "공사" : "용역"}</strong>
            </div>
            <div>
              <span class="text-gray-600">예정가격</span>
              <strong class="block mt-1">${this._fmt(metadata.estimated_price)}원</strong>
            </div>
            <div>
              <span class="text-gray-600">가격점수 만점</span>
              <strong class="block mt-1">${metadata.price_max}점</strong>
            </div>
            <div>
              <span class="text-gray-600">비가격점수 만점</span>
              <strong class="block mt-1">${metadata.non_price_max}점</strong>
            </div>
          </div>
        </div>

        ${winner ? `
          <div class="bg-green-50 border-2 border-green-500 rounded-lg p-5 mb-6">
            <div class="flex items-center gap-2 mb-3">
              <span class="iconify w-6 h-6 text-green-600" data-icon="mdi:trophy"></span>
              <h4 class="text-lg font-bold text-green-900">낙찰자</h4>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div><span class="text-green-700">업체명</span><strong class="block text-base text-green-900 mt-0.5">${winner.name}</strong></div>
              <div><span class="text-green-700">입찰가격</span><strong class="block text-base text-green-900 mt-0.5">${this._fmt(winner.bid_price)}원</strong></div>
              <div><span class="text-green-700">100점 환산</span><strong class="block text-base text-green-900 mt-0.5">${winner.total_score_100}점</strong></div>
              <div><span class="text-green-700">상태</span><strong class="block text-base text-green-900 mt-0.5">적격 + 최저가</strong></div>
            </div>
          </div>
        ` : `
          <div class="bg-amber-50 border-2 border-amber-400 rounded-lg p-5 mb-6">
            <p class="text-amber-900 font-bold">가격평점을 산출하지 않으므로 적격 여부·낙찰자를 판정하지 않습니다.</p>
            <p class="text-amber-800 text-sm mt-1">낙찰하한율 미달 여부와 입찰률만 참고하고, 적격 판정은 공고문의 적격심사 세부기준으로 하세요.</p>
          </div>
        `}

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="bg-gray-100 border-b-2 border-gray-300">
                <th class="px-4 py-3 text-left">순위</th>
                <th class="px-4 py-3 text-left">업체명</th>
                <th class="px-4 py-3 text-right">입찰가격</th>
                <th class="px-4 py-3 text-right">입찰률</th>
                <th class="px-4 py-3 text-right">비가격점수</th>
                <th class="px-4 py-3 text-right">총점</th>
                <th class="px-4 py-3 text-right">100점 환산</th>
                <th class="px-4 py-3 text-center">낙찰하한율</th>
              </tr>
            </thead>
            <tbody>
    `

    bidders.forEach((b, idx) => {
      const isWinner = winner && b.name === winner.name
      const bg = b.below_floor ? "bg-red-50" : ""
      const cls = isWinner ? "font-bold text-green-900" : ""
      html += `
        <tr class="${bg} border-b border-gray-200">
          <td class="px-4 py-3 ${cls}">${idx + 1}</td>
          <td class="px-4 py-3 ${cls}">
            ${b.name}
            ${isWinner ? '<span class="ml-2 px-2 py-0.5 bg-green-600 text-white text-xs rounded">낙찰</span>' : ""}
          </td>
          <td class="px-4 py-3 text-right ${cls}">${this._fmt(b.bid_price)}원</td>
          <td class="px-4 py-3 text-right ${cls}">${b.bid_ratio === null || b.bid_ratio === undefined ? '—' : b.bid_ratio + '%'}</td>
          <td class="px-4 py-3 text-right ${cls}">${b.non_price_score}</td>
          <td class="px-4 py-3 text-right ${cls}">${b.total_score === null ? '—' : b.total_score}</td>
          <td class="px-4 py-3 text-right ${cls}">${b.total_score_100 === null ? '—' : b.total_score_100}</td>
          <td class="px-4 py-3 text-center">
            ${b.below_floor
              ? '<span class="px-2 py-1 bg-red-100 text-red-800 text-xs rounded font-bold">낙찰하한율 미달</span>'
              : '<span class="px-2 py-1 bg-slate-100 text-slate-700 text-xs rounded">하한 이상</span>'}
          </td>
        </tr>
      `
    })

    html += `
            </tbody>
          </table>
        </div>
        <div class="mt-5 p-4 bg-blue-50 rounded-lg text-sm text-blue-800">
          <strong>적격 기준(참고):</strong> ${metadata.pass_score === null || metadata.pass_score === undefined
            ? "추정가격을 입력하지 않아 통과기준 구간(공사 100억)을 판정하지 않았습니다 — 공고문에서 확인하세요"
            : `100점 환산 ${metadata.pass_score}점 이상`} &nbsp;|&nbsp;
          <strong>가격평점:</strong> 예규 별표의 금액구간별 산식 — 이 도구는 산출하지 않습니다
        </div>
      </div>
    `
    this.resultTarget.innerHTML = html
    this.resultTarget.classList.remove("hidden")
    this.resultTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  _displayComprehensiveResult(data) {
    const { bidders, winner, metadata } = data

    let html = `
      <div class="bg-white rounded-lg shadow-sm border border-purple-200 p-6">
        <h3 class="text-2xl font-bold text-gray-900 mb-1">📊 종합심사낙찰제 결과</h3>

        ${data.score_unavailable ? `
          <div class="bg-amber-50 border-2 border-amber-400 rounded-lg p-4 mb-6 text-sm text-amber-900">
            <strong class="block mb-1">점수는 산출하지 않습니다</strong>
            ${data.notice || ""}
          </div>
        ` : ""}
        <p class="text-sm text-purple-600 mb-6">참고 배점: 가격50 + 시공실적20 + 시공능력15 + 경영상태10 + 사회적책임5 — 실제 배점은 공고문의 심사기준표를 따릅니다</p>

        <div class="bg-gray-50 p-4 rounded-lg mb-6">
          <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
            <div>
              <span class="text-gray-600">예정가격</span>
              <strong class="block mt-1">${this._fmt(metadata.estimated_price)}원</strong>
            </div>
            <div>
              <span class="text-gray-600">낙찰하한율</span>
              <strong class="block mt-1">${metadata.floor_rate}%</strong>
            </div>
            <div>
              <span class="text-gray-600">낙찰하한금액</span>
              <strong class="block mt-1">${this._fmt(metadata.floor_price)}원</strong>
            </div>
          </div>
        </div>

        ${winner ? `
          <div class="bg-green-50 border-2 border-green-500 rounded-lg p-5 mb-6">
            <div class="flex items-center gap-2 mb-3">
              <span class="iconify w-6 h-6 text-green-600" data-icon="mdi:trophy"></span>
              <h4 class="text-lg font-bold text-green-900">낙찰자</h4>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div><span class="text-green-700">업체명</span><strong class="block text-base text-green-900 mt-0.5">${winner.name}</strong></div>
              <div><span class="text-green-700">입찰가격</span><strong class="block text-base text-green-900 mt-0.5">${this._fmt(winner.bid_price)}원</strong></div>
              <div><span class="text-green-700">총점</span><strong class="block text-base text-green-900 mt-0.5">${winner.total_score}점</strong></div>
              <div><span class="text-green-700">상태</span><strong class="block text-base text-green-900 mt-0.5">적격 + 최고점</strong></div>
            </div>
          </div>
        ` : `
          <div class="bg-amber-50 border-2 border-amber-400 rounded-lg p-5 mb-6">
            <p class="text-amber-900 font-bold">입찰금액 평점을 산출하지 않으므로 낙찰자를 판정하지 않습니다.</p>
            <p class="text-amber-800 text-sm mt-1">비가격 평점 합계와 낙찰하한율 미달 여부만 참고하고, 낙찰자 판단은 공고문 기준으로 하세요.</p>
          </div>
        `}

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="bg-purple-50 border-b-2 border-purple-200">
                <th class="px-3 py-3 text-left">순위</th>
                <th class="px-3 py-3 text-left">업체명</th>
                <th class="px-3 py-3 text-right">입찰가격</th>
                <th class="px-3 py-3 text-right">입찰률</th>
                <th class="px-3 py-3 text-right">시공실적<br><span class="text-xs font-normal text-gray-500">(참고 20)</span></th>
                <th class="px-3 py-3 text-right">시공능력<br><span class="text-xs font-normal text-gray-500">(참고 15)</span></th>
                <th class="px-3 py-3 text-right">경영상태<br><span class="text-xs font-normal text-gray-500">(참고 10)</span></th>
                <th class="px-3 py-3 text-right">사회적책임<br><span class="text-xs font-normal text-gray-500">(참고 5)</span></th>
                <th class="px-3 py-3 text-right font-bold">총점</th>
                <th class="px-3 py-3 text-center">낙찰하한율</th>
              </tr>
            </thead>
            <tbody>
    `

    bidders.forEach((b, idx) => {
      const isWinner = winner && b.name === winner.name
      const bg = b.below_floor ? "bg-red-50" : ""
      const cls = isWinner ? "font-bold text-green-900" : ""
      html += `
        <tr class="${bg} border-b border-gray-200">
          <td class="px-3 py-3 ${cls}">${idx + 1}</td>
          <td class="px-3 py-3 ${cls}">
            ${b.name}
            ${isWinner ? '<span class="ml-1 px-2 py-0.5 bg-green-600 text-white text-xs rounded">낙찰</span>' : ""}
          </td>
          <td class="px-3 py-3 text-right ${cls}">${this._fmt(b.bid_price)}원</td>
          <td class="px-3 py-3 text-right ${cls}">${b.bid_ratio === null || b.bid_ratio === undefined ? '—' : b.bid_ratio + '%'}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.construction}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.capacity}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.management}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.social}</td>
          <td class="px-3 py-3 text-right font-bold ${cls}">${b.total_score === null ? '—' : b.total_score}</td>
          <td class="px-3 py-3 text-center">
            ${b.below_floor
              ? '<span class="px-2 py-1 bg-red-100 text-red-800 text-xs rounded font-bold">낙찰하한율 미달</span>'
              : '<span class="px-2 py-1 bg-slate-100 text-slate-700 text-xs rounded">하한 이상</span>'}
          </td>
        </tr>
      `
    })

    html += `
            </tbody>
          </table>
        </div>
        <div class="mt-5 p-4 bg-purple-50 rounded-lg text-sm text-purple-800">
          <strong>적격 기준:</strong> 이 도구는 판정하지 않습니다 — 총점 기준은 공고문의 심사기준표로 확인하세요 &nbsp;|&nbsp;
          <strong>입찰금액 평점:</strong> 예규 별표 산식 — 이 도구는 산출하지 않습니다
        </div>
      </div>
    `
    this.resultTarget.innerHTML = html
    this.resultTarget.classList.remove("hidden")
    this.resultTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  _fmt(price) {
    return new Intl.NumberFormat("ko-KR").format(price)
  }
}
