import { strict as assert } from 'node:assert';
import { describe, it } from 'node:test';
import { rounddown } from '../../app/javascript/insurance/engine.js';

describe('T01: rounddown', () => {
  it('TC-12: rounddown(73907, -1) === 73900', () => {
    assert.strictEqual(rounddown(73907, -1), 73900);
  });
  it('rounddown(73900, -1) === 73900 (이미 10원 단위)', () => {
    assert.strictEqual(rounddown(73900, -1), 73900);
  });
  it('rounddown(73910, -1) === 73910', () => {
    assert.strictEqual(rounddown(73910, -1), 73910);
  });
  it('rounddown(0, -1) === 0', () => {
    assert.strictEqual(rounddown(0, -1), 0);
  });
  it('rounddown(9, -1) === 0 (10원 미만 버림)', () => {
    assert.strictEqual(rounddown(9, -1), 0);
  });
  it('rounddown(55155, -1) === 55150', () => {
    assert.strictEqual(rounddown(55155, -1), 55150);
  });
  it('rounddown(음수값 -73907, -1) === -73910 (음수 내림)', () => {
    assert.strictEqual(rounddown(-73907, -1), -73910);
  });
});

import { RATES } from '../../app/javascript/insurance/engine.js';

describe('T02: RATES 상수', () => {
  it('RATES[2025].health.p === 0.03545', () => {
    assert.strictEqual(RATES[2025].health.p, 0.03545);
  });
  it('RATES[2026].health.p === 0.03595', () => {
    assert.strictEqual(RATES[2026].health.p, 0.03595);
  });
  it('RATES[2025].pension.p === 0.045', () => {
    assert.strictEqual(RATES[2025].pension.p, 0.045);
  });
  it('RATES[2026].pension.g === 0.0475', () => {
    assert.strictEqual(RATES[2026].pension.g, 0.0475);
  });
  it('RATES[2025].care.numerator === 0.9182', () => {
    assert.strictEqual(RATES[2025].care.numerator, 0.9182);
  });
  it('RATES[2026].care.denominator === 7.19', () => {
    assert.strictEqual(RATES[2026].care.denominator, 7.19);
  });
  it('RATES[2025].employment.p === 0.009', () => {
    assert.strictEqual(RATES[2025].employment.p, 0.009);
  });
  it('RATES[2025].accident.g === 0.00786', () => {
    assert.strictEqual(RATES[2025].accident.g, 0.00786);
  });
});

import { calcPension } from '../../app/javascript/insurance/engine.js';

describe('T03: calcPension (연금보험료)', () => {
  it('2026년 기관: calcPension(1_560_000, 2026).monthly.g === 74100', () => {
    // rounddown(1_560_000 * 0.0475, -1) = rounddown(74100, -1) = 74100
    assert.strictEqual(calcPension(1_560_000, 2026).monthly.g, 74100);
  });
  it('2025년 개인: calcPension(1_560_000, 2025).monthly.p === 70200', () => {
    // rounddown(1_560_000 * 0.045, -1) = rounddown(70200, -1) = 70200
    assert.strictEqual(calcPension(1_560_000, 2025).monthly.p, 70200);
  });
  it('2026년 개인: calcPension(1_560_000, 2026).monthly.p === 74100', () => {
    // 2026년 p=0.0475, rounddown(74100, -1) = 74100
    assert.strictEqual(calcPension(1_560_000, 2026).monthly.p, 74100);
  });
  it('2025년 기관: calcPension(2_000_000, 2025).monthly.g === 95000', () => {
    // rounddown(2_000_000 * 0.0475, -1) = rounddown(95000, -1) = 95000
    assert.strictEqual(calcPension(2_000_000, 2025).monthly.g, 95000);
  });
  it('연금은 정산 없음 — settlement 키 없음', () => {
    const result = calcPension(1_560_000, 2025);
    assert.strictEqual('settlement' in result, false);
  });
  it('연금은 정산 없음 — decided 키 없음', () => {
    const result = calcPension(1_560_000, 2025);
    assert.strictEqual('decided' in result, false);
  });
});

import { calcHealth } from '../../app/javascript/insurance/engine.js';

