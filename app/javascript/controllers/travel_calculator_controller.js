import { Controller } from "@hotwired/stimulus"

// 여비계산기 Stimulus 컨트롤러
// turbo:load 이벤트 리스너 중복 등록 문제 해결 (Stimulus lifecycle이 자동 관리)
export default class extends Controller {
  static targets = [
    "form", "departure", "destination", "startDate", "endDate",
    "accommodation", "dateError", "resultPlaceholder", "resultContent",
    "totalAmount", "summaryRoute", "summaryDays", "summaryTransport",
    "fareDesc", "fareAmount", "accommodationRow", "accommodationDesc",
    "accommodationAmount", "mealDesc", "mealAmount", "dailyDesc", "dailyAmount"
  ]

  // ── 도시 좌표 데이터 ──
  static cities = {
    '서울':[37.5665,126.978],'부산':[35.1796,129.0756],'대구':[35.8714,128.6014],
    '인천':[37.4563,126.7052],'광주':[35.1595,126.8526],'대전':[36.3504,127.3845],
    '울산':[35.5384,129.3114],'세종':[36.48,127.26],'수원':[37.2636,127.0286],
    '창원':[35.228,128.6811],'전주':[35.8242,127.148],'청주':[36.6424,127.489],
    '춘천':[37.8813,127.7298],'강릉':[37.7519,128.8761],'제주':[33.4996,126.5312],
    '여수':[34.7604,127.6622],'포항':[36.019,129.3435],'목포':[34.8118,126.3922],
    '진주':[35.1802,128.1076],'원주':[37.3422,127.9202],'천안':[36.8151,127.1139],
    '안동':[36.5684,128.7294],'경주':[35.8562,129.2247],'속초':[38.207,128.5918],
    '평택':[36.992,127.089],'구미':[36.1197,128.3444],'충주':[36.991,127.9259],
    '군산':[35.9676,126.7369],'익산':[35.9483,126.9577],'순천':[34.9506,127.4874],
    '김포':[37.6152,126.7156]
  }

  // ── KTX/SRT 편도 일반실 (원) ──
  static trainFares = {
    '서울-부산':59800,'서울-대전':23700,'서울-대구':43500,'서울-울산':55500,
    '서울-광주':41500,'서울-목포':48200,'서울-여수':51900,'서울-강릉':27600,
    '서울-포항':48200,'서울-경주':52000,'서울-창원':52000,'서울-진주':48000,
    '서울-천안':14800,'서울-전주':32000,'서울-청주':16000,'서울-원주':16000,
    '서울-안동':32000,'서울-순천':46000,
    '대전-부산':36800,'대전-대구':21000,'대전-광주':22000,'대전-전주':13000,
    '대구-부산':16200,'대구-울산':14000,'대구-포항':14000,'대구-경주':12000,
    '부산-울산':8200
  }

  // ── 고속/시외버스 편도 일반 (원) ──
  static busFares = {
    '서울-부산':23800,'서울-대전':9400,'서울-대구':18500,'서울-광주':18700,
    '서울-울산':25000,'서울-전주':13000,'서울-강릉':17500,'서울-춘천':6800,
    '서울-목포':24300,'서울-여수':23900,'서울-진주':22700,'서울-포항':22800,
    '서울-창원':24500,'서울-천안':5500,'서울-청주':8000,'서울-원주':8300,
    '서울-안동':17600,'서울-속초':16500,'서울-경주':22100,'서울-인천':2500,
    '서울-세종':10200,'서울-수원':3000,'서울-평택':5500,'서울-충주':10000,
    '서울-군산':14500,'서울-익산':13500,'서울-순천':22000,'서울-구미':16000,
    '서울-김포':2000,
    '대전-부산':17000,'대전-대구':10500,'대전-광주':12000,'대전-전주':6500,
    '대전-청주':3000,'대전-세종':2500,'대전-천안':4000,
    '대구-부산':8500,'대구-울산':7000,'대구-포항':6500,'대구-경주':4500,
    '대구-안동':7500,'대구-구미':4000,
    '부산-울산':5500,'부산-경주':7000,'부산-창원':4500,'부산-진주':9000,
    '광주-전주':7000,'광주-목포':6500,'광주-여수':12000,'광주-순천':9000
  }

  // ── 항공 왕복 이코노미 평균 (원, 이미 왕복) ──
  static flightFares = {
    '서울-제주':130000,'서울-부산':110000,'서울-울산':120000,'서울-광주':100000,
    '서울-여수':120000,'서울-포항':110000,'부산-제주':100000,'대구-제주':110000,
    '청주-제주':100000,'광주-제주':90000,'여수-제주':80000,'울산-제주':100000,
    '인천-제주':130000
  }

  // ── 여비 정액 (공무원여비규정 별표2, 2026.01.02 시행 기준) ──
  static accommodationByRegion = { seoul: 70000, metro: 60000, other: 50000 }
  static mealRate = 25000
  static dailyRate = 25000
  static transportNames = { train: 'KTX', bus: '고속버스', car: '자차', flight: '항공' }

