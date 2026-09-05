# AGENCY_SCOPE_REPORT — 적용 기관 범위 기반

> P0 실측: 콘텐츠 549건 중 **352건(64%)** 이 "어느 기관에 적용되는지" 판별 불가.
> 이번 단계 원칙(§23): **전부 AI 추론으로 채우지 않는다. 스키마·UI 기반만 만들고 HIGH confidence 만 backfill.**

---

## 1. 스키마

`topics` · `guides` · `audit_cases` 3개 테이블에 추가 (additive·nullable):
```
target_agency            string[] default []   # CENTRAL_GOVERNMENT / LOCAL_GOVERNMENT / EDUCATION_OFFICE /
                                               # EDUCATION_SUPPORT_OFFICE / PUBLIC_SCHOOL / PRIVATE_SCHOOL / PUBLIC_INSTITUTION
jurisdiction             string                # NATIONAL / LOCAL / EDUCATION / BOTH / INSTITUTION
agency_scope_confidence  string                # HIGH / MEDIUM / LOW
```

---

## 2. 분류 신호 — 구조적인 것만 쓴다

| 우선순위 | 신호 | confidence |
|---|---|---|
| ① | 기존 `sector` / `org_type` enum (사람이 이미 분류한 값) | HIGH |
| ② | `legal_basis` 가 **관할이 법으로 규정된 법령만** 인용 | HIGH |
| ③ | 그 외 | LOW → 변경하지 않음 |

본문 키워드 빈도 같은 약한 신호는 **쓰지 않는다.**

### 판정 보류 규칙 (중요)
- `sector=edu` 인데 `org_type` 이 없으면 → **보류.** 학교인지 교육청인지 알 수 없다.
- `legal_basis` 에 교육 법령이 섞이면 → **보류.** 학교/교육청 구분이 필요하다.
- 국가 전용 법령과 지방 전용 법령이 **함께** 인용되면 → **보류.** 어느 쪽 독자인지 알 수 없다.
  (P0 TR-06 이 정확히 이 상황이었다 — 국가·지방을 함께 말하면서 적용 대상을 밝히지 않은 85건)

---

## 3. 결과 (dev DB)

```
$ bin/rails silmu:p1:agency_dry_run    # DB 변경 없음
$ bin/rails silmu:p1:agency_backfill   # HIGH 만 적용
AuditCase agency backfill: applied=165 skipped=26
Topic     agency backfill: applied=10  skipped=82
Guide     agency backfill: applied=0   skipped=103
```

| 대상 | 전체 | HIGH 해결 | 미해결(UNSPECIFIED 유지) |
|---|---:|---:|---:|
| AuditCase | 191 | **165** (86%) | 26 |
| Topic | 92 | **10** (11%) | 82 |
| Guide | 103 | **0** | 103 |
| **합계** | 386 | **175** | 211 |

해결된 기관 분포 (AuditCase): `PUBLIC_SCHOOL` 86 · `LOCAL_GOVERNMENT` 78 · `CENTRAL_GOVERNMENT` 1

**Guide 0건은 결함이 아니다.** `guides` 에는 `sector` 는 있으나 `legal_basis` 컬럼이 없어 ② 신호를 쓸 수 없고, `sector` 대부분이 `common` 이라 ① 신호도 서지 않는다. 추측하지 않고 비워 두었다.

---

## 4. UI (§24)

`show_agency_scope?` 가 `true` 일 때만 표시한다 — 조건은 `target_agency` 존재 **AND** `agency_scope_confidence == "HIGH"`.

```
적용 대상
공립학교
```
```
적용 대상
지방자치단체
```

**MEDIUM 이하는 화면에 나가지 않는다.** 회귀 테스트 `"HIGH confidence 가 아니면 적용 대상을 표시하지 않는다"` 가 강제한다.
근거 없이 "전국 공통"으로 표시하는 경로는 만들지 않았다.

---

## 5. 검증된 샘플

| slug | 판정 | 근거 |
|---|---|---|
| `silmu-2026-position-suspension-senior-officer-review` | CENTRAL_GOVERNMENT | `legal_basis` 가 `국가공무원법 제73조의3 …(고위공무원 적격심사)` 만 인용 |
| `goe-2021-management-allowance-mispayment` | PUBLIC_SCHOOL | `sector=edu` + `org_type=school` |
| (국가·지방 혼재 사례) | 보류 | `지방공무원법 / 국가공무원법` 동시 인용 → LOW |

## 6. 남은 일
- Topic 82건 · Guide 103건은 사람 판정이 필요하다 (CSV `silmu_p1_agency_scope.csv` 를 검토 큐로)
- `AGENCY_RULE_MODEL.md` 의 `COMMON_RULE + OVERRIDE` 상속 모델은 아직 미구현 — 이번엔 "적용 대상 표시"까지만
- `Guide` 에 `legal_basis` 상당 필드가 없어 신호가 부족하다. `topic_slug` 연결을 통한 상속을 검토할 수 있다