describe('T04: calcHealth (건강보험료, 월중입사=N)', () => {
  // TC-01: 보수총액 21,034,620 / 12개월 / 2025년
  const h01 = calcHealth(
    1_558_470,    // bonsuWol (역산 추정)
    21_034_620,   // bonsuTotal
    12,           // geunMonths
    'N',          // wolIp
    0,            // il1Month (N이므로 무관)
    655_860,      // ginamP
    655_860,      // ginamG
    2025
  );

  it('TC-01: 결정보험료(개인) === 745,560', () => {
    assert.strictEqual(h01.decided.p, 745_560);
  });
  it('TC-01: 결정보험료(기관) === 745,560 (개인=기관)', () => {
    assert.strictEqual(h01.decided.g, 745_560);
  });
  it('TC-06: 정산보험료(개인) = 745,560 - 655,860 = 89,700', () => {
    assert.strictEqual(h01.settlement.p, 89_700);
  });
  it('TC-06: 정산보험료(기관) = 89,700', () => {
    assert.strictEqual(h01.settlement.g, 89_700);
  });
  it('월보험료(개인) === rounddown(1558470 * 0.03545, -1)', () => {
    // rounddown(55248, -1) = 55240
    const expected = Math.floor(1_558_470 * 0.03545 / 10) * 10;
    assert.strictEqual(h01.monthly.p, expected);
  });

  // 기납=0일 때 정산 = 결정
  const hZero = calcHealth(2_000_000, 24_000_000, 12, 'N', 0, 0, 0, 2025);
  it('기납=0일 때 정산 = 결정', () => {
    assert.strictEqual(hZero.settlement.p, hZero.decided.p);
  });
});

describe('T05: calcHealth (건강보험료, 월중입사=Y)', () => {
  // TC-13: 보수총액 5,000,000 / 4개월 / il1Month=3 / 2026년
  const h13 = calcHealth(
    1_250_000,  // bonsuWol
    5_000_000,  // bonsuTotal
    4,          // geunMonths
    'Y',        // wolIp
    3,          // il1Month
    0,          // ginamP
    0,          // ginamG
    2026
  );

  it('TC-13: 월평균 = rounddown(5000000/4, -1) = 1,250,000', () => {
    // 내부 계산 검증 — 결정에 il1Month 곱해서 역산
    // rounddown(1250000 * 0.03595, -1) * 3 = 44930 * 3 = 134790
    assert.strictEqual(h13.decided.p, 134_790);
  });
  it('TC-13: 결정(기관) === 결정(개인)', () => {
    assert.strictEqual(h13.decided.g, h13.decided.p);
  });
  it('TC-13: 정산(개인) = 134,790 (기납 0)', () => {
    assert.strictEqual(h13.settlement.p, 134_790);
  });

  // 월중입사=Y, il1Month=12 이면 N 케이스와 근사
  const hY12 = calcHealth(
    2_000_000, 24_000_000, 12, 'Y', 12, 0, 0, 2025
  );
  const hN12 = calcHealth(
    2_000_000, 24_000_000, 12, 'N', 0,  0, 0, 2025
  );
  it('월중입사=Y + il1Month=12 시 N 케이스와 결정 동일 (보수 균등 분포 시)', () => {
    assert.strictEqual(hY12.decided.p, hN12.decided.p);
  });
});

import { calcCare } from '../../app/javascript/insurance/engine.js';

