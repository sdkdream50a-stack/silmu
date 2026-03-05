// Created: 2026-02-22, Updated: 2026-03-05 (종심제 지원 추가)
// 적격심사·종합심사낙찰제 자동 채점기 Stimulus Controller

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

    // 낙찰하한율 라벨 업데이트
    if (this.hasFloorRateNoteTarget) {
      this.floorRateNoteTarget.textContent = isComprehensive
        ? "종심제: 89.745% (공사 기준)"
        : "공사: 89.745% (2026년 1월 변경)"
    }

    // 제출 버튼 텍스트
    if (this.hasSubmitBtnTextTarget) {
      this.submitBtnTextTarget.textContent = isComprehensive ? "종심제 계산하기" : "적격심사 계산하기"
    }

    // 배너 숨기기
    if (this.hasPriceBannerTarget) {
      this.priceBannerTarget.classList.add("hidden")
    }

    this.updateBidderFields()
  }

  // 비가격 배점 구조 업데이트 (적격심사 사업종류 변경 시)
  updateScoreStructure(event) {
    const projectType = event.target.value
    const floorRateInput = this.floorRateContainerTarget?.querySelector("input")
    const floorRateNote = this.hasFloorRateNoteTarget ? this.floorRateNoteTarget : null

    if (projectType === "construction") {
      if (floorRateInput) floorRateInput.value = "89.745"
      if (floorRateNote) floorRateNote.textContent = "공사: 89.745% (2026년 1월 변경)"
    } else {
      if (floorRateInput) floorRateInput.value = "0"
      if (floorRateNote) floorRateNote.textContent = "용역: 낙찰하한율 없음"
    }
    this.updateBidderFields()
  }

  // 300억 임계값 감지
  checkThreshold(event) {
    const price = parseFloat(event.target.value) || 0
    const THRESHOLD = 30_000_000_000 // 300억

    if (this.hasPriceBannerTarget) {
      this.priceBannerTarget.classList.toggle("hidden", price < THRESHOLD || this.mode === "comprehensive")
    }
  }

  // 업체 수 변경 시 재렌더링
  updateBidderFields() {
    const bidderCount = parseInt(this.element.querySelector('[name="bidder_count"]')?.value) || 3

    if (this.mode === "comprehensive") {
      this._renderComprehensiveBidderFields(bidderCount)
    } else {
      const projectType = this.element.querySelector('[name="project_type"]')?.value || "construction"
      const nonPriceMax = projectType === "construction" ? 40 : 30
      this._renderQualificationBidderFields(bidderCount, nonPriceMax)
    }
  }

  _renderQualificationBidderFields(bidderCount, nonPriceMax) {
    let html = '<div class="space-y-4">'
    for (let i = 1; i <= bidderCount; i++) {
      html += `
        <div class="border border-gray-300 rounded-lg p-4">
          <h4 class="font-bold text-gray-900 mb-3">업체 ${i}</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">업체명</label>
              <input type="text" name="bidder_${i}_name" placeholder="예: (주)ABC건설"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">입찰가격 (원)</label>
              <input type="number" name="bidder_${i}_price" placeholder="예: 450000000"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">비가격점수 (${nonPriceMax}점 만점)</label>
              <input type="number" name="bidder_${i}_non_price" placeholder="예: 35"
                     step="0.01" min="0" max="${nonPriceMax}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 text-sm">
            </div>
          </div>
        </div>
      `
    }
    html += '</div>'
    this.bidderFieldsTarget.innerHTML = html
  }

  _renderComprehensiveBidderFields(bidderCount) {
    let html = '<div class="space-y-4">'
    for (let i = 1; i <= bidderCount; i++) {
      html += `
        <div class="border border-purple-200 bg-purple-50 rounded-lg p-4">
          <h4 class="font-bold text-gray-900 mb-3">업체 ${i}</h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">업체명</label>
              <input type="text" name="bidder_${i}_name" placeholder="예: (주)ABC건설"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">입찰가격 (원)</label>
              <input type="number" name="bidder_${i}_price" placeholder="예: 35000000000"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
          </div>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                시공실적 <span class="text-gray-400">(20점)</span>
              </label>
              <input type="number" name="bidder_${i}_construction"
                     placeholder="0~20" step="0.01" min="0" max="20"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                시공능력 <span class="text-gray-400">(15점)</span>
              </label>
              <input type="number" name="bidder_${i}_capacity"
                     placeholder="0~15" step="0.01" min="0" max="15"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                경영상태 <span class="text-gray-400">(10점)</span>
              </label>
              <input type="number" name="bidder_${i}_management"
                     placeholder="0~10" step="0.01" min="0" max="10"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">
                사회적책임 <span class="text-gray-400">(5점)</span>
              </label>
              <input type="number" name="bidder_${i}_social"
                     placeholder="0~5" step="0.01" min="0" max="5"
                     class="w-full px-3 py-2 border border-purple-200 rounded-lg focus:ring-2 focus:ring-purple-500 text-sm bg-white">
            </div>
          </div>
          <p class="text-xs text-purple-600 mt-2">비가격점수 합계 최대 50점 (시공실적20 + 시공능력15 + 경영상태10 + 사회적책임5)</p>
        </div>
      `
    }
    html += '</div>'
    this.bidderFieldsTarget.innerHTML = html
  }

  async submit(event) {
    event.preventDefault()
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
      this.displayResult(data)
    } catch (error) {
      console.error("Error:", error)
      alert("계산 중 오류가 발생했습니다. 다시 시도해주세요.")
    }
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
          <div class="bg-red-50 border-2 border-red-500 rounded-lg p-5 mb-6">
            <p class="text-red-900 font-bold">⚠️ 적격자(95점 이상)가 없습니다. 재입찰이 필요합니다.</p>
          </div>
        `}

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="bg-gray-100 border-b-2 border-gray-300">
                <th class="px-4 py-3 text-left">순위</th>
                <th class="px-4 py-3 text-left">업체명</th>
                <th class="px-4 py-3 text-right">입찰가격</th>
                <th class="px-4 py-3 text-right">가격점수</th>
                <th class="px-4 py-3 text-right">비가격점수</th>
                <th class="px-4 py-3 text-right">총점</th>
                <th class="px-4 py-3 text-right">100점 환산</th>
                <th class="px-4 py-3 text-center">적격 여부</th>
              </tr>
            </thead>
            <tbody>
    `

    bidders.forEach((b, idx) => {
      const isWinner = winner && b.name === winner.name
      const bg = isWinner ? "bg-green-100" : (b.is_qualified ? "bg-blue-50" : "")
      const cls = isWinner ? "font-bold text-green-900" : ""
      html += `
        <tr class="${bg} border-b border-gray-200">
          <td class="px-4 py-3 ${cls}">${idx + 1}</td>
          <td class="px-4 py-3 ${cls}">
            ${b.name}
            ${isWinner ? '<span class="ml-2 px-2 py-0.5 bg-green-600 text-white text-xs rounded">낙찰</span>' : ""}
          </td>
          <td class="px-4 py-3 text-right ${cls}">${this._fmt(b.bid_price)}원</td>
          <td class="px-4 py-3 text-right ${cls}">${b.price_score}</td>
          <td class="px-4 py-3 text-right ${cls}">${b.non_price_score}</td>
          <td class="px-4 py-3 text-right ${cls}">${b.total_score}</td>
          <td class="px-4 py-3 text-right ${cls}">${b.total_score_100}</td>
          <td class="px-4 py-3 text-center">
            ${b.is_qualified
              ? '<span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded font-bold">적격</span>'
              : '<span class="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded">부적격</span>'}
          </td>
        </tr>
      `
    })

    html += `
            </tbody>
          </table>
        </div>
        <div class="mt-5 p-4 bg-blue-50 rounded-lg text-sm text-blue-800">
          <strong>적격 기준:</strong> 100점 환산 95점 이상 &nbsp;|&nbsp;
          <strong>낙찰자:</strong> 적격자 중 입찰가격 최저 업체
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
        <p class="text-sm text-purple-600 mb-6">배점: 가격50 + 시공실적20 + 시공능력15 + 경영상태10 + 사회적책임5 = 100점</p>

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
          <div class="bg-red-50 border-2 border-red-500 rounded-lg p-5 mb-6">
            <p class="text-red-900 font-bold">⚠️ 적격자(92점 이상)가 없습니다. 재입찰이 필요합니다.</p>
          </div>
        `}

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="bg-purple-50 border-b-2 border-purple-200">
                <th class="px-3 py-3 text-left">순위</th>
                <th class="px-3 py-3 text-left">업체명</th>
                <th class="px-3 py-3 text-right">입찰가격</th>
                <th class="px-3 py-3 text-right">가격<br><span class="text-xs font-normal text-gray-500">(50)</span></th>
                <th class="px-3 py-3 text-right">시공실적<br><span class="text-xs font-normal text-gray-500">(20)</span></th>
                <th class="px-3 py-3 text-right">시공능력<br><span class="text-xs font-normal text-gray-500">(15)</span></th>
                <th class="px-3 py-3 text-right">경영상태<br><span class="text-xs font-normal text-gray-500">(10)</span></th>
                <th class="px-3 py-3 text-right">사회적책임<br><span class="text-xs font-normal text-gray-500">(5)</span></th>
                <th class="px-3 py-3 text-right font-bold">총점</th>
                <th class="px-3 py-3 text-center">적격</th>
              </tr>
            </thead>
            <tbody>
    `

    bidders.forEach((b, idx) => {
      const isWinner = winner && b.name === winner.name
      const bg = isWinner ? "bg-green-100" : (b.is_qualified ? "bg-blue-50" : "")
      const cls = isWinner ? "font-bold text-green-900" : ""
      html += `
        <tr class="${bg} border-b border-gray-200">
          <td class="px-3 py-3 ${cls}">${idx + 1}</td>
          <td class="px-3 py-3 ${cls}">
            ${b.name}
            ${isWinner ? '<span class="ml-1 px-2 py-0.5 bg-green-600 text-white text-xs rounded">낙찰</span>' : ""}
          </td>
          <td class="px-3 py-3 text-right ${cls}">${this._fmt(b.bid_price)}원</td>
          <td class="px-3 py-3 text-right ${cls}">${b.price_score}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.construction}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.capacity}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.management}</td>
          <td class="px-3 py-3 text-right ${cls}">${b.social}</td>
          <td class="px-3 py-3 text-right font-bold ${cls}">${b.total_score}</td>
          <td class="px-3 py-3 text-center">
            ${b.is_qualified
              ? '<span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded font-bold">적격</span>'
              : '<span class="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded">부적격</span>'}
          </td>
        </tr>
      `
    })

    html += `
            </tbody>
          </table>
        </div>
        <div class="mt-5 p-4 bg-purple-50 rounded-lg text-sm text-purple-800">
          <strong>적격 기준:</strong> 총점 92점 이상 &nbsp;|&nbsp;
          <strong>낙찰자:</strong> 적격자 중 최고점 업체 (동점 시 최저가) &nbsp;|&nbsp;
          <strong>가격점수:</strong> 최저입찰금액 × 50 ÷ 해당입찰금액
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
