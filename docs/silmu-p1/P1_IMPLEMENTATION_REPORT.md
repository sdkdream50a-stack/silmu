# P1_IMPLEMENTATION_REPORT — Authority Trust Layer 구현 보고

> 세션 2026-09-05 · 대상 `/Users/seong/project/silmu` · 선행 `docs/silmu-audit/` (P0 감사)
> 목표: **"왜 이 답을 믿어도 되는가"를 사용자가 즉시 확인할 수 있게 한다.**
> 순서: PROVENANCE → AUTHORITY → SCOPE → FRESHNESS

---

## 0. 한 줄 요약

> P0 는 "감사사례 257건에 공식 원문 링크가 0건"이라고 보고했다. **DB 를 열어보니 원문 URL·페이지·발행기관이 이미 들어 있었고, 화면에 렌더되지 않았을 뿐이었다.**
> 이번 P1 은 새 출처를 만들지 않았다. **이미 있던 사실을 보이게 만들었다.**

---

## 1. 착수 전 확인한 P0 정정사항 (§3)

| 정정 | 이번 세션에서 재확인한 사실 |
|---|---|
| A. 감사사례 근거 | 링크는 0건이 맞지만 조문 표기 219건·`law.go.kr` 텍스트 94건이 있었다. **추가 확인**: `audit_cases.source` jsonb 에 원문 URL·페이지·발행기관을 가진 행이 **86건**(로컬 dev 기준) 존재했고 뷰에서 한 번도 읽히지 않았다 (`grep` 결과 `show.html.erb` 는 `verification_source` 만 참조). |
| B. AI | `ai_assistant_channel.rb:31-44` 의 주입 코드는 정상이고, JS(`ai_chat_controller.js`)→채널(`ask`) 파라미터명도 일치한다. **버그가 아니라 진입점 부재**다. §30 에 따라 코드를 바꾸지 않았다. |

### 이번 세션에서 발견한 P0 의 추가 오류 (자기정정)
P0 `TRUST_RISK_REGISTER` TR-02 는 `"5단계"가 무엇인지 사이트 어디에도 설명이 없었다` 고 적었다. **틀렸다.**
`app/views/home/about.html.erb:112-140` 에 5단계가 항목별로 정의되어 있다.
- 실제 결함은 ① 배지에서 그 설명으로 **도달할 수 없었고** ② 그 정의 자체가 "법령 콘텐츠" 검증인데 **사례 사실관계 검증으로 읽혔다**는 것이다.
- 코드 주석과 배지 문구를 이 사실에 맞게 정정했고, 배지에서 `/about` 으로 가는 링크를 추가했다.

---

## 2. 구현 범위 (§4)

| # | 항목 | 상태 |
|---|---|---|
| P1-1 | Provenance Model | ✅ 구현 |
| P1-2 | Audit Case Trust UI | ✅ 구현 |
| P1-3 | Internal Metadata Leak Removal | ✅ 구현 |
| P1-4 | Authority / Legal Reference UI | ✅ 구현 |
| P1-5 | Tool Trust Metadata | ✅ 구현 |
| P1-6 | Freshness / Verification Foundation | ✅ 스키마·UI 구현 / cron 복원은 **DO_NOT_ENABLE** |

일반행정 콘텐츠 생성·홈 개편·RAG·크롤링은 하지 않았다 (§29).

---

## 3. 마이그레이션 (§5·§35)

3개, 전부 **additive · nullable · reversible**. `db:rollback STEP=3` → `db:migrate` 왕복 검증 완료.

| 마이그레이션 | 대상 | 컬럼 |
|---|---|---|
| `20260905230000_add_provenance_to_audit_cases` | audit_cases | `source_type` `source_agency` `source_title` `source_url` `source_year` `source_page` `source_reference` `is_reconstructed` `provenance_confidence` |
| `20260905230100_add_authority_metadata_to_contents` | topics·guides·audit_cases | `verification_status` `verification_note` `effective_at` `review_due_at` |
| `20260905230200_add_agency_scope_to_contents` | topics·guides·audit_cases | `target_agency`(array) `jurisdiction` `agency_scope_confidence` |