describe('T06: calcCare (요양보험료)', () => {
  // TC-02: 2025년, 월중입사=N
  // 건강보험료_월기준(개인) = 62,130 (TC-01 기준)
  // 건강보험료_결정(개인)   = 745,560
  const c02 = calcCare(
    1_558_470,   // bonsuWol
    21_034_620,  // bonsuTotal
    12,          // geunMonths
    'N',         // wolIp
    0,           // il1Month
    0,           // ginamP (요양 기납)
    0,           // ginamG
    62_130,      // healthMonthlyP (건강_월기준액)
    745_560,     // healthDecidedP
    2025
  );

  it('TC-02: 결정보험료(개인) === 96,480', () => {
    assert.strictEqual(c02.decided.p, 96_480);
  });
  it('TC-02: 결정보험료(기관) === 96,480', () => {
    assert.strictEqual(c02.decided.g, 96_480);
  });
  it('기납=0이면 정산 = 결정', () => {
    assert.strictEqual(c02.settlement.p, 96_480);
  });

  // 기납 포함 정산
  const c02b = calcCare(
    1_558_470, 21_034_620, 12, 'N', 0,
    7_560, 7_560,   // 기납
    62_130, 745_560, 2025
  );
  it('정산 = 결정 - 기납: 96480 - 7560 = 88920', () => {
    assert.strictEqual(c02b.settlement.p, 88_920);
  });

  // TC-13 케이스: 2026년, 월중입사=Y
  // 건강결정(개인) = 134,790 (T05에서 계산)
  // 월평균 = 1,250,000 → healthMonthlyP = rounddown(1250000 * 0.03595, -1) = 44930
  const c13 = calcCare(
    1_250_000, 5_000_000, 4, 'Y', 3,
    0, 0,
    44_930,    // healthMonthlyP
    134_790,   // healthDecidedP
    2026
  );
  it('TC-13 요양(Y): 결정(개인) = rounddown(44930 * care비율, -1) * 3', () => {
    const ratio = 0.9448 / 7.19;
    const expected = Math.floor(44_930 * ratio / 10) * 10 * 3;
    assert.strictEqual(c13.decided.p, expected);
  });
});

import { calcEmployment } from '../../app/javascript/insurance/engine.js';

describe('T07: calcEmployment (고용보험료)', () => {
  const bonsuWol   = 1_753_000;  // 역산 추정
  const bonsuTotal = 21_033_340;

  const e01 = calcEmployment(bonsuWol, bonsuTotal, 12, 'N', 0,
    189_300, 378_170, 2025);

  it('TC-03: 결정(개인) === 189,300', () => {
    assert.strictEqual(e01.decided.p, 189_300);
  });
  it('TC-04: 결정(기관) === 368,080', () => {
    assert.strictEqual(e01.decided.g, 368_080);
  });
  it('TC-07: 정산(기관) = 368,080 - 378,170 = -10,090 (환급)', () => {
    assert.strictEqual(e01.settlement.g, -10_090);
  });

  // 월보험료 구조 확인
  it('월보험료(기관) = rounddown(bonsuWol × 1.75%, -1)', () => {
    const expected = Math.floor(bonsuWol * (0.009 + 0.0085) / 10) * 10;
    assert.strictEqual(e01.monthly.g, expected);
  });
  it('월보험료(개인) = rounddown(bonsuWol × 0.9%, -1)', () => {
    const expected = Math.floor(bonsuWol * 0.009 / 10) * 10;
    assert.strictEqual(e01.monthly.p, expected);
  });

  // 기납=0
  const eZero = calcEmployment(bonsuWol, bonsuTotal, 12, 'N', 0, 0, 0, 2025);
  it('기납=0이면 정산 = 결정', () => {
    assert.strictEqual(eZero.settlement.p, eZero.decided.p);
    assert.strictEqual(eZero.settlement.g, eZero.decided.g);
  });
});

import { calcAccident } from '../../app/javascript/insurance/engine.js';

describe('T08: calcAccident (산재보험료)', () => {
  const bonsuWol   = 1_753_000;
  const bonsuTotal = 21_033_340;

  const a01 = calcAccident(bonsuWol, bonsuTotal, 12, 'N', 0,
    165_320, 2025);

  it('TC-05: 결정(기관) === 165,320', () => {
    assert.strictEqual(a01.decided.g, 165_320);
  });
  it('개인 부담 없음 — p 키 없음', () => {
    assert.strictEqual('p' in a01.decided, false);
    assert.strictEqual('p' in a01.monthly, false);
  });
  it('정산 = 결정 - 기납', () => {
    assert.strictEqual(a01.settlement.g, 165_320 - 165_320);
  });

  // 기납=0
  const aZero = calcAccident(bonsuWol, bonsuTotal, 12, 'N', 0, 0, 2025);
  it('기납=0이면 정산 = 결정', () => {
    assert.strictEqual(aZero.settlement.g, aZero.decided.g);
  });

  // 월보험료
  it('월보험료(g) = rounddown(bonsuWol × 0.786%, -1)', () => {
    const expected = Math.floor(bonsuWol * 0.00786 / 10) * 10;
    assert.strictEqual(a01.monthly.g, expected);
  });
});

