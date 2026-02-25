import { Controller } from "@hotwired/stimulus"
import { calcSettlement, RATES } from "../insurance/engine.js"

export default class extends Controller {
  static targets = [
    // 탭 UI
    "tabBtn", "panel", "combinedTab", "combinedPanel", "advancedToggle",
    // 연말정산 입력
    "bonsuWolYearend", "bonsuTotalYearend", "geunMonthsYearend",
    "wolIpYearend", "il1MonthYearend", "il1FieldYearend", "accidentRateYearend",
    "ginamPensionPYearend", "ginamPensionGYearend",
    "ginamHealthPYearend", "ginamHealthGYearend",
    "ginamCarePYearend", "ginamCareGYearend",
    "ginamEmployPYearend", "ginamEmployGYearend",
    "ginamAccidentGYearend",
    // 퇴직정산 입력
    "bonsuWolRetire", "bonsuTotalRetire", "geunMonthsRetire",
    "wolIpRetire", "il1MonthRetire", "il1FieldRetire", "accidentRateRetire",
    "ginamPensionPRetire", "ginamPensionGRetire",
    "ginamHealthPRetire", "ginamHealthGRetire",
    "ginamCarePRetire", "ginamCareGRetire",
    "ginamEmployPRetire", "ginamEmployGRetire",
    "ginamAccidentGRetire",
    // 결과
    "resultYearend", "resultRetire",
    "resultTableYearend", "resultTableRetire",
    "resultBodyYearend", "resultBodyRetire",
    "resultFootYearend", "resultFootRetire",
    "combinedResult",
  ]

  connect() {
    this.advancedMode = false
    this.results = { yearend: null, retire: null }
  }