- `strong_migrations` 게이트를 우회하지 않았다. `change_table bulk` 는 검사 불가로 거부되어 개별 `add_column` + `add_index algorithm: :concurrently` 로 다시 썼다.
- **기존 컬럼은 하나도 삭제·변경하지 않았다** (`test/models/authority_schema_test.rb` 가 강제).
- `is_reconstructed` 는 의도적으로 nullable — `null`(미판정)과 `false`(실제 사례로 확인)를 구분한다.

---

## 4. 아키텍처 — 단일 렌더 경계

```
   DB (원본 그대로 보존)
     ├── verification_source  ← 내부 로그가 섞여 있던 자유 문자열
     ├── verification_note    ← 내부 전용으로 무손실 이관
     └── source(jsonb) / source_* / legal_basis
                    │
                    ▼
        ┌────────────────────────────┐
        │   AuthorityPresenter       │  ← 공개로 나가는 유일한 통로
        │   + InternalMetadataFilter │  ← 여기서 내부 문자열 차단
        └────────────────────────────┘
                    │
      ┌─────────────┼─────────────┬──────────────┐
      ▼             ▼             ▼              ▼
 _verification  _provenance  _authority_    _legal_
   _badge        _banner       source       references
      │
      └── (도구) _tool_trust ← ToolTrust ← config/tool_trust.yml + 기준값 YAML
```

**핵심:** Guide/Topic/AuditCase/Tool 이 각자 출처를 그리지 않는다. 경계가 하나라서 회귀 테스트도 하나로 강제된다.

---

## 5. 신규·변경 파일

### 신규 (16)
```
db/migrate/20260905230000_add_provenance_to_audit_cases.rb
db/migrate/20260905230100_add_authority_metadata_to_contents.rb
db/migrate/20260905230200_add_agency_scope_to_contents.rb
app/models/concerns/authority_metadata.rb
app/models/concerns/agency_scope.rb
app/models/concerns/audit_case_provenance.rb
app/services/internal_metadata_filter.rb
app/services/legal_reference_resolver.rb
app/services/audit_case_provenance_classifier.rb
app/services/agency_scope_classifier.rb
app/services/tool_trust.rb
app/presenters/authority_presenter.rb
app/views/shared/_provenance_banner.html.erb
app/views/shared/_authority_source.html.erb
app/views/shared/_legal_references.html.erb
app/views/shared/_tool_trust.html.erb
config/tool_trust.yml
lib/tasks/silmu_p1_authority.rake
```

### 변경 (8)
```
app/models/audit_case.rb        concern 3개 include
app/models/topic.rb             concern 2개 include
app/models/guide.rb             concern 2개 include
app/controllers/audit_cases_controller.rb   show 에 @authority
app/controllers/topics_controller.rb        show 에 @authority
app/views/shared/_verification_badge.html.erb  검증 범위 표시로 재작성
app/views/shared/_tool_next_actions.html.erb   도구 신뢰 레이어 단일 삽입점
app/views/audit_cases/show.html.erb / topics/show.html.erb / guides/show.html.erb  컴포넌트 배선
```

### 테스트 (6 신규)
```
test/services/internal_metadata_filter_test.rb
test/services/legal_reference_resolver_test.rb
test/services/authority_classifier_test.rb
test/services/tool_trust_test.rb
test/models/audit_case_authority_test.rb
test/models/authority_schema_test.rb
test/integration/public_metadata_leak_test.rb
```

---

## 6. 하지 않은 것 (의도적)

| 항목 | 이유 |
|---|---|
| `LegalComplianceJob` cron 복원 | **DO_NOT_ENABLE** — `FRESHNESS_JOB_REPORT.md` 참조 |
| AI 배선 변경 | 버그가 아니라 진입점 부재. §30 범위 밖 — `P2_RECOMMENDATION.md` 에 1줄 변경안 기록 |
| 전역 푸터 면책 문구 수정 | "자동 검증을 운영하고 있으나" 라는 **현재 사실과 다른 문장**이 있으나, 회사 운영에 관한 법적 고지 문구라 임의 수정하지 않고 결정 요청으로 남김 |
| 운영 DB backfill 실행 | §35 — dev 에서만 적용. 운영 실행 명령과 영향범위는 `MIGRATION_PLAN.md` |
| MEDIUM/LOW confidence 자동 적용 | §27 — 부정확한 metadata 는 빈 metadata 보다 위험 |
