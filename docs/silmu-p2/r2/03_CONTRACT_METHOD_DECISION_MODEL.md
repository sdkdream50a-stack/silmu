# 03 — 수의계약 판단 모델

> §10·§11·§18·§19: 결정적 규칙 + 근거 기반 설명. 금액만으로 판정하지 않는다.
> 구현 = `app/services/contract_decision/private_contract_evaluator.rb` · `quotation_requirement.rb`
> 규칙 = `config/contract_decision_rules.yml` (코드에 금액 리터럴 없음)

---

## 1. 판단 축

| 축 | 값 | 왜 필요한가 |
|---|---|---|
| `AGENCY_SCOPE` | LOCAL_GOVERNMENT · EDUCATION_OFFICE · PUBLIC_SCHOOL (범위 안) / CENTRAL_GOVERNMENT · PUBLIC_INSTITUTION · PRIVATE_SCHOOL (범위 밖) | 적용 법령이 다르다 |
| `CONTRACT_TYPE` | goods · service · construction_general · construction_special · construction_etc · lease_etc | §25①5호가·나·사목이 유형별로 다른 한도 |
| `ESTIMATED_AMOUNT` | 원 단위 (부가세·관급자재 제외) | §7 산정 결과 |
| `COUNTERPARTY_TYPE` | UNKNOWN · GENERAL · YOUTH_STARTUP · SMALL_ENTERPRISE · WOMEN · DISABLED · SOCIAL_ENTERPRISE · SOCIAL_COOPERATIVE · SELF_SUPPORT · VILLAGE | §25 다·라·바목이 상대방 자격 조건 |
| `SPECIAL_FIELD` | bool | §25 마목 (학술연구·원가계산·건설기술) |
| `VULNERABLE_RATIO_MET` | true · false · **nil(미확인)** | §25 바목 단서 · §30①2호나목 |

**`UNKNOWN` 은 `GENERAL` 이 아니다.** 모르는 것과 아닌 것은 다른 입력이고 다른 결론을 낸다.

## 2. 출력 상태

| 상태 | 뜻 |
|---|---|
| `POSSIBLE` | 조문 요건을 충족한다 |
| `POSSIBLE_WITH_CONDITIONS` | 요건은 맞으나 확인해야 할 조건이 남아 있다 (마목 특수분야 · 바목 고용비율) |
| `COMPETITIVE_PROCEDURE_REQUIRED` | §25①5호 사유가 적용되지 않는다. 경쟁입찰이 원칙 |
| `REVIEW_REQUIRED` | 담당자 판단이 필요하다 |
| `INSUFFICIENT_INFORMATION` | 입력이 부족해 어느 쪽도 단정할 수 없다 |
| `OUT_OF_SCOPE` | 이 규칙집이 덮지 않는 기관 |

> 기존 어휘 우선(§10) 검토: 저장소의 선행 구현(`EstimatedPriceService`)은 `available` 불리언 +
> `undetermined` 플래그를 쓴다. `undetermined` 는 위 `INSUFFICIENT_INFORMATION` 에 대응하지만,
> 불리언 축만으로는 "조건부 가능"과 "범위 밖"을 표현할 수 없어 6상태 어휘를 도입했다.
> 새 어휘가 기존 개념을 **대체하지 않고 포함**한다.

## 3. 판정 절차

```
① 기관 범위      미선택 → INSUFFICIENT_INFORMATION
                 범위 밖 → OUT_OF_SCOPE (+ 어느 법이 적용되는지)
② 필수 입력      유형·금액 없음 → INSUFFICIENT_INFORMATION
③ 상대방 필요성   물품·용역 & 2천만원 초과 & 유형 상한 이내 & 특수분야 아님 & 상대방 UNKNOWN
                 → INSUFFICIENT_INFORMATION
                 (상대방이 결론을 **실제로 바꾸는 구간**에서만 묻는다. 2천만원 이하,
                  1억원 초과, 특수분야(마목)는 상대방과 무관하게 결론이 확정된다)
④ 규칙 매칭      §25①5호 rule 중 유형·금액·상대방·특수분야를 모두 만족하는 것
                 매칭 0건 → COMPETITIVE_PROCEDURE_REQUIRED (+ 금액 외 사유 안내)
⑤ 단서 적용      취약계층 고용비율: 미확인 → 조건부 / 미충족 → 경쟁입찰
⑥ 견적요건       §30① 별도 판정 (§25 와 다른 임계)
```

③이 이 모델의 핵심이다. 운영 도구는 이 단계 없이 ④로 직행해 상대방을 모르는 상태에서
"수의계약"이라고 답했다.

## 4. 설명가능성 (§18)

모든 응답에 포함:

```json
{ "state": "...", "headline": "...",
  "input": { "agency_scope": "...", "contract_type": "...", "estimated_price": 0,
             "counterparty_type": "...", "special_field": false, "vulnerable_ratio_met": null },
  "matched_rule": { "rule_id": "D25-1-5-라", "source_locator": "제25조제1항제5호라목", "outcome": "POSSIBLE" },
  "legal_basis": [ { "title": "...", "locator": "...", "quote": "...",
                     "effective_from": "2026-06-03", "verified_at": "2026-09-06", "url": "..." } ],
  "conditions": [ "..." ],
  "unresolved_factors": [ { "factor": "COUNTERPARTY_TYPE", "detail": "..." } ],
  "quotation": { "requirement": "TWO_OR_MORE", "label": "...", "legal_basis": [...] },
  "next_actions": [ "..." ],
  "other_grounds": [ { "locator": "제25조제1항제1호", "label": "..." } ] }
```

