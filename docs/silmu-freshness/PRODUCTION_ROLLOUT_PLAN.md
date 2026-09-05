# PRODUCTION_ROLLOUT_PLAN — 운영 적용 계획

> §35·§40 — **production write 자동 실행 금지.** 이 문서는 명령과 영향범위이며, 실행은 별도 승인 단계다.

---

## 0. 이번 세션에서 운영에 한 일

**없다.** 모든 작업은 development DB 에서만 수행했다.
- `ACTUAL_WRITE (production) = 0`
- `config/recurring.yml` 무변경 (새 잡도 아직 스케줄에 넣지 않았다)

---

## 1. P1 backfill preflight 결과 (§40)

```bash
bin/rails silmu:p1:preflight     # 쓰기 없음
```
```
[1] 대상 규모      audit_cases=191 · topics=92 · guides=103   (운영은 257/114/107)
[2] 분류          confidence: {HIGH: 191}
                  source_type: {ACTUAL_AUDIT: 86, SILMU_RECONSTRUCTED_CASE: 63, UNVERIFIED: 42}
[4] 위험 점검      ACTUAL_AUDIT + 원문 URL 결손: 0건 ✅
                  MEDIUM (자동 적용 안 됨): 0건
                  공개 렌더 경계 누출: 0건 ✅
[6] 판정          PREFLIGHT_OK
```

⚠️ **dev 수치를 운영 보고로 쓰지 않는다.** 운영에서 preflight 를 다시 돌리고 그 결과를 정본으로 삼는다.
특히 P0 에서 관측된 `GOE 2021 … (조문번호 명시 없음 — 차후 정밀화 backlog)` 유형 17건 중
`source` jsonb 가 비어 있는 행은 **MEDIUM 으로 떨어져 자동 승격되지 않는다** — 그 수를 확인해야 한다.

---

## 2. 배포 단계

### Stage 1 — 스키마 (다운타임 없음)
```bash
pg_dump -Fc silmu_production > silmu_$(date +%Y%m%d_%H%M).dump
RAILS_ENV=production bin/rails db:migrate
```
- 신규 테이블 7 + 기존 3테이블에 nullable 컬럼 3
- 기존 컬럼 변경 0 · 인덱스는 `concurrently`
- 롤백: `db:rollback STEP=3`

**코드는 신규 테이블이 비어 있어도 동작한다.** `freshness_state` 가 nil 이면 P1 유도값으로 답한다.

### Stage 2 — P1 backfill (승인 필요)
```bash
RAILS_ENV=production bin/rails silmu:p1:preflight            # 판정 확인
RAILS_ENV=production bin/rails silmu:p1:provenance_dry_run   # CSV 검토
RAILS_ENV=production bin/rails silmu:p1:provenance_backfill
RAILS_ENV=production bin/rails silmu:p1:agency_backfill
RAILS_ENV=production bin/rails silmu:p1:leak_scan
```

### Stage 3 — 소스 등록 (읽기 전용 준비)
```bash
RAILS_ENV=production bin/rails silmu:freshness:seed_sources
```
소스 1 + 문서 8 등록. 아직 아무것도 수집하지 않는다.

### Stage 4 — 최초 수집 (기준선)
```bash
RAILS_ENV=production bin/rails silmu:freshness:check LIMIT=8
RAILS_ENV=production bin/rails silmu:freshness:status
```
기대: `changed=8` (전부 `NEW_DOCUMENT` 기준선), `failed=0`
**이 단계에서 생기는 8건은 개정이 아니다.** 기준선이므로 검토 태스크를 만들지 않아야 한다
(연결 간선이 아직 없으므로 `NO_CONTENT_LINKED`).

### Stage 5 — 영향 간선 생성
```bash
RAILS_ENV=production bin/rails silmu:freshness:build_links          # dry-run
RAILS_ENV=production bin/rails silmu:freshness:build_links APPLY=1
```
dev 기준 154건. 운영은 감사사례가 66건 더 많으므로 더 나온다.

### Stage 6 — 안전 확인
```bash
RAILS_ENV=production bin/rails silmu:freshness:no_auto_publish_check
```
기대: `NO_AUTO_PUBLISH: OK — 본문 무변경`

### Stage 7 — 스케줄 등록 (그 다음 주기)
`config/recurring.yml` 에 추가 — **Stage 4~6 이 성공한 뒤에만.**
```yaml
daily_authority_freshness:
  class: AuthorityFreshnessCheckJob
  schedule: "0 7 * * *"
```
⚠️ 구 `LegalComplianceJob` 주석은 **그대로 둔다.**

---

## 3. 롤백

| 상황 | 조치 |
|---|---|
| 수집 결과가 이상함 | `authority_versions` 는 immutable 이므로 지우지 않고 소스를 `enabled: false` 로 |
| 검토 큐가 과다 생성 | `AuthorityReviewTask` 는 콘텐츠에 영향 없음. 정리하거나 두어도 무해 |
| freshness 표시를 끄고 싶음 | 콘텐츠 3컬럼을 nil 로 → P1 유도값으로 되돌아감 |
| 스키마 되돌리기 | `db:rollback STEP=3` — 기존 데이터 무손실 |

**게시 콘텐츠가 손상되는 경로가 없다.** 최악의 경우에도 신규 테이블과 3개 컬럼만 정리하면 된다.

---

## 4. dev / production drift (§41)

**development DB 는 authority source 가 아니다.**

| | dev | 운영 |
|---|---:|---:|
| audit_cases | 191 | 257 |
| topics | 92 | 114 |
| guides | 103 | 107 |

- 공식자료 snapshot(`authority_versions`)은 **환경마다 독립적으로 수집**된다. dev 의 버전을 운영에 복사하지 않는다.
- 운영 수집 결과가 정본이다. dev 는 개발·테스트용이다.
- 이번 세션 중 dev DB 에서 P1 backfill 값이 한 번 소실됐다(초기 rollback 검증 시 P1 마이그레이션까지 되돌아감). 재적용해 복구했고, **운영에는 영향 없다.**

---

## 5. 승인 체크리스트

- [ ] 운영 백업 완료
- [ ] Stage 1 마이그레이션 · 앱 정상 동작 확인
- [ ] 운영 `silmu:p1:preflight` → `PREFLIGHT_OK`
- [ ] 운영 dry-run CSV 사람 검토 (MEDIUM 행 · ACTUAL_AUDIT URL 결손 0 확인)
- [ ] Stage 2 backfill + `leak_scan` 통과
- [ ] Stage 3~5 수집·간선 생성
- [ ] Stage 6 `no_auto_publish_check` 통과
- [ ] 1주기 관측 후 Stage 7 스케줄 등록
