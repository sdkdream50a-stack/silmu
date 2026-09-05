# IMPACT_GRAPH_SPEC — 영향 그래프

## 1. 구조 (§13)

```
       AuthorityDocument (지방계약법 시행령)
                  │
          ContentAuthorityLink
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
AuditCase       Tool         Topic/Guide/Template
  67건          10건            (아직 0)
```

법령이 바뀌면 이 간선을 역방향으로 따라 영향 가능 콘텐츠를 찾는다.

## 2. 현재 간선 (2026-09-06, dev)

| 문서 | 간선 | 구성 |
|---|---:|---|
| 지방계약법 시행령 | 77 | AuditCase 67 · Tool 10 |
| 지방계약법 | 32 | AuditCase 28 · Tool 4 |
| 지방공무원법 | 16 | AuditCase 16 |
| 지방공무원 보수규정 | 12 | AuditCase 12 |
| 지방회계법 | 11 | AuditCase 11 |
| 지방계약법 시행규칙 | 4 | AuditCase 4 |
| 지방공무원 복무규정 | 2 | AuditCase 2 |
| **합계** | **154** | AuditCase 140 · Tool 14 (도구 10종) |

## 3. 간선은 어떻게 만들어지나 (§42 — 새 지식을 만들지 않는다)

```
audit_cases.legal_basis  ──LegalReferenceResolver(P1)──►  canonical 법령명
                                                            │ HIGH confidence 만
config/tool_trust.yml    ──ToolTrust(P1)────────────────►  ─┘
                                                            ▼
                                              등록된 AuthorityDocument 와 title 일치?
                                                    ├ 예 → 간선 생성
                                                    └ 아니오 → 링크하지 않음
```

실측 (dry-run = 실제 적용, 수치 일치 검증됨):
```
생성 154 · 미해석(링크 안 함) 265 · 미등록법령(링크 안 함) 191 · 기존 0
```

- **미해석 265**: 자치법규·기관 내부지침·해석 불가 대용어. P1 의 `not_in_allowlist` 정책 그대로.
- **미등록법령 191**: 해석은 됐지만 아직 감시 대상으로 등록되지 않은 법령(공무원수당 규정 등). 소스를 늘리면 자동으로 간선이 된다.

**추측 연결을 하지 않는다.** 잘못된 간선은 잘못된 영향 판정을 만들고, 그것은 "검토했는데 놓쳤다"보다 나쁘다.

## 4. 영향 분류 (§14)

| 분류 | 조건 | 예 |
|---|---|---|
| `DIRECT` | 콘텐츠가 근거로 삼는 **바로 그 조문**이 변경 / 법령 폐지 | 제25조 근거 사례 + 제25조 개정 |
| `INDIRECT` | 같은 법령의 **다른 조문**이 변경 | 제30조 근거 사례 + 제25조 개정 |
| `POSSIBLE` | 조문 미지정 · 시행일 변경 · 메타데이터 변경 | 법령 단위만 연결된 도구 |
| `NO_IMPACT` | 영향 없음 (사람 판정) | — |
| `UNKNOWN` | **자동 판정 불가** | 변경은 있는데 조문 정보가 없음 |

> **확신할 수 없으면 `UNKNOWN` 으로 두고 사람에게 보낸다.** AI 가 추측으로 NO_IMPACT 를 주면 그 순간 이 시스템은 위험해진다.

실증 (조문 diff = 제25조 modified):
```
제25조 근거 감사사례  → DIRECT
제30조 근거 감사사례  → INDIRECT
제25조 근거 도구      → DIRECT (priority 1)
```

## 5. 우선순위

```
BASE = { DIRECT: 2, UNKNOWN: 3, INDIRECT: 4, POSSIBLE: 4, NO_IMPACT: 5 }
Tool/Template 이면 −1  →  최소 1
```

**priority 1 은 "도구·서식이 직접 영향" 에 예약한다.**
도구의 잘못된 값은 사용자가 그대로 기안에 옮기므로 다른 콘텐츠보다 위험이 크다(§34·§35).

## 6. Tool / Template 추적

`Tool` 과 `Template` 은 ActiveRecord 모델이 아니라 코드 기반이다.
그래서 `content_key`(예: `contract-method`)로 참조한다.

```
content_type = "Tool"
content_id   = nil
content_key  = "contract-method"
```

현재 추적 중인 도구 10종:
`contract-method` `contract-guarantee` `estimated-price` `predetermined-price`
`split-contract-checker` `contract-legality-check` `contract-documents` `contract-reason`
`qualification-evaluation` `budget-estimator`

**도구의 계산식은 자동으로 바뀌지 않는다.** `TOOL REVIEW REQUIRED` 태스크만 생성된다.
Template 은 아직 0건 — `config/tool_trust.yml` 과 같은 근거 등록부가 서식에는 없다(P2).

## 7. 멱등성

같은 변경 이벤트를 재분석해도 태스크가 중복 생성되지 않는다.
유니크 인덱스 `(authority_change_event_id, affected_type, affected_id, affected_key)` + `find_or_initialize_by`.
이미 만들어진 태스크는 **덮어쓰지 않는다** — 사람이 이미 판정 중일 수 있다.

## 8. 연결이 없을 때

`ContentAuthorityLink` 가 하나도 없으면 `impact_status = NO_CONTENT_LINKED`.
"영향 없음"이 아니라 **"아직 연결하지 못했다"** 는 뜻이다. 이 둘을 섞지 않는다.
