# silmu.kr P1.55 — Authority & Freshness Production Rollout

> 2026-09-06 · 선행 P0 감사 → P1 Trust Layer → P1.5 Freshness Engine
> 목적: 신규 기능이 아니라 **운영에서 실제로 작동함을 증명**하는 것.

## 결과 한 줄
> P0·P1·P1.5 전부가 미커밋 상태였다. 5개 커밋으로 나눠 운영에 올렸고,
> 마이그레이션 6/6 · provenance backfill 257건 · 법제처 실수집 8건 · 무변경 대조 통과 ·
> **게시 콘텐츠 자동 변경 0건**을 확인했다. 스케줄러는 켜지 않았다.

## 문서
| 문서 | 내용 |
|---|---|
| [PRODUCTION_REALITY.md](PRODUCTION_REALITY.md) | 운영 실측 (dev 숫자를 정본으로 쓰지 않음) |
| [BACKUP_ROLLBACK.md](BACKUP_ROLLBACK.md) | 복구 준비 상태 §6 |
| [MIGRATION_ROLLOUT.md](MIGRATION_ROLLOUT.md) | 커밋·배포·마이그레이션 기록 |
| [PRODUCTION_SMOKE_TEST.md](PRODUCTION_SMOKE_TEST.md) | 18 URL 스모크 + 렌더 검증 |
| [P1_BACKFILL_PRODUCTION.md](P1_BACKFILL_PRODUCTION.md) | §7·§8 dry-run·게이트·실행 |
| [LAW_CONTENT_FETCHER_DECISION.md](LAW_CONTENT_FETCHER_DECISION.md) | §12~§14 선재 파서 결함 처분 |
| [CANARY_RUN_1.md](CANARY_RUN_1.md) | 첫 수집 (기준선, 거짓경고 0) |
| [CANARY_RUN_2.md](CANARY_RUN_2.md) | 무변경 대조 (0-claim gate) |
| [SCHEDULER_ACTIVATION.md](SCHEDULER_ACTIVATION.md) | 스케줄러 판정 = NOT_ENABLED |
| [OBSERVABILITY.md](OBSERVABILITY.md) | 운영 관측 §23 |
| [ADMIN_REVIEW_UI.md](ADMIN_REVIEW_UI.md) | 검토 큐 화면 §24·§25 |
| [FRESHNESS_UI_VERIFICATION.md](FRESHNESS_UI_VERIFICATION.md) | 공개 UI 검증 §28·§29 |
| [P2_GATE_DECISION.md](P2_GATE_DECISION.md) | **P2_GATE = CONDITIONAL** |
| [P1_6_HANDOFF.md](P1_6_HANDOFF.md) | UI Phase 인터페이스 계약 §35 |
| [RESUME_PROMPT.md](RESUME_PROMPT.md) | 다음 세션 |

## 핵심 수치 (운영)
```
마이그레이션      6/6 적용
provenance       ACTUAL_AUDIT 86 · RECONSTRUCTED 110 · UNVERIFIED 61  (= 257)
agency HIGH      AuditCase 210 · Topic 15 · Guide 0
누출 검사        474건 중 경계가 막아낸 at_risk 287 · 실제 누출 0
Authority        소스 1 · 문서 8 · 버전 8 · 간선 209
RUN 1            fetch 8/8 · 실패 0 · 검토태스크 0 · 거짓경고 0
RUN 2            신규 version 0 · event 0 · task 0
콘텐츠 자동변경   0 (전수 SHA256, positive control 선행)
스모크           18 URL 전부 2xx · 5xx 0
```
