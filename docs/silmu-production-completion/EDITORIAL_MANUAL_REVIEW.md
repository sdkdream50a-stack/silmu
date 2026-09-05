# EDITORIAL_MANUAL_REVIEW — 사람 편집 대상

> §22. **AI 자동수정 금지.** 목록만 넘긴다.

## 1. 콘텐츠 본문 내 내부 작업 표현

P1.55 에서 운영 실측한 결과다. **이번 세션에서 재확인하지 않았다**(운영 DB 무변경 유지).

| 대상 | 건수 | slug |
|---|---:|---|
| AuditCase | 3 | `goe-2021-tenure-allowance-mispayment`<br>`goe-2021-overtime-allowance-mispayment`<br>`goe-2021-suspension-pay-deduction` |
| Topic | 1 | (P1.55 측정 시 1건 — slug 미기록) |
| Guide | 0 | — |

검출 패턴: `Phase [A-Z0-9]` · `batch [0-9]` · `backlog` · `커밋` · `commit `

실제 노출 예 (`/topics` 인덱스 JSON-LD `description`):
```
… 1,008,200원 과다 지급으로 5년 시효 환수 대상이 됩니다.
  Phase A #1 (호봉 누락·과소)의 대칭 사례입니다.
```

## 2. 왜 자동 수정하지 않는가

- P1 의 `InternalMetadataFilter` 는 **출처·검증 렌더 경계**를 지키는 장치다. 본문 원고는 그 대상이 아니다.
- 본문에서 문장을 지우면 의미가 달라질 수 있다. `Phase A #1 의 대칭 사례입니다` 는
  **다른 사례와의 관계**를 설명하는 문장이라 단순 삭제로는 정보가 사라진다.
- §22·§27 이 자동 수정을 금지한다.

## 3. 권장 편집 방향

```
"Phase A #1 (호봉 누락·과소)의 대칭 사례입니다."
  →  "호봉을 과소 인정한 사례와 방향만 반대인 같은 유형입니다."
```
내부 작업 단위(Phase/batch) 대신 **독자가 이해할 수 있는 관계 표현**으로 바꾼다.

## 4. 상태

```
ACTION = MANUAL_EDITORIAL_REVIEW_REQUIRED
건수 = 4 (AuditCase 3 · Topic 1)
자동 수정 = 하지 않음
```

## 5. 재측정 방법

```sql
select slug from audit_cases
 where issue ~* '(Phase [A-Z0-9]|batch [0-9]|backlog|커밋|commit )'
    or detail ~* '(Phase [A-Z0-9]|batch [0-9]|backlog|커밋|commit )'
    or lesson ~* '(Phase [A-Z0-9]|batch [0-9]|backlog|커밋|commit )'
    or action_taken ~* '(Phase [A-Z0-9]|batch [0-9]|backlog|커밋|commit )';
```
Topic 은 `summary` · `commentary` · `practical_tips` 를 같은 패턴으로 검사한다.
