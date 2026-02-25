/**
 * 4대보험 정산 계산 엔진
 * ES Module 형식. UI/Rails 코드 의존 없음.
 */

// ── T01: 유틸리티 ─────────────────────────────────────────────────────────

/**
 * 엑셀 ROUNDDOWN 동일 동작.
 * digits = -1 → 10원 단위 내림 (1원 버림)
 * 음수 입력 시 -∞ 방향(더 작은 값)으로 절사.
 *
 * @param {number} value
 * @param {number} digits  음수: Math.pow(10, -digits) 단위 버림
 * @returns {number}
 */
export function rounddown(value, digits) {
  const factor = Math.pow(10, -digits);
  return Math.floor(value / factor) * factor;
}

// ── T02: 보험료율 상수 ────────────────────────────────────────────────────

/**
 * 연도별 4대보험 요율표
 * pension.p   : 근로자 부담 국민연금율
 * pension.g   : 기관 부담 국민연금율
 * health.p/g  : 건강보험율 (근로자/기관, 동일)
 * care.numerator/denominator : 요양보험 비율 계산용
 *   → 요양비율 = numerator / denominator  (건강보험료 대비 요양보험료 비율)
 * employment.p      : 근로자 실업급여율
 * employment.g_base : 기관 실업급여율
 * employment.g_stable : 기관 고용안정율
 * accident.g : 산재보험율 (기관 전담)
 */
export const RATES = {
  2025: {
    pension:    { p: 0.045,   g: 0.0475  },
    health:     { p: 0.03545, g: 0.03545 },
    care:       { numerator: 0.9182, denominator: 7.09 },
    employment: { p: 0.009,   g_base: 0.009, g_stable: 0.0085 },
    accident:   { g: 0.00786 }
  },
  2026: {
    pension:    { p: 0.0475,  g: 0.0475  },
    health:     { p: 0.03595, g: 0.03595 },
    care:       { numerator: 0.9448, denominator: 7.19 },
    employment: { p: 0.009,   g_base: 0.009, g_stable: 0.0085 },
    accident:   { g: 0.00786 }
  }
};

// ── T03: 연금보험료 ───────────────────────────────────────────────────────

/**
 * 국민연금 월보험료 계산. 연금은 연간 정산 없음.
 *
 * @param {number} bonsuWol  보수월액
 * @param {number} year      2025|2026
 * @returns {{ monthly: { p: number, g: number } }}
 */
export function calcPension(bonsuWol, year) {
  const rate = RATES[year].pension;
  return {
    monthly: {
      p: rounddown(bonsuWol * rate.p, -1),
      g: rounddown(bonsuWol * rate.g, -1),
    }
  };
}

// ── T04/T05: 건강보험료 ───────────────────────────────────────────────────

/**
 * 건강보험료 계산 (월중입사 Y/N 통합).
 *
 * [월중입사=N]
 *   월보험료(p) = rounddown(보수월액 × health.p, -1)
 *   결정(p)     = rounddown(보수총액/근무월수 × health.p, -1) × 근무월수
 *   결정(g)     = 결정(p)
 *
 * [월중입사=Y]
 *   월평균      = rounddown(보수총액/근무월수, -1)
 *   결정(p)     = rounddown(월평균 × health.p, -1) × il1Month
 *   결정(g)     = 결정(p)
 *
 * 정산 = 결정 - 기납
 *
 * @param {number} bonsuWol    보수월액
 * @param {number} bonsuTotal  보수총액
 * @param {number} geunMonths  근무월수
 * @param {'Y'|'N'} wolIp      월중입사 여부
 * @param {number} il1Month    1일 포함 근무월수 (wolIp=Y 시 사용)
 * @param {number} ginamP      기납보험료(개인)
 * @param {number} ginamG      기납보험료(기관)
 * @param {number} year        2025|2026
 * @returns {{ monthly:{p,g}, decided:{p,g}, settlement:{p,g} }}
 */
export function calcHealth(bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month, ginamP, ginamG, year) {
  const rate = RATES[year].health;

  // 월보험료 (보수월액 기준)
  const monthlyP = rounddown(bonsuWol * rate.p, -1);
  const monthlyG = rounddown(bonsuWol * rate.g, -1);

  let decidedP, decidedG;

  if (wolIp === 'Y') {
    // 월중입사=Y: 월평균 먼저 rounddown 후 요율 적용
    const wolPyeong = rounddown(bonsuTotal / geunMonths, -1);
    decidedP = rounddown(wolPyeong * rate.p, -1) * il1Month;
    decidedG = decidedP;
  } else {
    // 월중입사=N: 월평균에 요율 적용 후 rounddown × 근무월수
    const wolGijun = rounddown(bonsuTotal / geunMonths * rate.p, -1);
    decidedP = wolGijun * geunMonths;
    decidedG = decidedP;
  }

  return {
    monthly:    { p: monthlyP,           g: monthlyG },
    decided:    { p: decidedP,           g: decidedG },
    settlement: { p: decidedP - ginamP,  g: decidedG - ginamG },
  };
}