  connect() {
    this._setDefaultDates()
    this._initTransportUI()
  }

  // ── 날짜 초기화 ──
  _setDefaultDates() {
    const today = new Date()
    this.startDateTarget.value = this._toLocalDateStr(today)
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    this.endDateTarget.value = this._toLocalDateStr(tomorrow)
  }

  _toLocalDateStr(date) {
    const yyyy = date.getFullYear()
    const mm = String(date.getMonth() + 1).padStart(2, '0')
    const dd = String(date.getDate()).padStart(2, '0')
    return `${yyyy}-${mm}-${dd}`
  }

  // ── 교통수단 선택 UI ──
  _initTransportUI() {
    this.element.querySelectorAll('.transport-label').forEach(label => {
      const radio = label.querySelector('input[type="radio"]')
      if (radio.checked) {
        label.classList.add('border-indigo-500', 'bg-indigo-50')
        label.querySelector('.transport-icon').classList.add('text-indigo-500')
      }
    })
  }

  selectTransport(event) {
    const labels = this.element.querySelectorAll('.transport-label')
    labels.forEach(l => {
      l.classList.remove('border-indigo-500', 'bg-indigo-50')
      const icon = l.querySelector('.transport-icon')
      icon.classList.remove('text-indigo-500')
      icon.classList.add('text-slate-400')
    })
    const label = event.currentTarget
    label.classList.add('border-indigo-500', 'bg-indigo-50')
    const icon = label.querySelector('.transport-icon')
    icon.classList.remove('text-slate-400')
    icon.classList.add('text-indigo-500')
  }

  // ── 국외 출장 토글 ──
  toggleTripType(event) {
    const existingNotice = document.getElementById('international-notice')
    if (event.target.value === 'international') {
      if (!existingNotice) {
        const notice = document.createElement('div')
        notice.id = 'international-notice'
        notice.className = 'p-4 bg-amber-50 border border-amber-200 rounded-xl text-sm text-amber-800 flex items-start gap-2'
        notice.innerHTML = '<span class="material-symbols-outlined text-amber-600 flex-shrink-0 mt-0.5" style="font-size:18px">info</span><div><strong>국외 출장 계산은 현재 지원 예정입니다.</strong><br>국내 출장을 선택하시거나, 국외 여비는 공무원여비규정 별표 3 · 4를 참조해주세요.</div>'
        const submitBtn = this.formTarget.querySelector('button[type="submit"]')
        submitBtn.parentNode.insertBefore(notice, submitBtn)
      }
    } else {
      if (existingNotice) existingNotice.remove()
    }
  }

  // ── 폼 제출 (계산 실행) ──
  calculate(event) {
    event.preventDefault()

    const departure = this.departureTarget.value
    const destination = this.destinationTarget.value
    const startDate = new Date(this.startDateTarget.value)
    const endDate = new Date(this.endDateTarget.value)
    const transport = this.formTarget.querySelector('input[name="transport"]:checked').value
    const needAccommodation = this.accommodationTarget.checked

    const days = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1
    const nights = days - 1

    if (days < 1) {
      this.dateErrorTarget.textContent = '도착일은 출발일 이후여야 합니다.'
      this.dateErrorTarget.classList.remove('hidden')
      return
    }
    this.dateErrorTarget.classList.add('hidden')

    const c1 = this._matchCity(departure)
    const c2 = this._matchCity(destination)
    let fareResult
    if (c1 && c2) {
      fareResult = this._calcFare(transport, c1, c2)
    } else {
      fareResult = { fare: 0, estimated: true, desc: '목록에서 도시를 선택해주세요', unavailable: true }
    }

    const regionType = this._getRegionType(destination)
    const C = this.constructor
    const accRate = C.accommodationByRegion[regionType]
    const accAmount = needAccommodation ? accRate * nights : 0
    const mealAmount = C.mealRate * days
    const dailyAmount = C.dailyRate * days
    const totalAmount = fareResult.fare + accAmount + mealAmount + dailyAmount

    // 결과 표시
    this.resultPlaceholderTarget.classList.add('hidden')
    this.resultContentTarget.classList.remove('hidden')

    this.totalAmountTarget.textContent = '\u20A9 ' + totalAmount.toLocaleString()
    this.summaryRouteTarget.textContent = departure + ' \u2192 ' + destination
    this.summaryDaysTarget.textContent = nights > 0 ? nights + '\uBC15 ' + days + '\uC77C' : '\uB2F9\uC77C'
    this.summaryTransportTarget.textContent = C.transportNames[transport]

    // 운임
    let fareDesc = fareResult.desc + ' (' + departure + ' \u2194 ' + destination + ')'
    if (fareResult.estimated && !fareResult.unavailable) fareDesc = '\u2248 ' + fareDesc
    if (fareResult.unavailable) fareDesc = fareResult.desc
    this.fareDescTarget.textContent = fareDesc
    this.fareAmountTarget.textContent = fareResult.unavailable ? '-' : '\u20A9 ' + fareResult.fare.toLocaleString()

    // 숙박비
    const regionNames = { seoul: '서울', metro: '광역시', other: '기타지역' }
    if (needAccommodation && nights > 0) {
      this.accommodationRowTarget.classList.remove('hidden')
      this.accommodationDescTarget.textContent = accRate.toLocaleString() + '원(' + regionNames[regionType] + ') \u00D7 ' + nights + '\uBC15'
      this.accommodationAmountTarget.textContent = '\u20A9 ' + accAmount.toLocaleString()
    } else {
      this.accommodationRowTarget.classList.add('hidden')
    }

    // 식비/일비
    this.mealDescTarget.textContent = C.mealRate.toLocaleString() + '원 \u00D7 ' + days + '\uC77C'
    this.mealAmountTarget.textContent = '\u20A9 ' + mealAmount.toLocaleString()
    this.dailyDescTarget.textContent = C.dailyRate.toLocaleString() + '원 \u00D7 ' + days + '\uC77C'
    this.dailyAmountTarget.textContent = '\u20A9 ' + dailyAmount.toLocaleString()

    if (window.innerWidth < 1024) {
      this.resultContentTarget.scrollIntoView({ behavior: 'smooth' })
    }
  }

