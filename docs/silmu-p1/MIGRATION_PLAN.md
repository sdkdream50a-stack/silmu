# MIGRATION_PLAN — 운영 적용 계획

> §35: 운영 DB 에 직접 destructive 변경 금지. 이번 세션은 **development 에서만** 적용했다.
> 운영 실행은 자동으로 하지 않는다. 아래는 명령과 영향범위 문서다.

---

## 1. 스키마 변경 — 안전성 근거

3개 마이그레이션 모두 **additive · nullable · reversible**.

| 마이그레이션 | 변경 | 잠금 위험 |
|---|---|---|
| `20260905230000_add_provenance_to_audit_cases` | `audit_cases` 에 9컬럼 추가 + 인덱스 2 | 낮음 — nullable·기본값 없는 컬럼 추가는 PG 11+ 에서 즉시 완료 |
| `20260905230100_add_authority_metadata_to_contents` | 3테이블 × 4컬럼 + 인덱스 6 | 낮음 |
| `20260905230200_add_agency_scope_to_contents` | 3테이블 × 3컬럼 + 인덱스 6 | 낮음 — `default: []` 는 PG 11+ 에서 rewrite 없음 |

- 인덱스는 전부 `algorithm: :concurrently` (테이블 잠금 없음) → `disable_ddl_transaction!` 필요
- `strong_migrations` 게이트를 **우회하지 않았다**. `safety_assured` 미사용
- 기존 컬럼 삭제·타입 변경·NOT NULL 추가 **0건**

### 검증 완료
```
bin/rails db:rollback STEP=3   # 3개 전부 reverted
bin/rails db:migrate           # 3개 전부 migrated
bin/rails test test/models/authority_schema_test.rb   # ADDITIVE 보존 검사 통과
```

---

## 2. 실행 순서 (운영)

```bash
# ── 0. 백업 (필수) ──
pg_dump -Fc silmu_production > silmu_$(date +%Y%m%d_%H%M).dump

# ── 1. 스키마 ──
RAILS_ENV=production bin/rails db:migrate
#   영향: 3테이블에 16컬럼 추가. 기존 행 변경 0. 다운타임 없음.
#   롤백: RAILS_ENV=production bin/rails db:rollback STEP=3

# ── 2. dry-run (DB 변경 없음) ──
RAILS_ENV=production bin/rails silmu:p1:provenance_dry_run
RAILS_ENV=production bin/rails silmu:p1:agency_dry_run
#   산출: tmp/silmu_p1_provenance_backfill.csv, tmp/silmu_p1_agency_scope.csv
#   ⚠️ 여기서 멈추고 CSV 를 사람이 확인한다. 특히:
#        · confidence=MEDIUM 행 (자동 적용되지 않음 — 검토 대상)
#        · proposed_source_type=ACTUAL_AUDIT 인데 proposed_source_url 이 빈 행 (있으면 안 됨)

# ── 3. backfill (HIGH confidence 만) ──
RAILS_ENV=production bin/rails silmu:p1:provenance_backfill
RAILS_ENV=production bin/rails silmu:p1:agency_backfill

# ── 4. 누출 검증 ──
RAILS_ENV=production bin/rails silmu:p1:leak_scan
#   기대: positive control OK · 실제 누출 0건
#   at_risk 수치는 경계가 막아낸 건수 (0이 아니어야 정상 — 0이면 검사 대상이 없다는 뜻)
```

### backfill 이 쓰는 컬럼 (그 외는 건드리지 않음)
`source_type` `source_agency` `source_title` `source_url` `source_year` `source_page`
`source_reference` `is_reconstructed` `provenance_confidence` `verification_status`
`verification_note` `target_agency` `jurisdiction` `agency_scope_confidence`

**읽기만 하는 컬럼(무변경):** `source` `verification_source` `verification_method` `last_verified_at` `legal_basis` `sector` `org_type` 및 모든 본문 컬럼.

`update_columns` 를 쓰므로 콜백·검증이 돌지 않는다 → IndexNow ping·캐시 무효화가 발생하지 않는다(의도적: 본문이 바뀌지 않았으므로 재색인 신호를 보내면 안 된다).

---

## 3. 롤백

| 상황 | 조치 |
|---|---|
| backfill 결과가 잘못됨 | 신규 컬럼만 비우면 된다. 앱은 신규 컬럼이 비어도 **보수적 기본값**으로 동작한다(`effective_source_type → UNVERIFIED`, `effective_verification_status → UNVERIFIED`) |
| 스키마를 되돌려야 함 | `db:rollback STEP=3`. 기존 컬럼·데이터 무손실 |
| UI 만 되돌리고 싶음 | 뷰 변경분만 revert. 모델·서비스는 남아 있어도 무해 |

**기존 데이터가 파괴되는 경로는 없다.** 신규 컬럼만 쓰고, 원본 `verification_source` 는 복사만 했다.

---

## 4. 운영과 dev 의 차이 (반드시 재측정)

| 대상 | dev | 운영 |
|---|---:|---:|
| audit_cases | 191 | **257** |
| topics | 92 | **114** |
| guides | 103 | **107** |

**dev 기준 수치를 운영 보고로 쓰면 안 된다.** 운영에서 dry-run 을 다시 돌리고 그 CSV 를 정본으로 삼는다.
특히 P0 에서 관측된 `GOE 2021 … (조문번호 명시 없음 — 차후 정밀화 backlog)` 유형 17건 중 `source` jsonb 가 비어 있는 행은 **MEDIUM 으로 떨어져 자동 승격되지 않는다** — 그 수를 CSV 에서 확인해야 한다.

---

## 5. 배포 순서 권장

1. 마이그레이션만 먼저 배포 (코드는 신규 컬럼이 비어도 동작)
2. dry-run → CSV 검토
3. backfill
4. `leak_scan` 통과 확인
5. 뷰 변경 포함 배포

1과 5를 나누면 backfill 결과를 보고 UI 노출 시점을 조절할 수 있다.