// ── T06: 요양보험료 ───────────────────────────────────────────────────────

/**
 * 요양보험료 계산.
 * 요양비율 = care.numerator / care.denominator
 *   (건강보험료 대비 요양보험료의 비율)
 *
 * [월중입사=N]
 *   월요양(p)  = rounddown(healthMonthlyP × 요양비율, -1)
 *   결정(p)    = rounddown(healthMonthlyP × 요양비율, -1) × 근무월수
 *
 * [월중입사=Y]
 *   결정(p)    = rounddown(healthMonthlyP × 요양비율, -1) × il1Month
 *   ※ healthMonthlyP는 호출 전에 이미 rounddown 된 값
 *
 * 결정(g) = 결정(p)
 * 정산    = 결정 - 기납
 *
 * @param {number} bonsuWol       보수월액
 * @param {number} bonsuTotal     보수총액
 * @param {number} geunMonths     근무월수
 * @param {'Y'|'N'} wolIp         월중입사 여부
 * @param {number} il1Month       1일 포함 근무월수 (wolIp=Y 시)
 * @param {number} ginamP         기납(개인)
 * @param {number} ginamG         기납(기관)
 * @param {number} healthMonthlyP 건강보험료 월기준액(개인) — 이미 rounddown 된 값
 * @param {number} healthDecidedP 건강보험료 결정액(개인) — 참고용
 * @param {number} year           2025|2026
 * @returns {{ monthly:{p,g}, decided:{p,g}, settlement:{p,g} }}
 */
export function calcCare(
  bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month,
  ginamP, ginamG,
  healthMonthlyP, healthDecidedP,
  year
) {
  const care = RATES[year].care;
  const ratio = care.numerator / care.denominator;

  // 월요양 단가 (healthMonthlyP 기준)
  const wolCareUnit = rounddown(healthMonthlyP * ratio, -1);

  // 월보험료: 보수월액 기준 건강 월보험료로 계산
  const healthRate = RATES[year].health;
  const healthMonthly = rounddown(bonsuWol * healthRate.p, -1);
  const monthlyP = rounddown(healthMonthly * ratio, -1);
  const monthlyG = monthlyP;

  let decidedP;
  if (wolIp === 'Y') {
    decidedP = wolCareUnit * il1Month;
  } else {
    decidedP = wolCareUnit * geunMonths;
  }
  const decidedG = decidedP;

  return {
    monthly:    { p: monthlyP,           g: monthlyG },
    decided:    { p: decidedP,           g: decidedG },
    settlement: { p: decidedP - ginamP,  g: decidedG - ginamG },
  };
}

// ── T07: 고용보험료 ───────────────────────────────────────────────────────

/**
 * 고용보험료 계산.
 *
 * 월보험료(p) = rounddown(보수월액 × 0.9%, -1)
 * 월보험료(g) = rounddown(보수월액 × (0.9% + 0.85%), -1)
 *
 * 결정(p)    = rounddown(보수총액 × 0.9%, -1)
 * 결정(g)    = rounddown(보수총액 × 0.9%, -1) + rounddown(보수총액 × 0.85%, -1)
 * 정산       = 결정 - 기납
 *
 * ※ 고용보험은 wolIp 구분 없이 보수총액 기준 일괄 계산
 *
 * @param {number} bonsuWol    보수월액
 * @param {number} bonsuTotal  보수총액
 * @param {number} geunMonths  근무월수 (참고용, 수식에 직접 사용 안 함)
 * @param {'Y'|'N'} wolIp      월중입사 (미사용, 시그니처 통일용)
 * @param {number} il1Month    (미사용)
 * @param {number} ginamP      기납(개인)
 * @param {number} ginamG      기납(기관)
 * @param {number} year        2025|2026
 * @returns {{ monthly:{p,g}, decided:{p,g}, settlement:{p,g} }}
 */
