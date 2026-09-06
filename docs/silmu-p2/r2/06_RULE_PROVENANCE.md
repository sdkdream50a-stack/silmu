# 06 — RULE PROVENANCE

> §20: 각 rule 에 필요한 최소 field 만. 대규모 rule platform 금지 — 두 도구에 필요한 구조만.

---

> **2026-09-06 재개 세션 강화** — rule 스키마를 9 field 로 확장하고 로딩을 fail-closed 로 만들었다.
> §28·법률 §9 를 rule 로 승격했고, 조문 9종을 법제처 API 로 재대조했다
> (`_data/articles_verified.json` · 전건 "현행" 확인).

## 1. 채택한 field

```yaml
rule_id            D25-1-5-라                    # 조문 위치에서 파생. 사람이 읽고 조문을 찾을 수 있어야 한다
title              "소기업·소상공인 1억원 이하"     # 사람이 읽는 이름
agency_scope       [LOCAL_GOVERNMENT, EDUCATION_OFFICE, PUBLIC_SCHOOL]
contract_types     [goods, service]
condition          "추정가격 2천만원 초과 1억원 이하 + 상대방이 소기업 또는 소상공인"
outcome            POSSIBLE
authority_source   LOCAL_CONTRACT_DECREE
source_locator     "제25조제1항제5호라목"
effective_from     "2026-06-03"                  # 이 rule 이 근거로 삼는 조문의 시행일
verified_at        "2026-09-06"                  # 원문을 마지막으로 대조한 날
quote              "추정가격이 2천만원 초과 1억원 이하인 계약으로서 …"
min_amount_exclusive / max_amount / counterparties / conditions   # 매칭 조건
```

`REQUIRED_RULE_FIELDS` = 위 9개(rule_id·title·agency_scope·condition·outcome·
authority_source·source_locator·effective_from·verified_at). 하나라도 없으면 **로딩이 실패한다.**

`sources` 블록이 문서 단위로 `title · law_id · mst · effective_from · verified_at · url` 을 보유한다.

### 채택하지 않은 field와 이유 (§20 후단 — 단순함 우선)

| field | 왜 안 넣었나 |
|---|---|
| `effective_to` | 현행 조문만 다루고 실효 조문을 보관하지 않는다. 필요해지면 그때 넣는다 |
| `confidence` | 전건 조문 원문 직접 인용이라 신뢰도 축이 상수다. 상수 field 는 정보가 없다 |
| rule 별 `verified_at` | 같은 날 같은 API 호출로 한 번에 취득했다. 문서 단위 값이 정확하다 |
| 버전 이력 / 승인 워크플로 | rule platform 이 된다. §20 이 금지 |

## 2. 불변식 — fail-closed

`ContractDecision::RuleSet#validate!` 가 로딩 시 강제한다. 위반은 예외이고, 조용히 건너뛰지 않는다.

| # | 거부 조건 | 예외 |
|---|---|---|
| 1 | 필수 9 field 중 하나라도 없음 (authority_source·source_locator·effective_from·outcome·title·verified_at·agency_scope·condition·rule_id) | `MissingProvenanceError` |
| 2 | `authority_source` 가 `sources` 에 없는 key | `UnknownSourceError` |
| 3 | `contract_types` 에 registry 에 없는 유형 (오타 rule 이 조용히 매칭 0 이 되는 것을 막는다) | `UnknownContractTypeError` |
| 4 | `agency_scope` 에 registry 에 없는 기관 | `InvalidRuleError` |
| 5 | 판정에 인용되는 fragment(의무·분리사유·공개의무)에 근거 없음 | `MissingProvenanceError` |

**13종 전건 양성대조가 테스트로 있다** (`rule_set_test.rb` `FAIL_CLOSED_CASES`).
각 조건을 일부러 위반시켜 실제로 예외가 나는지 확인한다 — 이게 없으면 "전건 근거 보유"는
검사가 아무것도 안 한 결과일 수도 있다.

**양성대조가 함께 있다** (`rule_set_test.rb`): 근거를 지운 규칙집을 넣으면 실제로 예외가 나는지,
없는 출처를 가리키면 잡는지 확인한다. 이게 없으면 "전건 근거 보유"는 검사가 아무것도 안 한
결과일 수도 있다.

> 이 검사는 처음에 실제로 아무것도 막지 않았다. `def source(key) = sources[key] or raise(...)` 로
> 썼는데 `or` 가 `def` 전체에 걸려 raise 가 영원히 실행되지 않았다. 검사처럼 보이지만
> 검사가 아니었고, **양성대조 테스트가 그것을 잡았다.**

## 3. 값 분류 (§21)

| 분류 | 대상 |
|---|---|
| `SOURCE_VERIFIED` | `contract_decision_rules.yml` 전건 (19) · `contract_thresholds.yml` 의 §25·§30 금액 · `contract_method_service.rb` 특례 임계 |
| `LEGACY_UNVERIFIED` | 낙찰하한율(89.745% · 89.495%) · `estimated_price_service.rb` 원가계산 비율 |
| `DERIVED` | `chatbot_controller.rb` 의 별도 계약방식 계산 경로 |
| `DISPLAY_ONLY` | 뷰 참고표 숫자 (판정에 쓰이지 않음) |

`LEGACY_UNVERIFIED` 는 **R2 판정 경로에 쓰이지 않으므로 손대지 않았다**(§21 후단 · §3).
다만 이들이 "공식 기준"으로 표시되고 있는지는 별도 확인이 필요하다 — 09 문서의 이월 항목으로 넘긴다.

## 4. 삭제한 값

| 값 | 위치 | 왜 |
|---|---|---|
| `cooperative: 협동조합 / threshold: 50000000` | `config/contract_thresholds.yml` | §25①5호바목 4)·§30①2호나목이 가리키는 것은 **사회적협동조합**(협동조합기본법 §2제3호). 일반 협동조합은 열거에 없다. **없는 자격을 특례로 두면 자격 없는 상대방과의 수의계약을 가능하다고 안내하게 된다** |
| `checkedCount >= 3` / `>= 2` | `split_contract_checker.html.erb` | 조문에 없는 임의 위험점수 (§27) |
| `최근 3개월` 합산 창 | 〃 | §7제2호는 12개월/회계연도 |

구 `special_enterprise=cooperative` 파라미터가 들어와도 자격을 인정하지 않고
`INSUFFICIENT_INFORMATION` 으로 떨어진다 — 회귀 테스트로 고정했다.
