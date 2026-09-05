# REVIEW_WORKFLOW — 검토 워크플로

## 1. 원칙 (§12)

> **"법령 변경 감지" ≠ "콘텐츠가 틀림"**

변경이 감지되면 `CHANGE_DETECTED` / `REVIEW_REQUIRED` 로 간다.
담당자가 "영향 없음"으로 판정할 수 있고, 그것도 정당한 결과다.

## 2. 상태 전이 (§47)

```
                    CURRENT
                       │ 근거 법령 변경 감지
                       ▼
              ┌─ 자동 NO_IMPACT ─► CURRENT
              │
        CHANGE_DETECTED / REVIEW_REQUIRED
                       │ 사람 판정
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   NO_IMPACT     IMPACT_CONFIRMED   UPDATE_REQUIRED
        │         NEEDS_LEGAL_REVIEW   DEFERRED
        ▼              │                │
VERIFIED_AFTER_CHANGE  └────────┬───────┘
                                ▼
                         REVIEW_REQUIRED (유지)
```

### 왜 `IMPACT_CONFIRMED` 가 VERIFIED 로 가지 않는가
영향이 **있다**고 사람이 확인한 콘텐츠에 "검증 완료" 배지가 붙으면,
그것은 P0 TR-02(재구성 사례에 검증 배지)와 같은 종류의 사고다.
**깨끗한 상태에 도달하는 유일한 경로는 "영향 없음" 판정뿐이다.**

회귀 테스트: `IMPACT_CONFIRMED 는 VERIFIED 로 가지 않는다 — 영향 있는 콘텐츠에 검증 배지 금지`

## 3. Reviewer 가 보는 것 (§27)

```bash
bin/rails silmu:freshness:review_queue
```
```
[P1] DIRECT    Tool / contract-method
     근거=지방계약법 시행령 변경=EFFECTIVE_DATE_CHANGED 시행일=2026-11-01
     사유=이 콘텐츠가 근거로 삼는 제25조 가 직접 변경되었습니다.
[P4] INDIRECT  AuditCase / 입찰공고 기간 미준수 사례
     근거=지방계약법 시행령 변경=EFFECTIVE_DATE_CHANGED 시행일=2026-11-01
     사유=같은 법령의 다른 조문(제25조)이 변경되었습니다. 제30조 에 대한 영향은 확인이 필요합니다.
```

무엇이 바뀌었는가 · 언제 시행되는가 · 어떤 콘텐츠가 영향받는가 · 왜 연결되었는가 — 네 가지가 모두 보인다.

## 4. 결정 (§28)

```ruby
task.decide!(decision: "NO_IMPACT", reviewer: "admin@silmu.kr", note: "인용 조문과 무관")
```

| 결정 | 의미 | freshness 결과 |
|---|---|---|
| `IMPACT_CONFIRMED` | 영향 있음 (아직 반영 전) | REVIEW_REQUIRED 유지 |
| `NO_IMPACT` | 확인했고 그대로 유효 | VERIFIED_AFTER_CHANGE |
| `UPDATE_REQUIRED` | 콘텐츠 수정 필요 | REVIEW_REQUIRED |
| `NEEDS_LEGAL_REVIEW` | 법무 검토 필요 | REVIEW_REQUIRED |
| `DEFERRED` | 보류 | REVIEW_REQUIRED |

알 수 없는 결정은 `ArgumentError` 로 거부한다.

## 5. `decide!` 가 하는 일 (트랜잭션)

1. 태스크 상태·검토자·시각·메모 갱신
2. `AuthorityVerificationEvent` 생성 — **어떤 버전을 보고 판정했는지** 포함
3. `ContentFreshnessUpdater.apply_decision` — freshness 3컬럼만 갱신
4. 해당 이벤트의 열린 태스크가 모두 없으면 `AuthorityChangeEvent` 를 `RESOLVED` 로 종료

**콘텐츠 본문은 어느 단계에서도 수정되지 않는다.**

## 6. 검증 이력 (§29)

```
AuthorityVerificationEvent
  content_type / content_id
  authority_version_id   ← 그때 본 버전
  reviewer / reviewed_at / result / note
```
콘텐츠의 `updated_at` 만으로 현행화 이력을 표현하지 않는다.
같은 콘텐츠가 여러 번 검증되면 이벤트가 쌓이고, 이력 전체를 되짚을 수 있다.

## 7. 현재 인터페이스

이번 단계는 **rake 출력**으로 시작한다(§26 — 가장 안전한 방식).
```bash
bin/rails silmu:freshness:review_queue   # 열린 태스크
bin/rails silmu:freshness:status         # 전체 관측
```

Admin 화면은 P2. 기존 `Admin::TopicReviewsController` 패턴을 그대로 쓸 수 있다
(`resources :topic_reviews do member { patch :resolve } end`).

## 8. 자동화하지 않는 것 (§15)

AI 는 **diff 요약 · 변경점 후보 추출 · 영향 가능성 제안 · review note 초안**까지만 허용된다.
현재 엔진은 AI 를 전혀 쓰지 않는다(규칙 기반 조문 매칭).

AI 가 할 수 없는 것:
```
게시 콘텐츠 자동 수정
법적 결론 자동 확정
NO_IMPACT 자동 판정
```