export function calcEmployment(
  bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month,
  ginamP, ginamG, year
) {
  const rate = RATES[year].employment;

  const monthlyP = rounddown(bonsuWol * rate.p, -1);
  const monthlyG = rounddown(bonsuWol * (rate.g_base + rate.g_stable), -1);

  const decidedP = rounddown(bonsuTotal * rate.p, -1);
  const decidedG = rounddown(bonsuTotal * rate.g_base, -1)
                 + rounddown(bonsuTotal * rate.g_stable, -1);

  return {
    monthly:    { p: monthlyP,           g: monthlyG },
    decided:    { p: decidedP,           g: decidedG },
    settlement: { p: decidedP - ginamP,  g: decidedG - ginamG },
  };
}

// ── T08: 산재보험료 ───────────────────────────────────────────────────────

/**
 * 산재보험료 계산. 개인 부담 없음 (기관 전담).
 *
 * 월보험료(g) = rounddown(보수월액 × accident.g, -1)
 * 결정(g)     = rounddown(보수총액 × accident.g, -1)
 * 정산(g)     = 결정(g) - 기납
 *
 * @param {number} bonsuWol    보수월액
 * @param {number} bonsuTotal  보수총액
 * @param {number} geunMonths  근무월수 (미사용)
 * @param {'Y'|'N'} wolIp      (미사용)
 * @param {number} il1Month    (미사용)
 * @param {number} ginamG      기납(기관)
 * @param {number} year        2025|2026
 * @returns {{ monthly:{g}, decided:{g}, settlement:{g} }}
 */
export function calcAccident(
  bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month,
  ginamG, year
) {
  const rate = RATES[year].accident;

  const monthlyG  = rounddown(bonsuWol  * rate.g, -1);
  const decidedG  = rounddown(bonsuTotal * rate.g, -1);

  return {
    monthly:    { g: monthlyG },
    decided:    { g: decidedG },
    settlement: { g: decidedG - ginamG },
  };
}

// ── T09: 정산 통합 함수 ───────────────────────────────────────────────────

/**
 * 4대보험 정산 통합 계산.
 *
 * 입력 input 구조:
 * {
 *   bonsuWol:    number,         보수월액
 *   bonsuTotal:  number,         보수총액 (건강/요양 기준)
 *   bonsuTotalEmploy?: number,   보수총액 (고용/산재 기준, 미지정 시 bonsuTotal 사용)
 *   geunMonths:  number,         근무월수
 *   wolIp:       'Y'|'N',
 *   il1Month:    number,         1일 포함 근무월수 (wolIp=Y 시)
 *   ginam: {
 *     pension_p, pension_g,
 *     health_p, health_g,
 *     care_p, care_g,
 *     employ_p, employ_g,
 *     accident_g
 *   },
 *   year: 2025|2026
 * }
 *
 * @param {object} input
 * @returns {object}
 */
export function calcSettlement(input) {
  const {
    bonsuWol, bonsuTotal, geunMonths,
    wolIp, il1Month, ginam, year
  } = input;

  // 고용/산재 보수총액: 별도 필드 없으면 bonsuTotal 사용
  const bonsuTotalEmploy = input.bonsuTotalEmploy ?? bonsuTotal;

  // ① 연금
  const pension = calcPension(bonsuWol, year);

  // ② 건강
  const health = calcHealth(
    bonsuWol, bonsuTotal, geunMonths,
    wolIp, il1Month,
    ginam.health_p, ginam.health_g,
    year
  );

  // ③ 요양 (건강 월기준액 필요)
  //    월기준액 = 건강 결정에 사용된 단위 금액
  //    - N케이스: rounddown(bonsuTotal/geunMonths × health.p, -1)
  //    - Y케이스: rounddown(rounddown(bonsuTotal/geunMonths, -1) × health.p, -1)
  const healthRate = RATES[year].health;
  let healthMonthlyBase;
  if (wolIp === 'Y') {
    const wolPyeong = rounddown(bonsuTotal / geunMonths, -1);
    healthMonthlyBase = rounddown(wolPyeong * healthRate.p, -1);
  } else {
    healthMonthlyBase = rounddown(bonsuTotal / geunMonths * healthRate.p, -1);
  }

  const care = calcCare(
    bonsuWol, bonsuTotal, geunMonths,
    wolIp, il1Month,
    ginam.care_p, ginam.care_g,
    healthMonthlyBase, health.decided.p,
    year
  );

  // ④ 고용
  const employment = calcEmployment(
    bonsuWol, bonsuTotalEmploy, geunMonths,
    wolIp, il1Month,
    ginam.employ_p, ginam.employ_g,
    year
  );

  // ⑤ 산재
  const accident = calcAccident(
    bonsuWol, bonsuTotalEmploy, geunMonths,
    wolIp, il1Month,
    ginam.accident_g,
    year
  );

  return { pension, health, care, employment, accident };
}