  // ── 탭 전환 ──
  switchTab(e) {
    const tab = e.currentTarget.dataset.tab
    this.tabBtnTargets.forEach(btn => {
      const isActive = btn.dataset.tab === tab
      btn.classList.toggle("bg-white", isActive)
      btn.classList.toggle("text-slate-900", isActive)
      btn.classList.toggle("shadow-sm", isActive)
      btn.classList.toggle("text-slate-500", !isActive)
    })
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.panel !== tab)
    })
  }

  // ── 합산 모드 토글 ──
  toggleAdvanced() {
    this.advancedMode = !this.advancedMode
    this.combinedTabTargets.forEach(el => el.classList.toggle("hidden", !this.advancedMode))
    const btn = this.advancedToggleTarget
    if (this.advancedMode) {
      btn.classList.replace("border-slate-200", "border-indigo-500")
      btn.classList.replace("text-slate-600", "text-indigo-700")
      btn.classList.add("bg-indigo-50")
    } else {
      btn.classList.replace("border-indigo-500", "border-slate-200")
      btn.classList.replace("text-indigo-700", "text-slate-600")
      btn.classList.remove("bg-indigo-50")
    }
  }

  // ── 월중입사 토글 ──
  toggleIl1Month(e) {
    const tab = e.currentTarget.dataset.tab
    const key = tab === "yearend" ? "Yearend" : "Retire"
    const isY = e.currentTarget.value === "Y"
    this[`il1Field${key}Target`].classList.toggle("hidden", !isY)
  }

  // ── 숫자 포맷 (천 단위 쉼표) ──
  formatNumber(e) {
    const raw = e.target.value.replace(/[^0-9]/g, "")
    e.target.value = raw ? Number(raw).toLocaleString("ko-KR") : ""
  }

  // ── 숫자 파싱 ──
  parseNum(str) {
    if (!str) return 0
    return parseInt(str.toString().replace(/,/g, ""), 10) || 0
  }

  // ── 계산 ──
  calculate(e) {
    const tab = e.currentTarget.dataset.tab
    const year = parseInt(e.currentTarget.dataset.year)
    const key = tab === "yearend" ? "Yearend" : "Retire"

    const wolIpRadios = this[`wolIp${key}Targets`]
    const wolIp = wolIpRadios.find(r => r.checked)?.value || "N"

    const input = {
      bonsuWol:    this.parseNum(this[`bonsuWol${key}Target`].value),
      bonsuTotal:  this.parseNum(this[`bonsuTotal${key}Target`].value),
      geunMonths:  parseInt(this[`geunMonths${key}Target`].value) || 0,
      wolIp,
      il1Month:    parseInt(this[`il1Month${key}Target`]?.value) || 1,
      ginam: {
        pension_p:   this.parseNum(this[`ginamPensionP${key}Target`].value),
        pension_g:   this.parseNum(this[`ginamPensionG${key}Target`].value),
        health_p:    this.parseNum(this[`ginamHealthP${key}Target`].value),
        health_g:    this.parseNum(this[`ginamHealthG${key}Target`].value),
        care_p:      this.parseNum(this[`ginamCareP${key}Target`].value),
        care_g:      this.parseNum(this[`ginamCareG${key}Target`].value),
        employ_p:    this.parseNum(this[`ginamEmployP${key}Target`].value),
        employ_g:    this.parseNum(this[`ginamEmployG${key}Target`].value),
        accident_g:  this.parseNum(this[`ginamAccidentG${key}Target`].value),
      },
      year,
      accidentRate: parseFloat(this[`accidentRate${key}Target`].value) / 100 || RATES[year].accident.g,
    }

    // 입력 검증
    if (!input.bonsuWol || !input.bonsuTotal || !input.geunMonths) {
      alert("보수월액, 보수총액, 근무월수는 필수 입력항목입니다.")
      return
    }

    const result = calcSettlement(input)
    this.results[tab] = { result, input }
    this[`result${key}Target`].classList.remove("hidden")
    this.renderResult(tab, result, input.ginam)

    // 합산 모드이고 둘 다 계산됐으면 합산 갱신
    if (this.advancedMode && this.results.yearend && this.results.retire) {
      this.renderCombined()
    }
  }

  // ── 결과 렌더링 ──
  renderResult(tab, result, ginam) {
    const key = tab === "yearend" ? "Yearend" : "Retire"
    const tbody = this[`resultBody${key}Target`]
    const tfoot = this[`resultFoot${key}Target`]

    const rows = this.buildRows(result, ginam)
    tbody.innerHTML = rows.body
    tfoot.innerHTML = rows.foot
  }

  buildRows(result, ginam) {
    const fmt = n => n === null ? "-" : Number(n).toLocaleString("ko-KR")
    const settlement = (val) => {
      if (val === null) return `<span class="text-slate-400 text-xs">정산없음</span>`
      if (val === undefined) return `<span class="text-slate-400 text-xs">해당없음</span>`
      const abs = Math.abs(val)
      if (val > 0) return `<span class="text-red-600 font-semibold">${fmt(abs)}원 <span class="text-xs">추가 징수</span></span>`
      if (val < 0) return `<span class="text-blue-600 font-semibold">${fmt(abs)}원 <span class="text-xs">환급</span></span>`
      return `<span class="text-slate-500">0원</span>`
    }

    const r = result
    let totalGinamP = 0, totalGinamG = 0
    let totalDecidedP = 0, totalDecidedG = 0
    let totalSettleP = 0, totalSettleG = 0

    const rows = [
      {
        label: "국민연금 (개인)", type: "p",
        monthly: r.pension.monthly.p,
        ginam: ginam?.pension_p ?? null,
        decided: null, settle: null
      },
      {
        label: "국민연금 (기관)", type: "g",
        monthly: r.pension.monthly.g,
        ginam: ginam?.pension_g ?? null,
        decided: null, settle: null
      },
      {
        label: "건강보험 (개인)", type: "p",
        monthly: r.health.monthly.p,
        ginam: ginam?.health_p ?? 0,
        decided: r.health.decided.p,
        settle: r.health.settlement.p
      },
      {
        label: "건강보험 (기관)", type: "g",
        monthly: r.health.monthly.g,
        ginam: ginam?.health_g ?? 0,
        decided: r.health.decided.g,
        settle: r.health.settlement.g
      },
      {
        label: "장기요양 (개인)", type: "p",
        monthly: r.care.monthly.p,
        ginam: ginam?.care_p ?? 0,
        decided: r.care.decided.p,
        settle: r.care.settlement.p
      },
      {
        label: "장기요양 (기관)", type: "g",
        monthly: r.care.monthly.g,
        ginam: ginam?.care_g ?? 0,
        decided: r.care.decided.g,
        settle: r.care.settlement.g
      },
      {
        label: "고용보험 (개인)", type: "p",
        monthly: r.employment.monthly.p,
        ginam: ginam?.employ_p ?? 0,
        decided: r.employment.decided.p,
        settle: r.employment.settlement.p
      },
      {
        label: "고용보험 (기관)", type: "g",
        monthly: r.employment.monthly.g,
        ginam: ginam?.employ_g ?? 0,
        decided: r.employment.decided.g,
        settle: r.employment.settlement.g
      },
      {
        label: "산재보험 (개인)", type: "p",
        monthly: null, ginam: null, decided: null, settle: undefined
      },
      {
        label: "산재보험 (기관)", type: "g",
        monthly: r.accident.monthly.g,
        ginam: ginam?.accident_g ?? 0,
        decided: r.accident.decided.g,
        settle: r.accident.settlement.g
      },
    ]

    // 합계 계산 (연금 제외, 개인/기관 합산)
    for (const row of rows) {
      if (row.label.includes("연금") || row.label.includes("산재 (개인)")) continue
      if (row.type === "p") {
        totalGinamP += row.ginam || 0
        totalDecidedP += row.decided || 0
        totalSettleP += row.settle || 0
      } else {
        totalGinamG += row.ginam || 0
        totalDecidedG += row.decided || 0
        totalSettleG += row.settle || 0
      }
    }

    const body = rows.map(row => `
      <tr class="hover:bg-slate-50">
        <td class="px-4 py-3 text-slate-700">${row.label}</td>
        <td class="px-4 py-3 text-right text-slate-600">${row.monthly === null ? '<span class="text-slate-300">-</span>' : fmt(row.monthly)}</td>
        <td class="px-4 py-3 text-right text-slate-600">${row.ginam === null ? '<span class="text-slate-300">-</span>' : fmt(row.ginam)}</td>
        <td class="px-4 py-3 text-right text-slate-600">${row.decided === null ? '<span class="text-slate-400 text-xs">정산없음</span>' : row.decided === undefined ? '<span class="text-slate-300">-</span>' : fmt(row.decided)}</td>
        <td class="px-4 py-3 text-right">${settlement(row.settle)}</td>
      </tr>
    `).join("")

    const foot = `
      <tr>
        <td class="px-4 py-3 font-bold text-slate-800">합계 (연금 제외)</td>
        <td class="px-4 py-3 text-right text-slate-400 text-xs">-</td>
        <td class="px-4 py-3 text-right font-semibold text-slate-700">${fmt(totalGinamP + totalGinamG)}</td>
        <td class="px-4 py-3 text-right font-semibold text-slate-700">${fmt(totalDecidedP + totalDecidedG)}</td>
        <td class="px-4 py-3 text-right font-bold">${settlement(totalSettleP + totalSettleG)}</td>
      </tr>
    `

    return { body, foot }
  }

  // ── 합산 렌더링 ──
  renderCombined() {
    const yr = this.results.yearend.result
    const rt = this.results.retire.result
    const yrG = this.results.yearend.input.ginam
    const rtG = this.results.retire.input.ginam

    // 합산 기납 보험료
    const combinedGinam = {
      pension_p:  (yrG.pension_p  || 0) + (rtG.pension_p  || 0),
      pension_g:  (yrG.pension_g  || 0) + (rtG.pension_g  || 0),
      health_p:   (yrG.health_p   || 0) + (rtG.health_p   || 0),
      health_g:   (yrG.health_g   || 0) + (rtG.health_g   || 0),
      care_p:     (yrG.care_p     || 0) + (rtG.care_p     || 0),
      care_g:     (yrG.care_g     || 0) + (rtG.care_g     || 0),
      employ_p:   (yrG.employ_p   || 0) + (rtG.employ_p   || 0),
      employ_g:   (yrG.employ_g   || 0) + (rtG.employ_g   || 0),
      accident_g: (yrG.accident_g || 0) + (rtG.accident_g || 0),
    }

    const combined = {
      pension: { monthly: { p: yr.pension.monthly.p, g: yr.pension.monthly.g } },
      health: {
        monthly:    { p: yr.health.monthly.p, g: yr.health.monthly.g },
        decided:    { p: yr.health.decided.p    + rt.health.decided.p,    g: yr.health.decided.g    + rt.health.decided.g },
        settlement: { p: yr.health.settlement.p + rt.health.settlement.p, g: yr.health.settlement.g + rt.health.settlement.g },
      },
      care: {
        monthly:    { p: yr.care.monthly.p, g: yr.care.monthly.g },
        decided:    { p: yr.care.decided.p    + rt.care.decided.p,    g: yr.care.decided.g    + rt.care.decided.g },
        settlement: { p: yr.care.settlement.p + rt.care.settlement.p, g: yr.care.settlement.g + rt.care.settlement.g },
      },
      employment: {
        monthly:    { p: yr.employment.monthly.p, g: yr.employment.monthly.g },
        decided:    { p: yr.employment.decided.p    + rt.employment.decided.p,    g: yr.employment.decided.g    + rt.employment.decided.g },
        settlement: { p: yr.employment.settlement.p + rt.employment.settlement.p, g: yr.employment.settlement.g + rt.employment.settlement.g },
      },
      accident: {
        monthly:    { g: yr.accident.monthly.g },
        decided:    { g: yr.accident.decided.g    + rt.accident.decided.g },
        settlement: { g: yr.accident.settlement.g + rt.accident.settlement.g },
      },
    }

    const rows = this.buildRows(combined, combinedGinam)
    this.combinedResultTarget.innerHTML = `
      <div class="overflow-x-auto rounded-xl border border-slate-200">
        <table class="w-full text-sm">
          <thead class="bg-slate-50">
            <tr>
              <th class="text-left px-4 py-3 text-slate-500 font-semibold text-xs">구분</th>
              <th class="text-right px-4 py-3 text-slate-500 font-semibold text-xs">월 보험료</th>
              <th class="text-right px-4 py-3 text-slate-500 font-semibold text-xs">기납 합계</th>
              <th class="text-right px-4 py-3 text-slate-500 font-semibold text-xs">결정 합계</th>
              <th class="text-right px-4 py-3 text-slate-500 font-semibold text-xs min-w-[120px]">정산 합계</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">${rows.body}</tbody>
          <tfoot class="bg-slate-50 border-t-2 border-slate-200">${rows.foot}</tfoot>
        </table>
      </div>
      <div class="px-4 py-3 bg-blue-50 border border-blue-100 rounded-xl mt-3">
        <p class="text-xs text-blue-700">
          <span class="font-semibold">※ 실무 안내:</span>
          <span class="text-red-600 font-semibold">추가 징수액</span>은 이번 달 급여에서 공제(-)하고,
          <span class="text-blue-600 font-semibold">환급액</span>은 급여에 더해서(+) 지급하세요.
        </p>
      </div>
    `
  }

  // ── 초기화 ──
  resetTab(e) {
    const tab = e.currentTarget.dataset.tab
    const key = tab === "yearend" ? "Yearend" : "Retire"
    this[`result${key}Target`].classList.add("hidden")
    this.results[tab] = null
    // 폼 필드 초기화
    const panel = this.panelTargets.find(p => p.dataset.panel === tab)
    if (panel) {
      panel.querySelectorAll("input[type=text], input[type=number]").forEach(el => {
        if (el.dataset.insuranceCalculatorTarget?.includes("accidentRate")) {
          el.value = "0.786"
        } else {
          el.value = ""
        }
      })
    }
  }

  // ── 엑셀 내보내기 ──
  downloadExcel(e) {
    const tab = e.currentTarget.dataset.tab
    const res = this.results[tab]
    if (!res) return

    if (typeof XLSX === "undefined") {
      alert("엑셀 라이브러리 로딩 중입니다. 잠시 후 다시 시도해 주세요.")
      return
    }

    const yearLabel = tab === "yearend" ? "2025연말정산" : "2026퇴직정산"
    const ws = this.buildExcelSheet(res.result, res.input.ginam)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, yearLabel)
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "")
    XLSX.writeFile(wb, `4대보험정산_${yearLabel}_${today}.xlsx`)
  }

  // ── 엑셀 시트 데이터 생성 (숫자값 보존) ──
  buildExcelSheet(result, ginam) {
    const r = result
    const g = ginam || {}
    const NA = "해당없음"
    const NO_SETTLE = "정산없음"
    const settleTxt = (val) => {
      if (val === null || val === undefined) return NO_SETTLE
      return val
    }

    const rows = [
      ["구분", "월 보험료", "기납 보험료", "결정 보험료", "정산 보험료", "비고"],
      ["국민연금 (개인)", r.pension.monthly.p, g.pension_p ?? NA, NO_SETTLE, NO_SETTLE, "정산 없음"],
      ["국민연금 (기관)", r.pension.monthly.g, g.pension_g ?? NA, NO_SETTLE, NO_SETTLE, "정산 없음"],
      ["건강보험 (개인)", r.health.monthly.p,     g.health_p  ?? 0, r.health.decided.p,     settleTxt(r.health.settlement.p), ""],
      ["건강보험 (기관)", r.health.monthly.g,     g.health_g  ?? 0, r.health.decided.g,     settleTxt(r.health.settlement.g), ""],
      ["장기요양 (개인)", r.care.monthly.p,       g.care_p    ?? 0, r.care.decided.p,       settleTxt(r.care.settlement.p), ""],
      ["장기요양 (기관)", r.care.monthly.g,       g.care_g    ?? 0, r.care.decided.g,       settleTxt(r.care.settlement.g), ""],
      ["고용보험 (개인)", r.employment.monthly.p, g.employ_p  ?? 0, r.employment.decided.p, settleTxt(r.employment.settlement.p), ""],
      ["고용보험 (기관)", r.employment.monthly.g, g.employ_g  ?? 0, r.employment.decided.g, settleTxt(r.employment.settlement.g), ""],
      ["산재보험 (개인)", NA,                     NA,               NA,                     NA, "개인 부담 없음"],
      ["산재보험 (기관)", r.accident.monthly.g,   g.accident_g ?? 0, r.accident.decided.g,  settleTxt(r.accident.settlement.g), ""],
    ]

    // 합계 행 (연금·산재개인 제외)
    const ginamSum = (g.health_p || 0) + (g.health_g || 0) + (g.care_p || 0) + (g.care_g || 0)
      + (g.employ_p || 0) + (g.employ_g || 0) + (g.accident_g || 0)
    const sumOf = (key) => [r.health, r.care, r.employment].reduce((s, ins) => s + (ins[key]?.p || 0) + (ins[key]?.g || 0), 0)
      + (r.accident[key]?.g || 0)
    rows.push(["합계 (연금 제외)", "", ginamSum, sumOf("decided"), sumOf("settlement"), ""])

    const ws = XLSX.utils.aoa_to_sheet(rows)

    // 열 너비 설정
    ws["!cols"] = [{ wch: 18 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 16 }, { wch: 18 }]

    // 정산 보험료 열(E) — 양수=추가징수, 음수=환급 메모 없음, 숫자 그대로
    return ws
  }
}
