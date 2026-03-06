import { Controller } from "@hotwired/stimulus"

// Tailwind JIT가 동적 보간(text-${color}-400)을 감지 못하므로
// 사용하는 모든 색상 클래스를 미리 정의하여 안전하게 참조
const COLOR_CLASSES = {
  emerald: "text-emerald-400",
  indigo:  "text-indigo-400",
  slate:   "text-slate-400"
}

export default class extends Controller {
  static targets = ["input", "category", "result", "resultContent"]

  connect() {
    this.calculate()
  }

  format(event) {
    const val = event.target.value.replace(/[^0-9]/g, "")
    if (val) {
      event.target.value = Number(val).toLocaleString()
      this.calculate()
    } else {
      event.target.value = ""
      this.resultTarget.classList.add("hidden")
    }
  }

  addAmount(event) {
    const current = parseInt(this.inputTarget.value.replace(/,/g, "")) || 0
    const added = Number(event.currentTarget.dataset.value)
    this.inputTarget.value = (current + added).toLocaleString()
    this.calculate()
  }

  calculate() {
    const amount = parseInt(this.inputTarget.value.replace(/,/g, ""))
    const category = this.categoryTarget.value
    if (!amount || amount <= 0) {
      this.resultTarget.classList.add("hidden")
      return
    }

    let method, color, icon, desc, checklist
    if (category === "construction") {
      if (amount <= 20000000) {
        method = "1인 견적 수의계약"; color = "emerald"; icon = "person"
        desc = "추정가격 2천만원 이하 공사"
        checklist = ["견적서 1부 징구", "계약서 작성 (간이계약서 가능)", "착공신고서", "준공검사 및 대가 지급"]
      } else if (amount <= 200000000) {
        method = "2인 이상 견적 수의계약"; color = "indigo"; icon = "group"
        desc = "추정가격 2천만원 초과 ~ 2억원 이하 공사"
        checklist = ["추정가격 산정", "2인 이상 견적서 징구", "예정가격 작성", "계약서 작성", "착공신고서 → 준공검사 → 대가 지급"]
      } else {
        method = "경쟁입찰"; color = "slate"; icon = "groups"
        desc = "추정가격 2억원 초과 공사"
        checklist = ["추정가격 산정", "입찰공고 (7일 이상)", "예정가격 작성 (복수예비가격)", "적격심사", "계약 체결 → 착공 → 준공검사"]
      }
    } else {
      const typeName = category === "goods" ? "물품" : "용역"
      if (amount <= 20000000) {
        method = "1인 견적 수의계약"; color = "emerald"; icon = "person"
        desc = `추정가격 2천만원 이하 ${typeName}`
        checklist = ["견적서 1부 징구", "계약서 작성 (간이계약서 가능)", "검수 및 대가 지급"]
      } else if (amount <= 100000000) {
        method = "2인 이상 견적 수의계약"; color = "indigo"; icon = "group"
        desc = `추정가격 2천만원 초과 ~ 1억원 이하 ${typeName}`
        checklist = ["추정가격 산정", "2인 이상 견적서 징구", "예정가격 작성", "계약서 작성", "검수 및 대가 지급"]
      } else {
        method = "경쟁입찰"; color = "slate"; icon = "groups"
        desc = `추정가격 1억원 초과 ${typeName}`
        checklist = ["추정가격 산정", "입찰공고 (7일 이상)", "예정가격 작성 (복수예비가격)", "적격심사 또는 최저가낙찰", "계약 체결 → 검수 → 대가 지급"]
      }
    }

    const colorClass = COLOR_CLASSES[color] || COLOR_CLASSES.indigo

    this.resultTarget.classList.remove("hidden")
    this.resultContentTarget.className = "p-4 rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm"
    const detailPath = this.element.dataset.homePriceContractMethodPath || ""
    this.resultContentTarget.innerHTML = `
      <div class="flex items-center gap-3 mb-3">
        <span class="material-symbols-outlined text-2xl ${colorClass}">${icon}</span>
        <h3 class="text-lg font-bold text-white">${method}</h3>
      </div>
      <p class="text-slate-400 text-sm mb-3">${desc} (추정가격: ${amount.toLocaleString()}원)</p>
      <div class="space-y-2">
        ${checklist.map(item => `<div class="flex items-start gap-2"><span class="material-symbols-outlined ${colorClass} text-lg mt-0.5">check_circle</span><span class="text-slate-300 text-sm">${item}</span></div>`).join("")}
      </div>
      <div class="mt-4 pt-3 border-t border-white/10">
        <a href="${detailPath}" class="inline-flex items-center gap-1 text-indigo-400 hover:text-indigo-300 text-sm font-semibold">상세 분석 바로가기 <span class="material-symbols-outlined text-lg">arrow_forward</span></a>
      </div>`
  }
}
