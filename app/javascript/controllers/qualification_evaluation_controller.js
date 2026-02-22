// Created: 2026-02-22
// 적격심사 자동 채점기 Stimulus Controller

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bidderFields", "result", "floorRateContainer"]

  connect() {
    this.updateBidderFields()
  }

  updateScoreStructure(event) {
    const projectType = event.target.value
    const floorRateContainer = this.floorRateContainerTarget

    if (projectType === "construction") {
      floorRateContainer.querySelector("input").value = "89.745"
      floorRateContainer.querySelector("p").textContent = "공사: 89.745% (2026년 1월 변경)"
    } else {
      floorRateContainer.querySelector("input").value = "0"
      floorRateContainer.querySelector("p").textContent = "용역: 낙찰하한율 없음"
    }
  }

  updateBidderFields() {
    const bidderCount = parseInt(this.element.querySelector('[name="bidder_count"]').value)
    const projectType = this.element.querySelector('[name="project_type"]').value
    const priceMax = projectType === "construction" ? 60 : 70
    const nonPriceMax = projectType === "construction" ? 40 : 30

    let html = '<div class="space-y-4">'

    for (let i = 1; i <= bidderCount; i++) {
      html += `
        <div class="border border-gray-300 rounded-lg p-4">
          <h4 class="font-bold text-gray-900 mb-3">업체 ${i}</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">업체명</label>
              <input type="text" name="bidder_${i}_name" placeholder="예: (주)ABC건설"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 focus:border-transparent text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">입찰가격 (원)</label>
              <input type="number" name="bidder_${i}_price" placeholder="예: 450000000"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 focus:border-transparent text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">비가격점수 (${nonPriceMax}점 만점)</label>
              <input type="number" name="bidder_${i}_non_price" placeholder="예: 35" step="0.01" min="0" max="${nonPriceMax}"
                     class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-forest-500 focus:border-transparent text-sm">
            </div>
          </div>
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

    try {
      const response = await fetch(form.action, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: formData
      })

      const data = await response.json()
      this.displayResult(data)
    } catch (error) {
      console.error('Error:', error)
      alert('계산 중 오류가 발생했습니다. 다시 시도해주세요.')
    }
  }

  displayResult(data) {
    const { bidders, qualified_bidders, winner, metadata } = data

    let html = `
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 class="text-2xl font-bold text-gray-900 mb-6">📊 적격심사 결과</h3>

        <!-- 기본 정보 -->
        <div class="bg-gray-50 p-4 rounded-lg mb-6">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <span class="text-gray-600">사업 종류:</span>
              <strong class="block mt-1">${metadata.project_type === 'construction' ? '공사' : '용역'}</strong>
            </div>
            <div>
              <span class="text-gray-600">예정가격:</span>
              <strong class="block mt-1">${this.formatPrice(metadata.estimated_price)}원</strong>
            </div>
            <div>
              <span class="text-gray-600">가격점수 만점:</span>
              <strong class="block mt-1">${metadata.price_max}점</strong>
            </div>
            <div>
              <span class="text-gray-600">비가격점수 만점:</span>
              <strong class="block mt-1">${metadata.non_price_max}점</strong>
            </div>
          </div>
        </div>

        <!-- 낙찰자 -->
        ${winner ? `
          <div class="bg-green-50 border-2 border-green-500 rounded-lg p-6 mb-6">
            <div class="flex items-center gap-3 mb-4">
              <span class="iconify w-8 h-8 text-green-600" data-icon="mdi:trophy"></span>
              <h4 class="text-xl font-bold text-green-900">낙찰자</h4>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <span class="text-sm text-green-700">업체명</span>
                <strong class="block text-lg text-green-900 mt-1">${winner.name}</strong>
              </div>
              <div>
                <span class="text-sm text-green-700">입찰가격</span>
                <strong class="block text-lg text-green-900 mt-1">${this.formatPrice(winner.bid_price)}원</strong>
              </div>
              <div>
                <span class="text-sm text-green-700">총점 (100점 환산)</span>
                <strong class="block text-lg text-green-900 mt-1">${winner.total_score_100}점</strong>
              </div>
              <div>
                <span class="text-sm text-green-700">상태</span>
                <strong class="block text-lg text-green-900 mt-1">적격 + 최저가</strong>
              </div>
            </div>
          </div>
        ` : `
          <div class="bg-red-50 border-2 border-red-500 rounded-lg p-6 mb-6">
            <p class="text-red-900 font-bold">⚠️ 적격자(95점 이상)가 없습니다. 재입찰이 필요합니다.</p>
          </div>
        `}

        <!-- 전체 업체 결과 -->
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="bg-gray-100 border-b-2 border-gray-300">
                <th class="px-4 py-3 text-left font-bold">순위</th>
                <th class="px-4 py-3 text-left font-bold">업체명</th>
                <th class="px-4 py-3 text-right font-bold">입찰가격</th>
                <th class="px-4 py-3 text-right font-bold">가격점수</th>
                <th class="px-4 py-3 text-right font-bold">비가격점수</th>
                <th class="px-4 py-3 text-right font-bold">총점</th>
                <th class="px-4 py-3 text-right font-bold">100점 환산</th>
                <th class="px-4 py-3 text-center font-bold">적격 여부</th>
              </tr>
            </thead>
            <tbody>
    `

    bidders.forEach((bidder, index) => {
      const isWinner = winner && bidder.name === winner.name
      const bgClass = isWinner ? 'bg-green-100' : (bidder.is_qualified ? 'bg-blue-50' : '')
      const textClass = isWinner ? 'font-bold text-green-900' : ''

      html += `
        <tr class="${bgClass} border-b border-gray-200">
          <td class="px-4 py-3 ${textClass}">${index + 1}</td>
          <td class="px-4 py-3 ${textClass}">
            ${bidder.name}
            ${isWinner ? '<span class="ml-2 px-2 py-0.5 bg-green-600 text-white text-xs rounded">낙찰</span>' : ''}
          </td>
          <td class="px-4 py-3 text-right ${textClass}">${this.formatPrice(bidder.bid_price)}원</td>
          <td class="px-4 py-3 text-right ${textClass}">${bidder.price_score}점</td>
          <td class="px-4 py-3 text-right ${textClass}">${bidder.non_price_score}점</td>
          <td class="px-4 py-3 text-right ${textClass}">${bidder.total_score}점</td>
          <td class="px-4 py-3 text-right ${textClass}">${bidder.total_score_100}점</td>
          <td class="px-4 py-3 text-center">
            ${bidder.is_qualified
              ? '<span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded font-bold">적격</span>'
              : '<span class="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded">부적격</span>'
            }
          </td>
        </tr>
      `
    })

    html += `
            </tbody>
          </table>
        </div>

        <div class="mt-6 p-4 bg-blue-50 rounded-lg">
          <h4 class="font-bold text-blue-900 mb-2">💡 결과 해석</h4>
          <ul class="text-sm text-blue-800 space-y-1">
            <li>• <strong>적격</strong>: 100점 환산 점수 95점 이상</li>
            <li>• <strong>낙찰자</strong>: 적격자 중 입찰가격이 가장 낮은 업체</li>
            <li>• 적격자가 없으면 재입찰 또는 유찰 처리</li>
          </ul>
        </div>
      </div>
    `

    this.resultTarget.innerHTML = html
    this.resultTarget.classList.remove('hidden')
    this.resultTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }

  formatPrice(price) {
    return new Intl.NumberFormat('ko-KR').format(price)
  }
}
