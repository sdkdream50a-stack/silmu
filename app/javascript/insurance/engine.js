/**
 * 4대보험 정산 계산 엔진
 * ES Module 형식. UI/Rails 코드 의존 없음.
 */

// ── T01: 유틸리티 ─────────────────────────────────────────────────────────

/**
 * 엑셀 ROUNDDOWN 동일 동작.
 * digits = -1 → 10원 단위 내림 (1원 버림)
 * 음수 입력 시 -∞ 방향(더 작은 값)으로 절사.
 */
export function rounddown(value, digits) {
  const factor = Math.pow(10, -digits);
  return Math.floor(value / factor) * factor;
}

// ── T02: 보험료율 상수 ────────────────────────────────────────────────────

/**
 * 연도별 4대보험 요율표
 *
 * pension.ceiling/floor : 기준소득월액 상·하한선의 "연초 기준" 기본값.
 *   상·하한은 매년 7월에 바뀌므로 달력연도 하나로 고정하면 하반기에 틀린다 →
 *   실제 적용값은 PENSION_BRACKETS에서 기준일로 찾는다.
 *
 * [수정 이력]
 *   2026-03-05: RATES[2025].pension.g 0.0475 → 0.045 수정
 *               (국민연금 9.5% 인상은 2026년부터 적용. 2025년은 여전히 9% = 4.5%+4.5%)
 *               pension 상·하한선 추가
 *   2026-08-04: 상·하한을 7월 개정 주기에 맞춰 PENSION_BRACKETS로 분리.
 *               2026.7~2027.6 상한 6,590,000 / 하한 410,000 (보건복지부 고시) 반영.
 */

/**
 * 국민연금 기준소득월액 상·하한 적용 구간. from 이상이면 그 구간을 쓴다(최신순 탐색).
 * 출처: 「국민연금 기준소득월액 하한액과 상한액」 보건복지부 고시. 매년 7월 1일 적용.
 */
export const PENSION_BRACKETS = [
  { from: "2026-07-01", to: "2027-06-30", ceiling: 6_590_000, floor: 410_000 },
  { from: "2025-07-01", to: "2026-06-30", ceiling: 6_370_000, floor: 400_000 },
  { from: "2024-07-01", to: "2025-06-30", ceiling: 6_170_000, floor: 390_000 }
];

/**
 * 기준일에 적용되는 상·하한을 돌려준다. 구간을 못 찾으면 null.
 * toISOString은 UTC로 바꿔버려 KST 자정~09시에 전날로 판정된다(7/1 00:00 KST → 6/30).
 * 로컬 달력 기준으로 YYYY-MM-DD를 만든다.
 */