  // ── 유틸리티 함수 ──
  _haversine(lat1, lon1, lat2, lon2) {
    const R = 6371, rad = Math.PI / 180
    const dLat = (lat2-lat1)*rad, dLon = (lon2-lon1)*rad
    const a = Math.sin(dLat/2)**2 + Math.cos(lat1*rad)*Math.cos(lat2*rad)*Math.sin(dLon/2)**2
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  }

  _getRoadDist(c1, c2) {
    const cities = this.constructor.cities
    const p1 = cities[c1], p2 = cities[c2]
    if (!p1 || !p2) return null
    return Math.round(this._haversine(p1[0],p1[1],p2[0],p2[1]) * 1.3)
  }

  _matchCity(input) {
    const cities = this.constructor.cities
    input = input.trim()
    if (!input) return null
    if (cities[input]) return input
    for (const c of Object.keys(cities)) { if (input.startsWith(c)) return c }
    for (const c of Object.keys(cities)) { if (c.startsWith(input)) return c }
    for (const c of Object.keys(cities)) { if (input.includes(c) || c.includes(input)) return c }
    return null
  }

  _lookupFare(table, c1, c2) {
    return table[c1+'-'+c2] || table[c2+'-'+c1] || null
  }

  _getRegionType(dest) {
    const metro = ['부산','대구','인천','광주','대전','울산','세종']
    if (dest.includes('서울')) return 'seoul'
    for (const city of metro) { if (dest.includes(city)) return 'metro' }
    return 'other'
  }

  _calcFare(transport, c1, c2) {
    const C = this.constructor
    const dist = this._getRoadDist(c1, c2)
    if (!dist || dist < 1) return { fare: 0, estimated: true, desc: '동일 지역' }
    const isIsland = (c1 === '제주' || c2 === '제주')
    let fare, estimated = false, desc

    if (transport === 'train') {
      if (isIsland) return { fare: 0, desc: '제주는 철도 노선이 없습니다', unavailable: true }
      const known = this._lookupFare(C.trainFares, c1, c2)
      if (known) { fare = known * 2; desc = 'KTX 왕복 일반실' }
      else { fare = Math.round(dist*140/100)*100*2; estimated = true; desc = 'KTX 추정 왕복' }
    } else if (transport === 'bus') {
      if (isIsland) return { fare: 0, desc: '제주는 시외버스 노선이 없습니다', unavailable: true }
      const known = this._lookupFare(C.busFares, c1, c2)
      if (known) { fare = known * 2; desc = '고속버스 왕복 일반' }
      else { fare = Math.round(dist*57/100)*100*2; estimated = true; desc = '고속버스 추정 왕복' }
    } else if (transport === 'car') {
      if (isIsland) return { fare: 0, desc: '제주는 자차 이동 불가', unavailable: true }
      fare = Math.round(dist*2*177/1000)*1000
      estimated = true
      desc = '자차 왕복 약 '+(dist*2).toLocaleString()+'km (유류비+통행료)'
    } else if (transport === 'flight') {
      const known = this._lookupFare(C.flightFares, c1, c2)
      if (known) { fare = known; desc = '항공 왕복 이코노미' }
      else if (isIsland) { fare = 120000; estimated = true; desc = '제주 항공 추정 왕복' }
      else { fare = Math.min(200000, Math.max(80000, Math.round(dist*300/1000)*1000)); estimated = true; desc = '항공 추정 왕복' }
    }
    return { fare: fare||0, estimated, desc }
  }
}
