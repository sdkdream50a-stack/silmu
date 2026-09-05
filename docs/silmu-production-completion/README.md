# silmu.kr P1.55B — Remote Safety + Source Failure Alerting

> 2026-09-06 · 안전한 지점에서 마감. P2 진입 없음. 스케줄러 여전히 OFF.

## 한 줄
> 운영 중인 코드가 **로컬 디스크에만 존재하던 재해복구 리스크를 해소**하고,
> 공식 출처가 **조용히 죽지 않도록** 3회 연속 실패 시 운영자에게 알리는 인프라를 운영에 배포했다.
> 콘텐츠는 한 글자도 자동 변경되지 않았다.

## 문서
| 문서 | 내용 |
|---|---|
| [GIT_REMOTE_RECOVERY.md](GIT_REMOTE_RECOVERY.md) | **운영 커밋 원격 복구지점 확보** (P1.55B 1순위) |
| [SOURCE_FAILURE_ALERTING.md](SOURCE_FAILURE_ALERTING.md) | 소스 장애 알림 **설계 정본** (P1.55B 에서 구현됨) |
| [SOURCE_FAILURE_IMPLEMENTATION.md](SOURCE_FAILURE_IMPLEMENTATION.md) | 구현 — additive 컬럼 2개 · 임계값 · 발동 지점 |
| [SOURCE_FAILURE_TESTS.md](SOURCE_FAILURE_TESTS.md) | 검증 — 9 tests · 뮤테이션 7/7 KILLED |
| [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) | 배포 게이트·스모크·콘텐츠 무변경 대조 |
| [BUILDER_RECOVERY.md](BUILDER_RECOVERY.md) | 배포 정지 근본원인 (P1.55B 에서 조건 재현·같은 우회 적용) |
| [ADMIN_UI_DEPLOYMENT.md](ADMIN_UI_DEPLOYMENT.md) | P1.55A 배포·게이트·스모크 |
| [EFFECTIVE_DATE_RECONCILIATION.md](EFFECTIVE_DATE_RECONCILIATION.md) | 시행일 정본 판정 · backfill 안 하는 이유 |
| [CLOUDFLARE_FRESHNESS_CACHE.md](CLOUDFLARE_FRESHNESS_CACHE.md) | 캐시 지연 (DESIGN_ONLY) |
| [EDITORIAL_MANUAL_REVIEW.md](EDITORIAL_MANUAL_REVIEW.md) | 사람 편집 대상 4건 |
| [P1_6_FINAL_HANDOFF.md](P1_6_FINAL_HANDOFF.md) | **UI Phase 인계** (P1.55B 재확인) |
| [TEST_REPORT.md](TEST_REPORT.md) | P1.55A 시점 353 runs 기록 |
| [RESUME_PROMPT.md](RESUME_PROMPT.md) | **다음 세션 시작점** |

## 상태 요약
```
운영 리비전    2d05bae (health 200)   ← 50c2624 에서 승격
원격 복구지점  origin/fix/tool-accuracy-p1-0804  ✅
origin/main   74056244 (무변경 — 이번 세션 미승인)
schema        20260906065000
테스트         362 runs / 2,731 assertions / 0F / 0E / 14 skips (신규 skip 0)
운영 콘텐츠    변경 0 (Topic/Guide/AuditCase sha256 배포 전후 동일)
스케줄러       DISABLED (별도 승인 필요)
P2_GATE       CONDITIONAL
```

## 알림 계약 한 눈에
```
1~2회 연속 실패  →  로그만
3회             →  운영자 메일 1회 (episode 당 1회, 중복 억제)
5회 이상        →  degraded — 잡이 건너뜀 (미발송이면 여기서도 알린다)
복구            →  episode 리셋 → 다음 장애에서 다시 알림
발송 실패        →  수집을 막지 않는다 · alerted_at 미기록 → 다음 주기 재시도
```
