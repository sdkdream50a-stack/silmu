# P1_BACKFILL_PRODUCTION — 운영 provenance backfill

> §7·§8 — dry-run → 게이트 확인 → HIGH confidence 만 write.

---

## 1. Preflight (쓰기 없음)

```
$ bin/kamal app exec --reuse 'bin/rails silmu:p1:preflight'
P1 BACKFILL PREFLIGHT  env=production  db=silmu_production

[1] 대상 규모     audit_cases=257 · topics=114 · guides=103
[2] 분류          confidence: {HIGH: 257}
                  source_type: {SILMU_RECONSTRUCTED_CASE: 110, UNVERIFIED: 61, ACTUAL_AUDIT: 86}
[3] 재실행 안전성  source_type 채워진 행 0 / 257 → 멱등
[4] 위험 점검     ACTUAL_AUDIT + 원문 URL 결손: 0건 ✅
                  MEDIUM (자동 적용 안 됨): 0건
                  공개 렌더 경계 누출: 0건 ✅
[6] 판정          PREFLIGHT_OK
                  ⚠️ ACTUAL_WRITE=0
```

### dev 예측 vs 운영 실제
| | dev(191) | 운영 예측 | **운영 실제(257)** |
|---|---:|---:|---:|
| ACTUAL_AUDIT | 86 | 86 | **86** ✅ |
| SILMU_RECONSTRUCTED_CASE | 63 | — | **110** |
| UNVERIFIED | 42 | 약 108 | **61** |

재구성 사례 110건은 **P0 감사가 공개 HTML 에서 센 110건과 정확히 일치한다** — 독립 경로로 얻은 두 수치의 교차 검증.
`UNVERIFIED` 는 예측(108)보다 적었다. 예측은 "늘어난 66건이 전부 미분류"라고 가정했으나, 실제로는 상당수가 재구성 공시 문자열을 갖고 있었다.

## 2. §7 요구 기록

| 항목 | 값 |
|---|---:|
| TOTAL | 257 |
| ACTUAL_AUDIT | 86 |
| RECONSTRUCTED | 110 |
| UNVERIFIED | 61 |
| HIGH confidence | **257** |
| MEDIUM | **0** |
| LOW | **0** |
| rows changed | 257 |
| rows unchanged | 0 |
| unexpected values | **0** |

## 3. §8 Write Gate

| 조건 | 판정 | 근거 |
|---|:--:|---|
| dry-run deterministic | ✅ | 멱등 (같은 입력 → 같은 분류), 재실행 안전 |
| MEDIUM = 0 or reviewable | ✅ | 0건 |
| LOW = 0 automatic writes | ✅ | 분류기가 HIGH 만 적용 |
| public metadata leak regression | ✅ | preflight 누출 0 · leak_scan positive control OK |
| backup verified | ✅ | `prewrite_20260905_153316.dump` 무결성 확인 |
| rollback documented | ✅ | `BACKUP_ROLLBACK.md` §4 |

→ **WRITE 허용**

## 4. dry-run CSV 표본 (운영)

```csv
content_id,slug,old_source,proposed_source_type,…,confidence,reason,requires_review
audit_case:1,private-contract-over-limit,"공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: 지방계약법 시행령 제25조. 운영 정합",SILMU_RECONSTRUCTED_CASE,,,LEGAL_REFERENCE_VERIFIED,HIGH,콘텐츠가 스스로 재구성 사례임을 명시 (verification_source 에 '특정 실사례 아님'),false
```
`old_source` 에 `운영 정합` 같은 내부 표현이 그대로 보이지만, 이것은 **CSV(내부 리포트)** 이며 공개 렌더에는 나가지 않는다(그것이 P1 경계의 목적이다).

MEDIUM 행 검색 결과 **0건**.

## 5. 실행

```
$ bin/rails silmu:p1:provenance_backfill
provenance backfill: applied=257 skipped(non-HIGH)=0

$ bin/rails silmu:p1:agency_backfill
AuditCase agency backfill: applied=210 skipped=47
Topic     agency backfill: applied=15  skipped=99
Guide     agency backfill: applied=0   skipped=103

$ bin/rails silmu:p1:leak_scan
positive control: OK (알려진 누출 문자열을 차단함)
leak_scan: 검사 474건 · 경계가 막아낸 at_risk 287건 · 실제 누출 0건
```

### 적용 결과 (운영 DB 직접 확인)
```
audit_cases.source_type   ACTUAL_AUDIT 86 · SILMU_RECONSTRUCTED_CASE 110 · UNVERIFIED 61
표본:
  private-contract-over-limit            SILMU_RECONSTRUCTED_CASE / LEGAL_REFERENCE_VERIFIED / is_reconstructed=t / HIGH
  goe-2021-management-allowance-mispayment ACTUAL_AUDIT / OFFICIAL_SOURCE_VERIFIED / is_reconstructed=f / HIGH
topics.agency_scope_confidence=HIGH  15건
```

**at_risk 287건** — 경계가 없었다면 운영 공개 화면에 내부 문자열이 나갔을 레코드 수다(dev 는 115건이었다).
이 수치가 0이 아니기 때문에 "누출 0"이 의미를 갖는다.

## 6. Guide 0건에 대하여

`Guide` 는 agency 판정 신호가 없어 0건이 적용되었다(dev 와 동일).
`guides` 에는 `legal_basis` 컬럼이 없고 `sector` 대부분이 `common` 이라 구조적 신호가 서지 않는다.
**추측하지 않고 비워 두는 것이 설계 의도다**(부정확한 metadata 는 빈 metadata 보다 위험).

## 7. 롤백

신규 컬럼만 비우면 된다. 앱은 컬럼이 비어도 보수적 기본값(`UNVERIFIED`)으로 동작한다.
기존 컬럼(`source`·`verification_source`·`legal_basis`)은 **읽기만 했고 변경하지 않았다.**
