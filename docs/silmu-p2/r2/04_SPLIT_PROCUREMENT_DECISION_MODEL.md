# 04 — 분할발주 판단 모델

> §12: "나눠서 계약했다 → 위법"으로 만들지 않는다. §27: 임의 횟수·기간 기준 금지.
> 구현 = `app/services/contract_decision/split_procurement_evaluator.rb`

---

## 1. 두 트랙 — 합치지 않는다

```
계약 유형
├── 공사 (종합·전문·그 밖의 공사)   →  §77 트랙 : 금지 + 예외 + 회피목적 override
└── 물품 · 용역                    →  §7제2호 트랙 : 추정가격 합산 산정
```

운영 도구는 물품·용역(기본 선택지)에 §77 을 근거로 대고 있었다. §77 은 표제·본문 모두 "공사"다.
근거를 잘못 대면 두 가지가 동시에 깨진다 — 인용이 틀리고, **실제로 적용되는 규칙(§7제2호)을 놓친다.**
합산 기간이 조문에 없는 "최근 3개월"이 된 것이 그 결과다.

## 2. 공사 트랙 (§77)

### 사실 질문

| factor | 조문 | 값 |
|---|---|---|
| `single_project` | §77① | 동일 구조물공사 또는 단일공사인가 |
| `scope_fixed` | §77① | 설계서 등으로 전체 사업내용이 확정되었는가 |
| `avoidance_intent` | §77③ | 수의계약 한도·경쟁 회피 목적인가 |

`separation_ground` — §77①1호 / 2호 / 3호가목 / 3호나목 중 주장하는 사유.

### 판정 순서

```
⓪ single_project=no 또는 scope_fixed=no (금지 요건 **확정 미충족**)
   ├─ avoidance_intent ≠ yes  → LOW_RISK  (§77 이 적용되지 않는다. 예외 사유를 주장할 필요도 없다)
   └─ avoidance_intent = yes  → REVIEW_NEEDED + INCONSISTENT_INPUT
                                 (별개 사업이라면 회피할 한도가 없다 — 답이 서로 맞지 않는다)
① avoidance_intent = yes 이지만
   분리 사유 주장도 없고 §77① 요건(single & fixed)도 성립 안 함  → REVIEW_NEEDED
   (§77③ 은 "제1항 각 호의 공사"에 붙는 조항이다. 아무것도 성립하지 않은 상태에서
    회피 목적 답변만 보고 §77③ 을 인용하면 조문 적용범위를 넘는다)
② avoidance_intent = yes + (분리 사유 주장 또는 §77① 요건 성립) → HIGH_SPLIT_RISK (§77①+§77③)
   (§77③ 은 §77①각 호의 허용 사유를 덮는다)
③ separation_ground 지정            → LEGITIMATE_SEPARATION_POSSIBLE
   (avoidance_intent ≠ no 이면 미해결 요인으로 남긴다)
④ single_project=yes & scope_fixed=yes → HIGH_SPLIT_RISK (§77①)
⑤ 둘 중 하나가 no                   → LOW_RISK (+ SELF_REPORTED 단서)
⑥ 그 밖 (미상)                      → INSUFFICIENT_INFORMATION
```

⓪은 **독립검증(gemini)** 지적을 수리한 것이다 — §77①이 적용되지 않는 계약에 예외 사유를
입증하게 하면 없는 책임을 지운다. ①은 구현 도중 호스트 자체 전수 프로브가 찾은 것이다. 처음에는 `avoidance_intent=yes` 면
사실관계와 무관하게 전부 `HIGH_SPLIT_RISK` + §77③ 인용이었다. 27개 조합을 전수로 찍어 보고
"§77① 요건도 각 호 사유도 없는데 §77③ 을 근거로 든다"는 것을 발견했다. 뮤턴트 5b 로 고정했다.

의무는 결과와 무관하게 항상 함께 낸다 — §77②(계획 단계 검토), §77④(제1항제2호 분할 시 보고).

## 3. 물품·용역 트랙 (§7제2호)

| factor | 값 |
|---|---|
| `same_purpose` | 동일·유사한 조달 요구인가 |
| `within_window` | 합산 대상 기간(**12개월** / 해당 회계연도) 안인가 |

```
same_purpose = no                     → LOW_RISK (합산 대상 아님)
둘 중 하나 미상                        → INSUFFICIENT_INFORMATION
same & window = yes
  ├─ 합산액 > 2천만원                  → HIGH_SPLIT_RISK
  └─ 합산액 ≤ 2천만원 (또는 금액 미입력) → REVIEW_NEEDED
same=yes · window=no                  → REVIEW_NEEDED (기간 산정 재확인)
```

합산 화면에는 이번 금액 · 기간 내 합산 · **제7조제2호에 따른 추정가격**을 함께 보여주고,
비교 임계는 **§30①2호 본문의 2천만원**임을 조문 위치와 함께 표시한다.
임계값은 규칙집에서 읽으며 코드에 리터럴이 없다.

## 3-bis. 검토축 8종 — 계약유형별로 갈라서 낸다 (§5)

같은 8개 축을 두 트랙에 **각각** 물었을 때, 근거가 있는 축의 수가 다르다.

