# OBSERVABILITY — 관측

> §26 — 이번 단계는 **rake 출력**으로 시작한다. 가장 안전하고 되돌리기 쉽다.

## 1. `silmu:freshness:status`

```
[감시 소스]      key · tier · 유형 · enabled · 주기 · 마지막 검사/성공 · 연속실패(+종류)
[문서]          현행 버전 시행일 · 버전 수 · 연결 콘텐츠 수
[변경 이벤트]    전체 / 미분석 / 열림 · change_type 분포
[검토 큐]       열림 / 전체 · impact_class 분포 · status 분포
[콘텐츠 freshness] 클래스별 관측 수 / 전체 · 상태 분포
[검증 이벤트]    전체 · 최근 7일
```

§26 요구 항목 대응:
| 요구 | 위치 |
|---|---|
| 전체 감시 source | [감시 소스] |
| 마지막 성공 / 마지막 검사 | [감시 소스] |
| 실패 source | [감시 소스] 연속실패 + 종류 |
| 변경 감지 source | [변경 이벤트] |
| Review Required 수 | [검토 큐] 열림 |
| 최근 검증 완료 수 | [검증 이벤트] 최근 7일 |

## 2. `silmu:freshness:review_queue`

열린 태스크를 우선순위 순으로. `LIMIT=n` 지원.

## 3. `silmu:freshness:no_auto_publish_check`

엔진을 실제로 돌린 뒤 Topic/Guide/AuditCase 본문 스냅샷을 비교한다.
변경이 있으면 `abort`. CI 나 배포 후 스모크로 쓸 수 있다.

## 4. 잡 로그

```json
[AuthorityFreshness] {"checked":8,"unchanged":0,"changed":8,"failed":0,"tasks_created":0,"skipped_failing":0}
```
구조화 JSON 이라 로그 수집기에서 바로 집계할 수 있다.

## 5. 실패 가시성 (§24)

실패는 세 종류로 구분되어 `authority_sources` 에 남는다.
```
FETCH_FAILED        네트워크·HTTP 실패
PARSE_FAILED        응답은 왔으나 해석 실패 (검색 결과 0건 포함)
SOURCE_UNAVAILABLE  예외·서비스 장애
```
**어느 것도 "법령 삭제"로 해석되지 않는다.** 실패해도 `AuthorityVersion` 은 생성되지 않고 문서 `status` 는 `ACTIVE` 그대로다(회귀 테스트 있음).

`failure_count` 가 `MAX_CONSECUTIVE_FAILURES(5)` 를 넘으면 잡이 그 소스를 건너뛴다 — 무한 retry 금지(§25).
성공하면 카운터가 0으로 초기화된다.

## 6. 아직 없는 것

| 항목 | 상태 |
|---|---|
| Admin 화면 | P2 — `Admin::TopicReviewsController` 패턴 재사용 |
| 알림(메일/슬랙) | P2 — 구 `LegalComplianceMailer` 는 재사용하지 않는다(그 잡과 결합돼 있다) |
| 메트릭 익스포트 | P2 |
| 실행 이력 원장 | P2 — 현재는 로그만. `AuthorityChangeEvent` 가 사실상 이력 역할 |
