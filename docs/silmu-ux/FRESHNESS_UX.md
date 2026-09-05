# FRESHNESS_UX — P1.6 Phase F

> §31~§35. Freshness 는 P1.6 에 **READ-ONLY** 다. business logic 은 한 줄도 건드리지 않았다.

## 1. 변경 범위

| 대상 | 변경 |
|---|---|
| `AuthorityFreshnessCheckJob` · `AuthorityChangeEvent` · `AuthorityVersion` · `ContentAuthorityLink` · `AuthorityReviewTask` · `LegalComplianceJob` · `RegulationVerifier` | **0줄** |
| 스케줄러 | **OFF 유지** (config/recurring.yml 무변경) |
| 마이그레이션 | **0건** |
| presenter/파셜 | 소비만. `_solution_status` 신설(읽기 전용) |

## 2. 표시 규칙 (§28 세 상태)

| 상태 | 화면 문구 | 근거 |
|---|---|---|
| CURRENT | ● 현재 기준 확인 · YYYY.MM.DD 검토 | `freshness_label` |
| CHANGE_DETECTED / REVIEW_REQUIRED | ⚠ 최신 개정사항 검토 중 | `freshness_attention?` |
| REVIEW_DUE / STALE_SUSPECTED / SOURCE_UNAVAILABLE | 재검증 예정일 경과 / 재검증 필요 / 공식 출처 확인 불가 | `stale?` |
| UNKNOWN | 확인 주기 미설정 | — |

## 3. 거짓 CURRENT 가 **구조적으로** 불가능한 이유 (§32)

문구를 view 에서 만들지 않고 `authority.freshness_label` 을 **그대로 출력**한다.
그 매핑(`AuthorityMetadata::FRESHNESS_LABELS`)은 `CURRENT` 일 때만 "현재 기준 확인"을 준다.
→ 상태가 CURRENT 가 아니면 그 문구가 나올 경로가 없다.

회귀로 고정:
```
CURRENT 가 아니면 '현재 기준 확인' 을 쓰지 않는다
확인 주기가 없으면 상태를 지어내지 않는다
```
뮤테이션 S1(문구 하드코딩) → **KILLED**.

## 4. 화면을 지배하지 않는다 (§31)

첫 화면에서는 **칩 1~3개**(적용 대상·현행성·시행일)뿐이다.
상세 배지·출처 블록·검토 안내는 기존 위치(본문 하단 사이드)에 그대로 둔다.

## 5. 노출하지 않는 것 (§36)

`diff` · `change_type` · `impact_class` · `version` · `freshness_state` ·
`last_change_event_id` · commit · batch · Phase · lawId · backlog → **공개 UI 0건**.
회귀 테스트가 이 문자열들의 부재를 단언한다(`solution_page_test`).
운영 경계 실측: `rake silmu:p1:leak_scan` → positive control OK · at_risk 115 · **실제 누출 0**.

## 6. 푸터 문구 (§7 인계) — 강화하지 않았다

`법령 변경을 자동 감지` / `항상 최신` / `실시간 현행화` 류 표현 **미사용**.
이유: `AuthorityFreshnessCheckJob` 스케줄러가 아직 꺼져 있다.
같은 이유로 primary nav 에 **"법령·변경" 항목을 넣지 않았다** — 라벨도 약속이다.