import { calcSettlement } from '../../app/javascript/insurance/engine.js';

describe('T09: calcSettlement (정산 통합)', () => {
  // ── 2025년, 월중입사=N, TC-01/02/03/04/05/06/07 케이스 ──
  const result25 = calcSettlement({
    bonsuWol:   1_558_470,
    bonsuTotal: 21_034_620,   // 건강/요양 기준
    bonsuTotalEmploy: 21_033_340,  // 고용/산재 기준 (별도 필드)
    geunMonths: 12,
    wolIp:      'N',
    il1Month:   0,
    ginam: {
      pension_p:  0,
      pension_g:  0,
      health_p:   655_860,
      health_g:   655_860,
      care_p:     0,
      care_g:     0,
      employ_p:   189_300,
      employ_g:   378_170,
      accident_g: 165_320,
    },
    year: 2025
  });

  // TC-06: 건강 정산(개인)
  it('TC-06: health.settlement.p === 89,700', () => {
    assert.strictEqual(result25.health.settlement.p, 89_700);
  });
  // TC-07: 고용 정산(기관) 환급
  it('TC-07: employment.settlement.g === -10,090 (환급)', () => {
    assert.strictEqual(result25.employment.settlement.g, -10_090);
  });
  // TC-01: 건강 결정
  it('TC-01: health.decided.p === 745,560', () => {
    assert.strictEqual(result25.health.decided.p, 745_560);
  });
  // TC-02: 요양 결정
  it('TC-02: care.decided.p === 96,480', () => {
    assert.strictEqual(result25.care.decided.p, 96_480);
  });
  // TC-03: 고용 결정(개인)
  it('TC-03: employment.decided.p === 189,300', () => {
    assert.strictEqual(result25.employment.decided.p, 189_300);
  });
  // TC-04: 고용 결정(기관)
  it('TC-04: employment.decided.g === 368,080', () => {
    assert.strictEqual(result25.employment.decided.g, 368_080);
  });
  // TC-05: 산재 결정(기관)
  it('TC-05: accident.decided.g === 165,320', () => {
    assert.strictEqual(result25.accident.decided.g, 165_320);
  });

  // 연금 정산 없음 구조 확인
  it('pension: monthly만 있고 decided/settlement 없음', () => {
    assert.ok(result25.pension.monthly);
    assert.strictEqual('decided'    in result25.pension, false);
    assert.strictEqual('settlement' in result25.pension, false);
  });

  // ── 2026년, 월중입사=N ──
  const result26 = calcSettlement({
    bonsuWol:   1_489_820,   // 역산 추정
    bonsuTotal: 4_469_450,
    geunMonths: 3,
    wolIp:      'N',
    il1Month:   0,
    ginam: {
      pension_p:  0, pension_g:  0,
      health_p:   0, health_g:   0,
      care_p:     0, care_g:     0,
      employ_p:   0, employ_g:   0,
      accident_g: 0,
    },
    year: 2026
  });

  it('TC-08: 2026년 건강결정 = rounddown(4469450/3×0.03595,-1)×3', () => {
    const wol = Math.floor((4_469_450 / 3 * 0.03595) / 10) * 10;
    assert.strictEqual(result26.health.decided.p, wol * 3);
  });
  it('TC-09: 2026년 고용결정(기관) = base + stable', () => {
    const base  = Math.floor(4_469_450 * 0.009  / 10) * 10;
    const stab  = Math.floor(4_469_450 * 0.0085 / 10) * 10;
    assert.strictEqual(result26.employment.decided.g, base + stab);
  });

  // ── 월중입사=Y 케이스 ──
  const resultY = calcSettlement({
    bonsuWol:   1_250_000,
    bonsuTotal: 5_000_000,
    geunMonths: 4,
    wolIp:      'Y',
    il1Month:   3,
    ginam: {
      pension_p: 0, pension_g: 0,
      health_p:  0, health_g:  0,
      care_p:    0, care_g:    0,
      employ_p:  0, employ_g:  0,
      accident_g: 0,
    },
    year: 2026
  });
  it('TC-13: Y케이스 건강결정 === 134,790', () => {
    assert.strictEqual(resultY.health.decided.p, 134_790);
  });
});