export function pensionBracket(refDate) {
  const d = refDate instanceof Date ? refDate : new Date(refDate);
  const iso = typeof refDate === "string" && /^\d{4}-\d{2}-\d{2}/.test(refDate)
    ? refDate.slice(0, 10)
    : `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  // 고시되지 않은 미래 날짜(예: 2027-01-01)를 최신 구간으로 계산하면 확인되지 않은 값을 내놓게 된다.
  // 구간의 적용 종료일을 넘어서면 null을 돌려주고 호출부가 차단하게 한다.
  return PENSION_BRACKETS.find((b) => iso >= b.from && iso <= b.to) || null;
}
export const RATES = {
  2025: {
    pension:    { p: 0.045,   g: 0.045,   ceiling: 6_170_000, floor: 390_000 },
    health:     { p: 0.03545, g: 0.03545 },
    care:       { numerator: 0.9182, denominator: 7.09 },
    employment: { p: 0.009,   g_base: 0.009, g_stable: 0.0085 },
    accident:   { g: 0.00786 }
  },
  2026: {
    pension:    { p: 0.0475,  g: 0.0475,  ceiling: 6_370_000, floor: 400_000 },
    health:     { p: 0.03595, g: 0.03595 },
    care:       { numerator: 0.9448, denominator: 7.19 },
    employment: { p: 0.009,   g_base: 0.009, g_stable: 0.0085 },
    accident:   { g: 0.00786 }
  }
};

// ── T03: 연금보험료 ───────────────────────────────────────────────────────

/**
 * 국민연금 월보험료 계산. 연금은 연간 정산 없음.
 * 기준소득월액 상·하한선 자동 적용.
 *
 * @param {number} bonsuWol  보수월액 (입력값)
 * @param {number} year      2025|2026
 * @param {Date|string} [refDate]  상·하한 적용 기준일. 상·하한은 매년 7월에 바뀌므로
 *   특정 시점 기준으로 계산하려면 이 값을 준다. 생략하면 RATES[year]의 연초 기준값을 쓴다
 *   (기존 호출부 호환 — year는 정산연도이지 적용시점이 아니다).
 * @returns {{ monthly: { p, g }, cappedWol, isOverCeiling, isUnderFloor }}
 */
export function calcPension(bonsuWol, year, refDate = null) {
  const rate = RATES[year].pension;
  // 기준일을 줬는데 해당 구간이 없으면(=고시 범위 밖) 조용히 연초값으로 떨어뜨리지 않는다.
  const bracket = refDate ? pensionBracket(refDate) : rate;
  if (!bracket) {
    throw new RangeError(
      `국민연금 기준소득월액 상·하한이 고시된 기간(${PENSION_BRACKETS[PENSION_BRACKETS.length - 1].from} ~ ` +
      `${PENSION_BRACKETS[0].to}) 밖의 기준일입니다: ${refDate}`
    );
  }
  const ceiling = bracket.ceiling;
  const floor = bracket.floor;
  const cappedWol = Math.min(Math.max(bonsuWol, floor), ceiling);
  return {
    monthly: {
      p: rounddown(cappedWol * rate.p, -1),
      g: rounddown(cappedWol * rate.g, -1),
    },
    cappedWol,
    isOverCeiling: bonsuWol > ceiling,
    isUnderFloor:  bonsuWol < floor,
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
 *   결정(p)     = rounddown(월평균 × health.p, -1) × 산정월수(il1Month)
 *   결정(g)     = 결정(p)
 *
 * 정산 = 결정 - 기납
 *
 * @param {number} bonsuWol    보수월액
 * @param {number} bonsuTotal  보수총액
 * @param {number} geunMonths  근무월수
 * @param {'Y'|'N'} wolIp      월중입사 여부
 * @param {number} il1Month    산정월수 (wolIp=Y 시: 보험료 실제 부과 개월수)
 * @param {number} ginamP      기납보험료(개인)
 * @param {number} ginamG      기납보험료(기관)
 * @param {number} year        2025|2026
 */
export function calcHealth(bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month, ginamP, ginamG, year) {
  const rate = RATES[year].health;

  const monthlyP = rounddown(bonsuWol * rate.p, -1);
  const monthlyG = rounddown(bonsuWol * rate.g, -1);

  let decidedP, decidedG;

  if (wolIp === 'Y') {
    const wolPyeong = rounddown(bonsuTotal / geunMonths, -1);
    decidedP = rounddown(wolPyeong * rate.p, -1) * il1Month;
    decidedG = decidedP;
  } else {
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
 *   (건강보험료 대비 요양보험료의 비율, 예: 0.9182/7.09 ≈ 12.95%)
 *
 * [월중입사=N]
 *   월요양(p)  = rounddown(healthMonthlyP × 요양비율, -1)
 *   결정(p)    = rounddown(healthMonthlyP × 요양비율, -1) × 근무월수
 *
 * [월중입사=Y]
 *   결정(p)    = rounddown(healthMonthlyP × 요양비율, -1) × il1Month
 *
 * 결정(g) = 결정(p)
 * 정산    = 결정 - 기납
 */
export function calcCare(
  bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month,
  ginamP, ginamG,
  healthMonthlyP, healthDecidedP,
  year
) {
  const care = RATES[year].care;
  const ratio = care.numerator / care.denominator;

  const wolCareUnit = rounddown(healthMonthlyP * ratio, -1);

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
 * 사업주 고용안정·직업능력개발 요율(g_stable)은 기관 규모별로 상이:
 *   150인 미만: 0.25%  / 150인 이상 우선지원대상: 0.45%
 *   150~1,000인: 0.65% / 1,000인 이상·국가지자체: 0.85%
 *
 * @param {number} overrideStableRate  사업주 고용안정 요율 직접 지정 (없으면 RATES 기본값 사용)
 */
export function calcEmployment(
  bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month,
  ginamP, ginamG, year, overrideStableRate
) {
  const rate = RATES[year].employment;
  const stableRate = overrideStableRate ?? rate.g_stable;

  const monthlyP = rounddown(bonsuWol * rate.p, -1);
  const monthlyG = rounddown(bonsuWol * (rate.g_base + stableRate), -1);

  const decidedP = rounddown(bonsuTotal * rate.p, -1);
  const decidedG = rounddown(bonsuTotal * rate.g_base, -1)
                 + rounddown(bonsuTotal * stableRate, -1);

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
 * @param {number} overrideRate  기관별 산재요율 직접 지정 (없으면 RATES 기본값 사용)
 */
export function calcAccident(
  bonsuWol, bonsuTotal, geunMonths, wolIp, il1Month,
  ginamG, year, overrideRate
) {
  const rate = overrideRate ?? RATES[year].accident.g;

  const monthlyG  = rounddown(bonsuWol  * rate, -1);
  const decidedG  = rounddown(bonsuTotal * rate, -1);

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
 *   bonsuWol:           number,       보수월액
 *   bonsuTotal:         number,       보수총액 (건강/요양 기준)
 *   bonsuTotalEmploy?:  number,       보수총액 (고용/산재 기준, 미지정 시 bonsuTotal 사용)
 *   geunMonths:         number,       근무월수
 *   wolIp:              'Y'|'N',
 *   il1Month:           number,       산정월수 (wolIp=Y 시)
 *   ginam: { pension_p, pension_g, health_p, health_g, care_p, care_g,
 *            employ_p, employ_g, accident_g },
 *   year:               2025|2026,
 *   accidentRate?:      number,       산재보험료율 직접 지정 (없으면 RATES 기본값)
 *   employStableRate?:  number        고용안정 사업주 요율 직접 지정 (없으면 RATES 기본값)
 * }
 */
export function calcSettlement(input) {
  const {
    bonsuWol, bonsuTotal, geunMonths,
    wolIp, il1Month, ginam, year
  } = input;

  const bonsuTotalEmploy = input.bonsuTotalEmploy ?? bonsuTotal;

  // ① 연금 (정산 없음, 상·하한선 자동 적용)
  // 기준소득월액 상·하한은 7월에 개정된다. 호출부가 기준일을 주면 그 시점 값을 쓴다.
  const pension = calcPension(bonsuWol, year, input.refDate ?? null);

  // ② 건강
  const health = calcHealth(
    bonsuWol, bonsuTotal, geunMonths,
    wolIp, il1Month,
    ginam.health_p, ginam.health_g,
    year
  );

  // ③ 요양
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

  // ④ 고용 (고용안정 요율 외부 주입 가능)
  const employment = calcEmployment(
    bonsuWol, bonsuTotalEmploy, geunMonths,
    wolIp, il1Month,
    ginam.employ_p, ginam.employ_g,
    year,
    input.employStableRate
  );

  // ⑤ 산재 (산재요율 외부 주입 가능 — UI에서 기관별로 다른 요율 입력 가능)
  const accident = calcAccident(
    bonsuWol, bonsuTotalEmploy, geunMonths,
    wolIp, il1Month,
    ginam.accident_g,
    year,
    input.accidentRate
  );

  return { pension, health, care, employment, accident };
}
