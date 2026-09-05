# AUTHORITY_METADATA_SCHEMA — 권위 메타데이터 표준 V1

> 목표: 사이트의 모든 사실 주장에 대해 **"누가 정한 규칙인가 · 언제 기준인가 · 어느 기관에 적용되는가 · 우리가 얼마나 확인했는가"**를 기계가 읽을 수 있게 만든다.
> 원칙: **기존 컬럼을 최대한 재사용하고, 새 컬럼은 additive(nullable)로만 추가한다.** destructive migration 금지.

---

## 1. 이미 존재하는 것 (재사용)

`topics` · `guides` · `audit_cases` 세 테이블에 이미 있다:

```
last_verified_at      :datetime
verification_method   :string(32)
verification_source   :string(200)
sector                :integer   (기본 0)
org_type              :integer   (nullable)
```
`topics`에는 추가로 `law_base_date` `law_verified_at` `needs_review` `review_flagged_at` `review_reason`.
`audit_cases`에는 `source :jsonb` `legal_basis :string` `severity` `checkpoints :jsonb`.

> 권위 스키마의 **절반은 이미 구축되어 있다.** 문제는 스키마가 아니라 ① 값이 비어 있거나 ② 값의 의미가 섞여 있거나(TR-01) ③ 화면에 잘못 렌더된다는 것이다.

---

## 2. 표준 필드 정의 (V1)

### 2.1 식별·분류
| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `title` | string | ✅ | 기존 |
| `content_type` | enum | ✅ | `TOPIC` `GUIDE` `AUDIT_CASE` `TOOL` `TEMPLATE` `FAQ` `SERIES` |
| `domain` | enum | ✅ | 신 IA 15 도메인 (`NEW_INFORMATION_ARCHITECTURE.md` §2) |
| `task_key` | string | | 업무 단위 키 (`contract.private.small_amount` 등) |

### 2.2 적용 대상 (Agency Dimension) — **신규, 확장의 핵심**
| 필드 | 타입 | 필수 | 값 |
|---|---|---|---|
| `target_agency` | enum[] | ✅ | `CENTRAL_GOVERNMENT` `LOCAL_GOVERNMENT` `EDUCATION_OFFICE` `EDUCATION_SUPPORT_OFFICE` `PUBLIC_SCHOOL` `PRIVATE_SCHOOL` `PUBLIC_INSTITUTION` |
| `target_official_type` | enum[] | ✅ | `NATIONAL_OFFICIAL` `LOCAL_OFFICIAL` `EDUCATION_OFFICIAL` `PUBLIC_INSTITUTION_EMPLOYEE` `CONTRACT_WORKER` |
| `jurisdiction` | enum | ✅ | `NATIONAL` `LOCAL` `EDUCATION` `BOTH` `INSTITUTION` |
| `applicable_region` | string[] | | `ALL` 또는 시도 코드 배열 |
| `education_office` | string | | 특정 교육청 기준일 때만 |
| `school_type` | enum | | `PUBLIC` `PRIVATE` `NONE` |
| `fiscal_system` | enum | | `LOCAL_FINANCE` `SCHOOL_ACCOUNTING` `EDU_SPECIAL_ACCOUNT` `NATIONAL_FINANCE` |

> `target_agency`가 비면 발행 금지. 현재 **549건 중 352건이 UNSPECIFIED**이므로 backfill이 P1 최우선 작업이다.

### 2.3 근거 (Evidence)
| 필드 | 타입 | 설명 |
|---|---|---|
| `law` | ref[] | 법률 (`SOURCE_GRAPH_DESIGN.md`의 `LAW` 노드) |
| `enforcement_decree` | ref[] | 시행령 |
| `enforcement_rule` | ref[] | 시행규칙 |
| `administrative_rule` | ref[] | 훈령·예규·고시 |
| `official_guideline` | ref[] | 공식 편람·집행기준 |
| `official_source_url` | url | **원문 URL. 감사사례 257건 전부 결손(TR-01)** |
| `source_agency` | string | 법제처·감사원·행안부·교육부·조달청 등 |
| `source_tier` | enum | `TIER_1`~`TIER_4` (`SOURCE_HIERARCHY.md`) |

### 2.4 시간 (Temporal)
| 필드 | 타입 | 설명 |
|---|---|---|
| `effective_date` | date | 근거 규정의 시행일 |
| `law_base_date` | date | 콘텐츠가 기준으로 삼은 법령 시점 (기존 컬럼) |
| `verified_at` | datetime | 마지막 검증 시각 (= `last_verified_at`) |
| `verification_method` | enum | **아래 2.6으로 값 표준화 필요** |
| `last_updated_at` | datetime | 기존 `updated_at` |
| `review_due_at` | date | 다음 재검증 기한 (신규 — 배지 신선도 자기고발용) |