점수는 없다. `"가능성 높음 82점"` 같은 값을 만들 근거가 조문에 없다(§18 후단).
회귀 = `test/services/contract_decision/private_contract_evaluator_test.rb` "점수를 출력하지 않는다".

## 5. 판정 표 (실측 출력)

기관 = LOCAL_GOVERNMENT.

| 유형 | 금액 | 상대방 | 상태 | 견적요건 |
|---|---:|---|---|---|
| 물품 | 1,000만 | (무관) | POSSIBLE `D25-1-5-나` | 1인 가능 |
| 물품 | 2,000만 | (무관) | POSSIBLE `D25-1-5-나` | 1인 가능 |
| 물품 | 2,000만 1원 | UNKNOWN | **INSUFFICIENT_INFORMATION** | — |
| 물품 | 3,000만 | GENERAL | **COMPETITIVE_PROCEDURE_REQUIRED** | — |
| 물품 | 3,000만 | YOUTH_STARTUP | POSSIBLE `D25-1-5-다` | 1인 가능 (§30 가목) |
| 용역 | 5,000만 | GENERAL | COMPETITIVE_PROCEDURE_REQUIRED | — |
| 용역 | 5,000만 | SMALL_ENTERPRISE | POSSIBLE `D25-1-5-라` | **2인 이상** (§30 열거 밖) |
| 용역 | 5,000만 | SOCIAL_ENTERPRISE (비율 미확인) | POSSIBLE_WITH_CONDITIONS | 고용비율 확인 후 |
| 용역 | 5,000만 | SOCIAL_ENTERPRISE (비율 **충족**) | **POSSIBLE** · 조건 없음 | 1인 가능 (§30 나목) |
| 용역 | 5,000만 | UNKNOWN · 특수분야 | POSSIBLE_WITH_CONDITIONS `D25-1-5-마` | 2인 이상 |
| 물품 | 1.5억 | UNKNOWN | **COMPETITIVE_PROCEDURE_REQUIRED** | — |
| 용역 | 8,000만 | YOUTH_STARTUP | **COMPETITIVE_PROCEDURE_REQUIRED** (다목 5천만 상한) | — |
| 물품 | 8,000만 | WOMEN | POSSIBLE `D25-1-5-바-1-2` | **2인 이상** (§30 가목 5천만 초과) |
| 종합공사 | 3억 | (무관) | POSSIBLE `D25-1-5-가-general` | 2인 이상 |
| 전문공사 | 3억 | (무관) | COMPETITIVE_PROCEDURE_REQUIRED | — |
| 물품 | 1,000만 | (무관) · 기관=국가기관 | **OUT_OF_SCOPE** | — |

## 5-bis. 상대방 × 금액 전수 (물품 · 실측)

`ASK` = INSUFFICIENT_INFORMATION · `BID` = COMPETITIVE_PROCEDURE_REQUIRED · `COND` = POSSIBLE_WITH_CONDITIONS

| 금액 | UNKNOWN | GENERAL | 청년창업 | 소기업·소상공인 | 여성기업 | 사회적기업 |
|---:|---|---|---|---|---|---|
| 200만 | POSSIBLE | POSSIBLE | POSSIBLE | POSSIBLE | POSSIBLE | POSSIBLE |
| 2,000만 | POSSIBLE | POSSIBLE | POSSIBLE | POSSIBLE | POSSIBLE | POSSIBLE |
| 2,000만 1원 | **ASK** | **BID** | POSSIBLE | POSSIBLE | POSSIBLE | COND |
| 5,000만 | ASK | BID | POSSIBLE | POSSIBLE | POSSIBLE | COND |
| 5,000만 1원 | ASK | BID | **BID** | POSSIBLE | POSSIBLE | COND |
| 1억 | ASK | BID | BID | POSSIBLE | POSSIBLE | COND |
| 1억 1원 | **BID** | BID | BID | BID | BID | BID |

2천만원 이하 행이 상대방과 무관하게 전부 `POSSIBLE` 인 것이 중요하다 — 나목은 상대방 자격을
조건 삼지 않는다. 여기까지 상대방을 묻거나 조건을 붙이면 조문에 없는 요건을 요구하는 것이다.
(구현 도중 실제로 사회적기업 1천만원이 조건부로 나왔고, 뮤턴트 4b 로 고정했다.)

1억 1원 행에서 UNKNOWN 도 `BID` 인 것은 독립검증 지적 수리분이다 — 물품·용역 수의계약 한도는
모든 자격을 통틀어 1억원이므로 그 위는 상대방을 몰라도 결론이 확정된다. 결론이 나는데 되물으면
도구가 답을 미루기만 한다.

마목(학술연구 등 특수분야)은 상대방과 무관하게 1억까지 `POSSIBLE_WITH_CONDITIONS`이고,
**상대방이 UNKNOWN 이어도 판정한다**(마목의 `counterparties` 가 `any` 이므로).
사목(임대차 등)은 5,000만 `POSSIBLE` / 5,000만 1원 `BID`.

## 6. 이 모델이 하지 않는 것

- §25①1~4·6~8호, §26, §27 사유의 **판정**. 존재만 안내한다.
- 부정당업자 제재·수의계약 배제사유 **조회**. 확인하라고 안내만 한다.
- 내부 위임전결 규정 반영. 기관마다 다르고 적재돼 있지 않다.
- 취약계층 고용비율 **수치** 제시. 행안부 고시가 적재돼 있지 않다.
- 적법 확정. 어떤 상태도 "이 계약은 적법하다"를 뜻하지 않는다(§13).
