# 07 — BEFORE / AFTER 과업 테스트

> §28: 숫자 예시의 답을 미리 정하지 않고 실제 결과를 측정한다. §29: 경계·정보부족 케이스 포함.
> BEFORE = 운영 `ce62d2e` 실측 (`_data/reachability_prod.json`).
> AFTER = 로컬 구현 실측. 검색 도달성 축은 **검색 코드를 건드리지 않았으므로 BEFORE 와 같다.**

---

## 1. 일곱 과업

| # | 질문 | BEFORE | AFTER |
|---|---|---|---|
| 1 | 수의계약 한도 | Topic 4 · Tool 1 · 바로 답 = "한도 금액에 **부가세**가 포함되나요?"(곁가지). 도구는 유형·금액만 받고 기관 미표시 | 도구가 유형별 한도를 조문 위치와 함께 판정. 5개 유형 전부 2천만원에서 `POSSIBLE`. 기관 범위·시행일 표시. **검색 도달성은 불변**(Topic 4 · Tool 1) |
| 2 | 3000만원 물품 수의계약 가능한가 | Tool **0**. 도구 직접 입력 시 **"수의계약 / 2인 이상 견적"** 확정 — 같은 응답의 작은 글씨는 "일반 업체는 2천만원 초과 시 경쟁입찰 대상" | 상대방 미상 → `INSUFFICIENT_INFORMATION`(상대방을 묻는다) · 일반업체 → `COMPETITIVE_PROCEDURE_REQUIRED` · 청년창업/소기업/여성 → `POSSIBLE` · 사회적기업 → `POSSIBLE_WITH_CONDITIONS` |
| 3 | 5000만원 용역 수의계약 가능한가 | Tool 0 · 바로 답 = "**설계용역과 공사를 합산**해서…"(다른 질문) | 상대방별 5분기. 일반업체 = 경쟁입찰 |
| 4 | 공사를 나눠 계약해도 되나 | Topic **0** · Tool **0** · 도구에 적법 분리 경로 없음 | 금지요건 충족 → `HIGH_SPLIT_RISK` · §77①1호 주장 + 회피목적 아님 → `LEGITIMATE_SEPARATION_POSSIBLE` · 사실 미상 → `INSUFFICIENT_INFORMATION` |
| 5 | 같은 물품을 여러 번 나눠 사도 되나 | Topic 0 · Tool 0 · 도구는 **3개월** 창 + §77(공사 조항) 인용 | `HIGH_SPLIT_RISK` · 추정가격 **5,100만원(12개월 합산)** · 근거 **제7조제2호** |
| 6 | 분리발주와 분할발주의 차이 | Topic 0 · Tool 0 · 도구가 둘을 구분하지 못함 | 회피목적 아님 → `LEGITIMATE_SEPARATION_POSSIBLE` / 회피목적 → `HIGH_SPLIT_RISK` (근거 §77①·§77③). **같은 입력에서 이 축 하나로 결론이 갈린다** |
| 7 | 처음 계약을 맡았어요 | Topic 4 · Tool 0 | **변화 없음 — R2 범위 밖**(§24). R4 대상 |

> **1·2·3의 검색 도달성이 AFTER 에서도 그대로인 것은 의도된 것이다.** R2 는 검색 recall 을 건드리지
> 않았다(P1.6 동결). 4·5·6 의 Topic 0 도 그대로다 — 이를 해소하려면 콘텐츠(FAQ·keywords)를 바꿔야 하고
> 그건 이번 세션의 콘텐츠 변이 0 제약 밖이다. **05 문서에 사양으로 남겼다.**
> 바뀐 것은 **도구에 도달한 뒤 무엇을 답하는가**이다.

## 2. 경계·부정 케이스 (§29)

| 케이스 | 결과 |
|---|---|
| 정보 부족 (상대방 미상, 2천만 초과) | `INSUFFICIENT_INFORMATION` + `COUNTERPARTY_TYPE` 미해결 요인 |
| 기관 scope 불명 | `INSUFFICIENT_INFORMATION` + `AGENCY_SCOPE` |
| 기관 범위 밖 (국가기관·공공기관·사립학교) | `OUT_OF_SCOPE` + 어느 법이 적용되는지 |
| 계약유형 불명 (분할 도구) | `INSUFFICIENT_INFORMATION` — 어느 조문을 쓸지 정해지지 않음 |
| 금액 경계 2,000만 / 2,000만 1원 | `POSSIBLE` / `INSUFFICIENT_INFORMATION` |
| 금액 경계 4억 / 4억 1원 (종합공사) | `POSSIBLE` / `COMPETITIVE_PROCEDURE_REQUIRED` |
| 견적요건 경계 5,000만 / 5,000만 1원 (여성기업) | `SINGLE_ALLOWED` / `TWO_OR_MORE` |
| 견적서 생략 경계 200만 미만 / 200만 | 안내 있음 / **없음** (시행규칙 §33은 "미만") |
| 예외조건 미충족 (사회적기업 고용비율 false) | `COMPETITIVE_PROCEDURE_REQUIRED` |
| 예외조건 미확인 (고용비율 nil) | `POSSIBLE_WITH_CONDITIONS` + 미해결 요인 |
| 분할 의심이나 합리적 분리 가능 | `LEGITIMATE_SEPARATION_POSSIBLE` |
| 분할 사실은 있으나 동일 조달요구 아님 | `LOW_RISK` + `SELF_REPORTED` 단서 |
| 조문 목록에 없는 자격 (`cooperative`) | 자격 불인정 → `INSUFFICIENT_INFORMATION` |
| 금액·유형 미입력 | `INSUFFICIENT_INFORMATION` |

**어느 조합에서도 무조건 YES/NO 가 나오지 않는다** — 이것이 §29 의 합격 조건이다.

## 3. 검색어만 관련 있고 기능은 다른 경우 (§29 마지막 항)

P1.6 정밀도 가드가 그 축을 담당한다. R2 후 재측정:

| 질의 | Topic | Tool | 바로 답 |
|---|---:|---:|---|
| 차비 | 2 | 1 (여비계산기) | — (숙박비 답이 올라오지 않음) |
| 숙박비 지급 기준 | 2 | 0 | "숙박비 지급 기준은 어떻게 되나요?" ✅ |
| 지급 기준 | 4 | 0 | — (고유 토큰 없음) ✅ |
| 병가 | 1 | 0 | "공무원 일반 병가는 연간 며칠까지…" ✅ |
| 병가 진단서 | 1 | 0 | "병가에 진단서는 언제부터…" ✅ |

계약 도구가 무관 질의에 새로 붙지 않았다.