| 축 | 공사 (§77) | 물품·용역 (§7제2호) |
|---|---|---|
| 동일 사업·수요 | §77①  *판정* | §7제2호  *판정* |
| 통합 산정 가능성 | §77①(전체 사업내용 확정)  *판정* | §7제2호나목  *판정* |
| 동일 목적·기능 | §77①  *판정* | §7제2호가목  *판정* |
| 동일 시기 예측 가능성 | §77②  *안내* | §7제2호가목·나목  *판정* |
| 한도·경쟁 회피 효과 | §77③  *판정* | **근거 미확인 → REVIEW_REQUIRED** |
| 법령상 별도 발주 필요성 | §77①1호  *분리 사유* | **근거 미확인 → REVIEW_REQUIRED** |
| 객관적 분리 사유 | §77①2호  *분리 사유* | **근거 미확인 → REVIEW_REQUIRED** |
| 기술적·일정상 독립성 | §77①3호  *분리 사유* | **근거 미확인 → REVIEW_REQUIRED** |
| **근거 보유** | **8 / 8** | **4 / 8** |

물품·용역의 4축을 채우려면 §77(공사 조항)이나 §28(§25①6호가목·§26·§27 한정 허용)을
끌어다 써야 한다. **그게 조문 번호만 보고 의미를 넓히는 것**이라 하지 않았다.
그 4축은 판정하지 않고 사유와 함께 검토 대상으로 남긴다.

회귀 = `split_procurement_evaluator_test.rb` "물품·용역에서 근거를 확인하지 못한 축은
REVIEW_REQUIRED 로 남는다" · 뮤턴트 23(공사 조문 부착) · 24(사유 제거).

## 4. 출력 상태

| 상태 | 뜻 |
|---|---|
| `LOW_RISK` | 금지·합산 요건을 충족하지 않는다 (입력한 사실관계 기준) |
| `REVIEW_NEEDED` | 요건에 걸리나 결론을 확정할 정보가 부족하다 |
| `HIGH_SPLIT_RISK` | 금지 요건 충족 또는 회피 목적 확인 |
| `LEGITIMATE_SEPARATION_POSSIBLE` | §77①각 호의 허용 사유에 해당할 수 있다 |
| `INSUFFICIENT_INFORMATION` | 사실관계가 확인되지 않았다 |

`LAWFUL_CONFIRMED` 같은 상태는 **만들지 않았다**(§13). 회귀 테스트가 그 이름의 부재를 고정한다.

독립검증(kimi)이 `LEGITIMATE_SEPARATION_POSSIBLE` 이라는 이름 자체가 "목적 심사까지 통과한
확정 판정"으로 읽힌다고 지적했다. 상태 어휘는 과제가 지정한 것이라 이름을 바꾸지 않았고,
대신 그 판정의 headline 에 **"요건 해당 가능성이지 적법 확정이 아니며 §77③ 회피 목적 여부는
별도 확인"** 을 결합했다. 회귀로 고정했다.

## 5. 만들지 않은 것 (§27)

| 없앤 것 | 이유 |
|---|---|
| `체크 3개 이상 = 위험 높음` · `2개 이상 = 중간` | 조문에 그런 기준이 없다. 임의 위험점수다 |
| "최근 **3개월**" 합산 창 | §7제2호는 **12개월**/회계연도다 |
| "동일 계약상대자" 를 판정 요건으로 | 감사 관점 신호이지 조문 요건이 아니다. 요건에서 제외 |
| 위험도 진행바 (n/5) | 위와 같은 이유. 점수를 시각화하면 근거가 있는 것처럼 보인다 |
| "수의계약 가능" 결론 | 분할 도구가 낼 판정이 아니다. 계약방식 도구로 넘긴다 |

## 6. 실측 출력

| 유형 | 입력 | 상태 |
|---|---|---|
| 종합공사 | single=yes, fixed=yes | HIGH_SPLIT_RISK (§77①) |
| 종합공사 | single=no, fixed=no, avoidance=**yes** | **REVIEW_NEEDED** — §77③ 미인용 + `INCONSISTENT_INPUT` |
| 종합공사 | single=no, fixed=no, ground=1호 | **LOW_RISK** — §77①이 적용되지 않으므로 예외 사유 입증 불필요 |
| 종합공사 | 사실 미상 + avoidance=yes | REVIEW_NEEDED + `AVOIDANCE_SCOPE` |
| 종합공사 | single=yes, fixed=yes, avoidance=yes | HIGH_SPLIT_RISK (§77①+§77③) |
| 종합공사 | single=yes, fixed=yes, ground=1호, avoidance=no | LEGITIMATE_SEPARATION_POSSIBLE |
| 종합공사 | 〃 + avoidance=**yes** | **HIGH_SPLIT_RISK** (§77③) |
| 종합공사 | ground=2호, avoidance=no | LEGITIMATE_SEPARATION_POSSIBLE + **§77④ 보고의무** |
| 종합공사 | single=no | LOW_RISK + SELF_REPORTED |
| 종합공사 | 전부 미상 | INSUFFICIENT_INFORMATION |
| 물품 | same=yes, window=yes, 1,800만+1,800만+1,500만 | HIGH_SPLIT_RISK · 추정가격 5,100만 |
| 물품 | same=yes, window=yes, 500만+500만 | REVIEW_NEEDED · 추정가격 1,000만 |
| 물품 | same=no | LOW_RISK |
| 물품 | same 미상 | INSUFFICIENT_INFORMATION |
| (미선택) | — | INSUFFICIENT_INFORMATION (어느 조문인지 정해지지 않음) |