### 2.5 상태
```
authority_status ∈ {
  OFFICIAL_VERIFIED        # 공식 원문으로 1:1 대조 완료 + 원문 URL 보유
  OFFICIAL_PARTIAL         # 공식 근거는 있으나 일부(조문·페이지·적용대상) 미확정
  SECONDARY_SOURCE         # 2차 자료 기반
  COMMUNITY_DERIVED        # 커뮤니티에서 질문/이슈만 유래 (정답 근거 아님)
  SILMU_INTERPRETATION     # 실무.kr의 해석·판단 (도구 산출 포함)
  SILMU_RECONSTRUCTED_CASE # 공개 패턴을 일반화한 재구성 사례
  UNVERIFIED               # 미검증
  STALE_SUSPECTED          # review_due_at 경과 또는 근거 개정 감지
}

content_status ∈ { DRAFT, PUBLISHED, NEEDS_REVIEW, DEPRECATED, MERGED_INTO(:target) }
```

### 2.6 `verification_method` 값 표준화 (TR-01 직접 수정)

현재 운영 값은 자유 문자열이며 **사용자 화면에 그대로 노출**된다. 실측된 값에는
`Phase A~E batch 01~03 (commits eed3ceb..12dff5d)`, `법제처 OPEN API mcp spot check`, `sen_2025_audit_disclosure_dashboard` 같은 내부 로그가 섞여 있다.

**표준 enum으로 고정하고, 자유 문자열은 비공개 `verification_note`로 이관한다.**

| enum 값 | 사용자 표시 문구 |
|---|---|
| `OFFICIAL_API_MATCH` | 법제처 국가법령정보센터 원문과 1:1 대조 |
| `OFFICIAL_DOC_MATCH` | 공식 문서(감사보고서·편람) 원문 대조 |
| `EXPERT_REVIEW` | 실무 검토자 확인 |
| `PATTERN_GENERALIZATION` | 공개 사례 패턴 일반화 |
| `NONE` | 미검증 |

```
verification_note :text   # 신규, 관리자 전용. 커밋 해시·배치 ID·lawId는 전부 여기로.
```

### 2.7 사례 전용 (`audit_cases`)
`AUDIT_CASE_PROVENANCE_SPEC.md` 참조 — `provenance`, `original_document_url`, `page`, `disposition`, `audit_year`, `audit_name`.

---

## 3. 렌더 규칙 (화면 계약)

권위 배지는 **세 줄을 분리해서** 보여준다. 현재는 한 줄에 뭉쳐 있어 TR-01·TR-02가 발생한다.

```
[1] 무엇에 대한 검증인가   → "법령 근거 검증 완료"  (사례 사실관계 검증이 아님을 명시)
[2] 언제 기준인가         → "법령 기준일 2026-05-20 · 검토 2026-06-15 · 재검토 예정 2026-12-15"
[3] 무엇을 보고 확인했나   → "출처: 국가법령정보센터 지방계약법 시행령 제25조" + 원문 링크
```

**금지 규칙 (기계 검사 가능):**
1. `official_source_url`이 없으면 검증 배지를 **표시하지 않는다.**
2. `verification_note`(내부 문자열)는 **어떤 경우에도 공개 렌더에 들어가지 않는다.**
3. `provenance = SILMU_RECONSTRUCTED_CASE`이면 배지 문구에 "사례"라는 단어를 쓰지 않는다.
4. 금액·기한·비율이 본문에 있으면 같은 블록에 근거 조문 또는 `기준일`이 있어야 한다.

이 4개는 `lib/tasks/silmu_legal_lint.rake`를 확장해 CI 게이트로 만들 수 있다(이미 lint rake가 존재).

---

## 4. 마이그레이션 계획 (additive only)

```ruby
# 1) 신규 컬럼 — 전부 nullable, 기본값 없음. 기존 동작 무영향.
add_column :topics,      :target_agency,        :string, array: true, default: []
add_column :topics,      :target_official_type, :string, array: true, default: []
add_column :topics,      :jurisdiction,         :string
add_column :topics,      :applicable_region,    :string, array: true, default: []
add_column :topics,      :fiscal_system,        :string
add_column :topics,      :authority_status,     :string
add_column :topics,      :review_due_at,        :date
add_column :topics,      :verification_note,    :text
# guides / audit_cases 동일
# audit_cases 추가: provenance, original_document_url, source_page, disposition, audit_year, audit_name
```
- **인덱스는 backfill 이후에** 생성 (`(published, jurisdiction)`, `(published, authority_status)`).
- backfill은 `db/content_migrations/`의 기존 멱등 패턴을 그대로 쓴다 — 새 기계를 만들지 않는다.
- 기존 `verification_source`/`verification_method` 값은 **삭제하지 않고** `verification_note`로 복사한 뒤 표준 enum을 새로 채운다.

---

## 5. 완료 판정 (기계 검사)

| 게이트 | 조건 |
|---|---|
| G1 | 발행된 모든 콘텐츠에 `target_agency` 비어 있지 않음 |
| G2 | 검증 배지가 렌더된 모든 페이지에 `official_source_url` 존재 |
| G3 | 공개 HTML에 `commit`/`batch`/`lawId`/`backlog` 문자열 0건 |
| G4 | `provenance` 없는 `audit_case` 0건 |
| G5 | `review_due_at` 경과 항목은 배지에 "재검증 필요" 표시 |
