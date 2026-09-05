# AUTHORITY_DATA_MODEL — 데이터 모델

## 1. AuthoritySource — 감시 대상 출처 (§16)

```
key                    안정 식별자 (moleg_law_api)
name / agency
source_type            STRUCTURED_API | STRUCTURED_HTML | UNSTRUCTURED_PDF | UNSTRUCTURED_HTML
authority_tier         1~4  (§7)
jurisdiction / region
official_url
fetch_strategy         law_api | http_html | http_pdf | manual
enabled
check_interval_hours   §23 — 소스마다 다르다
last_checked_at / last_success_at
failure_count / last_failure_kind / last_failure_message   §24·§25
config (jsonb)
```

`usable_for_currency_judgement?` → `authority_tier <= 3`.
**Tier 4(카페·블로그)는 현행성 판정 근거로 쓸 수 없다.** 질문 발굴에만 쓴다.

## 2. AuthorityDocument — 법령 identity (§6)

```
authority_source_id
key / official_identifier
document_type   CONSTITUTION LAW PRESIDENTIAL_DECREE MINISTERIAL_ORDINANCE
                LOCAL_ORDINANCE LOCAL_RULE DIRECTIVE REGULATION OFFICIAL_INSTRUCTION
                NOTICE PUBLIC_NOTICE ADMINISTRATIVE_RULE GUIDELINE MANUAL HANDBOOK
                FAQ OFFICIAL_INTERPRETATION AUDIT_STANDARD
title / short_title / agency / jurisdiction / region
current_version_id
status                       ACTIVE | REPEALED | UNKNOWN
has_transitional_provision   §10 — nullable(미판정 ≠ false)
transition_review_required
```

법령·규정·지침을 하나의 문자열로 취급하지 않는다. 법제처 `법령구분명` → `KOREAN_TYPE_MAP` 으로 매핑.

## 3. AuthorityVersion — 시점 snapshot · **IMMUTABLE**

```
authority_document_id
version_identifier   (법령일련번호 MST)
revision_number      (공포번호)
revision_kind        (제개정구분명)
promulgated_at       공포일
published_at
effective_at         시행일 ← §9 의 핵심
expires_at
fetched_at
source_url
content_hash         SHA256(normalized_content)
raw_metadata (jsonb)
normalized_content
```

**불변성 강제**
- `before_update` → `ImmutableError`
- `before_destroy` → 문서 연관 삭제일 때만 허용
- 개정은 덮어쓰기가 아니라 **새 행 추가**

**시행 판정**
```ruby
in_effect?(on)        # effective_at <= on < expires_at
future_effective?(on) # effective_at > on
effective_label       # "2026.06.03 시행" / "2026.11.01 시행 예정" / "시행일 미상"
```
시행일을 모르면 `in_effect? == false` — 모르는 것을 현행이라 단정하지 않는다.

## 4. AuthorityChangeEvent

```
authority_document_id
old_version_id / new_version_id
detected_at
change_type    NEW_DOCUMENT | CONTENT_CHANGED | METADATA_CHANGED
               | EFFECTIVE_DATE_CHANGED | REPEALED
diff_level     1 hash / 2 metadata / 3 조문 / 4 paragraph
diff_summary / machine_diff (jsonb)
effective_at
impact_status  PENDING | ANALYZED | NO_CONTENT_LINKED
review_status  OPEN | IN_REVIEW | RESOLVED
```

`baseline?` — `NEW_DOCUMENT` 는 개정이 아니라 기준선이다.
`already_in_effect?` — 시행 전 개정은 아직 현행 기준을 바꾸지 않는다.

## 5. ContentAuthorityLink — Impact Graph 간선 (§13)

```
content_type   Topic | Guide | AuditCase | Tool | Template
content_id     (AR 레코드)
content_key    (Tool/Template — 코드 기반이라 id 가 없다)
authority_document_id
article_reference / clause_reference
relationship_type  GOVERNED_BY | INTERPRETS | EVIDENCED_BY | CALCULATES_WITH
confidence         HIGH | MEDIUM | LOW
derivation_source  어떻게 만들어졌나 (감사 추적)
verified_at
```

유니크 인덱스: `(content_type, content_id, content_key, authority_document_id, article_reference)`

**HIGH 만 간선이 된다.** 추측 연결은 잘못된 영향 판정을 만든다.

## 6. AuthorityReviewTask — 검토 큐 (§27·§28)

```
authority_change_event_id
affected_type / affected_id / affected_key / affected_label
impact_class   DIRECT | INDIRECT | POSSIBLE | NO_IMPACT | UNKNOWN
impact_reason
priority       1(도구 직접) ~ 5
status         OPEN | IN_REVIEW
               | IMPACT_CONFIRMED | NO_IMPACT | UPDATE_REQUIRED
               | NEEDS_LEGAL_REVIEW | DEFERRED
assigned_to / reviewed_at / review_note
```

`decide!` 는 트랜잭션 안에서 ① 상태 갱신 ② 검증 이벤트 생성 ③ freshness 전이 ④ 이벤트 자동 종료를 수행한다.

## 7. AuthorityVerificationEvent (§29)

```
content_type / content_id / content_key
authority_version_id        ← 어떤 버전을 보고 판정했나
authority_review_task_id
reviewer / reviewed_at / result / note
```

콘텐츠의 `updated_at` 만으로 현행화 이력을 표현하지 않는다.

## 8. 콘텐츠 측 (기존 테이블에 additive)

`topics` · `guides` · `audit_cases`
```
freshness_state        §11 8상태
freshness_state_at
last_change_event_id
```
P1 의 `verification_status` · `effective_at` · `review_due_at` 는 그대로 살아 있고, 이 3개가 **엔진 관측값**을 담는다.

## 9. 마이그레이션 안전성

| 마이그레이션 | 성격 |
|---|---|
| `20260906010000_create_authority_freshness_core` | 신규 테이블 3 |
| `20260906010100_create_authority_change_and_impact` | 신규 테이블 4 |
| `20260906010200_add_freshness_state_to_contents` | 기존 3테이블에 nullable 컬럼 3 |

- `strong_migrations` 를 우회하지 않았다. 순환 FK 는 `add_foreign_key validate: false` + `validate_foreign_key` + `disable_ddl_transaction!` 권장 패턴 사용
- `db:rollback STEP=3` → `db:migrate` 왕복 검증 완료 (테이블 7 → 0 → 7)
- 기존 컬럼 삭제·변경 0
