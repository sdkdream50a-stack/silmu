# DECISION_WIZARD_ARCHITECTURE — 판단형 도구 공통 아키텍처

> 현재 37개 도구는 **계산기**다. 다음 단계는 **판단기**다 — "얼마인가"가 아니라 "해도 되는가".
> 이번 세션에서는 구현하지 않는다. **공통 스키마와 엔진만 설계한다.**

---

## 1. 현재 도구 자산 (실측)

| 지표 | 값 |
|---|---:|
| 도구 수 | 37 |
| 면책·한계 문구 보유 | **7 (19%)** |
| 기준 연도 표기 보유 | **5 (14%)** |
| 검증 배지 | **0** |
| 근거(법령·규정) 언급 | 32 (86%) |
| 본문 <800자 (thin) | 2 |
| 도구 전용 JSON-LD (`SoftwareApplication`/`HowTo`) | **0** |

구조: 도구 1개 = 컨트롤러 1개 + 서비스 1개 (`contract_method_service`, `estimated_price_service`, `legal_period_service` 등 32개 서비스).
기준값 원천: `config/legal_standards.yml`(2026-02-04) · `config/contract_thresholds.yml`(2026-03-28).

**결함:** 각 도구가 규칙을 자기 코드에 갖고 있고, 기준일을 화면에 말하지 않는다(TR-03).

---

## 2. 공통 모델

```
DecisionSpec
├── key                "contract.method.determine"
├── version            "2026-05-20"          ← agency_rules.applicable_from 과 동기
├── domain             05_계약조달
├── inputs[]           InputSpec
├── rules[]            Rule
├── outcomes[]         Outcome
├── evidence[]         EvidenceRef           ← 모든 규칙은 근거를 갖는다
└── disclaimers[]

InputSpec  { key, label, type(enum|money|date|bool|select), required, help, agency_scoped? }
Rule       { id, when(조건식), then(outcome_key), evidence_ref[], applicable_from, applicable_to }
Outcome    { key, verdict, headline, requirements[], next_actions[], risk_notes[] }
EvidenceRef{ law_ref, official_source_url, source_tier, effective_date }

verdict ∈ { ALLOWED, ALLOWED_WITH_CONDITIONS, NOT_ALLOWED, INSUFFICIENT_INPUT, AMBIGUOUS }
```

### 핵심 설계 결정

1. **규칙은 코드가 아니라 데이터다.** `Rule.when`은 `agency_rules` 테이블과 DecisionSpec YAML을 참조한다. 법령 개정 시 코드 배포 없이 값만 바꾼다(현재도 `contract_thresholds.yml` 주석이 "재배포 불필요"라고 밝힌 방향).
2. **`AMBIGUOUS`가 1급 결과다.** 판단할 수 없으면 답을 지어내지 않고 "이 조건에서는 기관 법무·계약심사 확인 필요"를 반환한다. 이것이 도구가 감사 지적을 생산하지 않게 하는 유일한 장치다.
3. **모든 결과에 기관 차원이 붙는다.** `agency_scoped?` 입력은 `AGENCY_RULE_MODEL`의 override 경로를 탄다.
4. **결과는 그 자체로 증빙이 된다.** 판단 근거·기준일·입력값을 포함한 출력(PDF/HWPX)을 생성한다 — 기존 `hwpx_export_service`·`pdf_export_service` 재사용.

---

## 3. 엔진

```ruby
# app/services/decision/engine.rb  (신규 1개)
Decision::Engine.new(spec_key: "contract.method.determine",
                     agency: current_agency,
                     as_of: Date.current)
                .evaluate(inputs)
# => Decision::Result(verdict:, outcome:, evidence:, unresolved_inputs:, spec_version:, ambiguity_reason:)
```

- Spec 로더: `config/decisions/*.yml` (도구별 1파일)
- 규칙 평가: 선언적 조건식 (순수 함수, 부작용 없음) → **테스트가 쉬움**
- 감사 로그: 입력·버전·결과를 익명 저장 → `QUESTION_RADAR`의 입력 신호로 재사용

기존 32개 서비스를 한꺼번에 갈아엎지 않는다. **엔진을 신설하고 신규 판단기부터 태운다.**

---

## 4. 우선 후보 10종 (요구된 목록) — 현재 자산 대비

| # | 판단기 | 현재 | 신규 필요 |
|---|---|---|---|
| 1 | 수의계약 가능 여부 | `contract_method` (계산) | 판단 전환 |
| 2 | 정보공개 공개/비공개 | **없음** (도메인 09 = 2건) | 신규 |
| 3 | 출장여비 판단 | `travel_calculator` | 판단 전환 |
| 4 | 겸직허가 필요 여부 | **없음** | 신규 |
| 5 | 위원회 수당 지급 가능 | **없음** | 신규 |
| 6 | 민원 처리기한 계산 | **없음** (도메인 08 = 0건) | 신규 |
| 7 | 연가보상비 계산/판단 | `annual-leave-calculator` | 판단 전환 |
| 8 | 계약서 작성·생략 판단 | `contract_documents` | 판단 전환 |
| 9 | 보조금 정산 체크 | `subsidy-settlement-checker` | 판단 전환 |
| 10 | 학교회계 집행 가능 여부 | **없음** | 신규 (`fiscal_system` 차원 필수) |

> **순서 판단:** 신규 5종보다 **기존 5종의 판단 전환이 먼저다.** 이미 트래픽과 URL이 있고, TR-03(면책·기준일 결손)을 같은 작업으로 닫을 수 있다.

---

## 5. 도구 화면 공통 계약 (TR-03 수정)

모든 도구 상·하단에 공통 파셜을 강제한다.
```
기준: 지방계약법 시행령 §25 (2026-05-20 시행) · 기준값 버전 2026-02-04  [근거 원문 →]
⚠️ 이 결과는 실무 참고용입니다. 기안 전 소속 기관 기준과 현행 조문을 확인하세요.
   최종 판단은 계약담당관·법무담당관의 검토를 따릅니다.
```
`version` 문자열은 `legal_standards.yml`/`contract_thresholds.yml`에서 **직접 읽는다** — 손으로 적지 않는다. 그래야 상수가 낡으면 화면이 스스로 낡았다고 말한다.
