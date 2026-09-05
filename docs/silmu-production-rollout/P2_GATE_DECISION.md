# P2_GATE_DECISION — 확장 게이트 판정

> §38·§39 — 실제 개정을 기다리기 위해 작업을 멈추지 않는다. 다만 정직하게 분류한다.

---

## 1. §38 Production Success Gate

| # | 조건 | 판정 | 근거 |
|:--:|---|:--:|---|
| 1 | P1 provenance rendering | ✅ | 운영 257건 backfill · 실제 페이지에서 🟢실제/📘재구성 배너 확인 |
| 2 | freshness tables | ✅ | 7개 테이블 생성 · 마이그레이션 6/6 |
| 3 | live official fetch | ✅ | 법제처 8/8 성공 · parse failure 0 |
| 4 | version creation | ✅ | immutable version 8건 · 실제 시행일 수집 |
| 5 | unchanged detection | ✅ | RUN 2 신규 0/0/0 (RUN 1 positive control 선행) |
| 6 | no false baseline alerts | ✅ | 기준선 8건 → 검토 태스크 0 · 공개 경고 0 |
| 7 | no content mutation | ✅ | 전수 SHA256 비교 · positive control 선행 |
| 8 | scheduler safety | 🟡 | 코드 요건 6/6 충족 · **아직 켜지 않음** |
| 9 | observability | ✅ | rake status (Admin UI 는 커밋됐으나 미배포 — R10) |
| 10 | review workflow | 🟡 | 모델·결정 5종·검증 이벤트 동작 · rake 로 검토 가능 · Admin UI 미배포(R10) |

**8/10 완전 충족 · 2건 부분(scheduler 미가동 · Admin UI 미배포)**
실제 개정 완주는 §39 에 따라 별도 판정한다.

## 2. §39 Real Revision Gate

```
실제 법령 개정 감지 → 검토 → 종결 완주 = 아직 없음
```
운영 수집 시점(2026-09-06)에 8개 문서 모두 변경이 없었다. **정상이다.**
fixture 를 실제 개정으로 가장하지 않았다 — 운영 DB 에는 실제 법제처 데이터만 있다.

## 3. 판정

```
P2_GATE = CONDITIONAL
```

### 지금 해도 되는 것 (§40)
```
P1.6 UI/UX 설계·구현
search architecture
navigation
homepage 개편
question taxonomy 설계
```

### 아직 대량 실행 금지
```
일반행정 콘텐츠 수백 개 생성
전국 기관 대량 ingestion
17개 교육청 전수 ingestion
```

### CONDITIONAL 해제 조건
- [ ] 스케줄러 등록 후 자연 주기 실행 2회 이상 무사고
- [ ] 실제 법령 개정 1건을 감지→검토→종결까지 완주
- [ ] 소스 연속 실패 알림 배선 (사람이 화면을 안 봐도 알 수 있게)

## 4. 잔여 위험

| # | 위험 | 성격 | 조치 |
|:--:|---|---|---|
| R1 | 스케줄러 미가동 — 사람이 수동 실행해야 함 | 운영 | 별도 승인 후 등록 |
| R2 | 소스 장애 알림 없음 | 운영 | 스케줄러보다 먼저 필요 |
| R3 | 콘텐츠 본문 4건에 내부 작업 표현(`Phase A #1` 등) | 원고 | 사람이 편집 (자동 수정 금지) |
| R4 | Cloudflare 캐시 4시간 — freshness 상태 반영 지연 | 운영 | 개정 대응 시 purge 절차 필요 |
| R5 | `Guide` 103건 전부 agency 미판정 | 데이터 | 신호 부족 — 추측하지 않음 |
| R6 | 조문 전문 미수집 — Level 3 diff 는 fixture 로만 검증 | 기능 | `LawApiService#fetch_law` 연동(P2) |
| R7 | UNSTRUCTURED(PDF/HWP) fetcher 없음 | 기능 | 교육청 확장 전 필요 |
| R8 | 동시 실행 락 없음 | 기능 | 단일 워커 구성이라 현실 위험 낮음 |
| R9 | `LawSyncJob` 은 파서 수정 후 재실행하지 않음 | 데이터 | `laws.effective_date` 여전히 NULL 15건 |
| R10 | **Admin 검토 UI 운영 미배포** — kamal buildx 3회 정지 | 인프라 | 빌더 재생성 후 재배포 (`ADMIN_REVIEW_UI.md` §6) |

R9 보충: 파서를 고쳤으므로 `LawSyncJob` 을 돌리면 `laws` 테이블이 채워진다.
다만 이 잡은 `laws` 테이블에 **쓰기** 때문에 이번 Phase 범위(read-only 검증) 밖으로 두었다.

## 5. 롤백 트리거 발생 여부 (§43)

```
5xx 증가                    없음 (18 URL 전부 2xx)
페이지 렌더 오류             없음
unexpected content mutation 없음 (전수 해시 비교)
duplicate versions/events   없음 (3회 실행 → version 8 유지)
false freshness warning     없음
source request storm        없음 (8요청 · 1s 간격)
DB lock/problem             없음
unexpected provenance overwrite 없음
```
**롤백 트리거 0건. 롤백 미실행.**
