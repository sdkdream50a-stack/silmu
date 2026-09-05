# CURRENT_FRESHNESS_ARCHITECTURE — 현행성 엔진 구조

> 2026-09-06 · 선행 `docs/silmu-audit/`(P0) · `docs/silmu-p1/`(P1)
> 원칙: **DETECT → VERSION → DIFF → IMPACT → REVIEW → VERIFY → PUBLISH**
> 그리고 **엔진은 게시 콘텐츠를 절대 수정하지 않는다.**

---

## 0. 한 줄

> 구 `LegalComplianceJob` 은 AI 출력으로 `topic.update!` 를 실행할 수 있었다.
> 새 엔진은 그 경로를 **구조적으로 갖지 않는다** — 쓰는 곳이 `authority_*` 테이블과 콘텐츠의 `freshness_state` 3개 컬럼뿐이고, 회귀 테스트가 이를 강제한다.

---

## 1. 파이프라인

```
 AuthoritySource (등록된 출처만)
        │  due? (소스별 주기)
        ▼
   FETCH  ── 실패 → FETCH_FAILED / PARSE_FAILED / SOURCE_UNAVAILABLE (구분해 기록)
        ▼
 NORMALIZE (공백·줄바꿈·HTML 껍데기만 — 의미는 손대지 않음)
        ▼
   HASH  (SHA256 of normalized)
        ▼
  COMPARE ── 동일 → NO_CHANGE (버전·이벤트 생성 안 함)
        ▼ 다름
 AuthorityVersion 생성 (IMMUTABLE)
        ▼
 AuthorityChangeEvent 생성
   change_type: NEW_DOCUMENT | CONTENT_CHANGED | METADATA_CHANGED
                | EFFECTIVE_DATE_CHANGED | REPEALED
        ▼
 ImpactAnalyzer ── ContentAuthorityLink 를 따라 영향 콘텐츠 탐색
        ▼          DIRECT / INDIRECT / POSSIBLE / NO_IMPACT / UNKNOWN
 AuthorityReviewTask 생성 (사람이 판정할 큐)
        ▼
 ContentFreshnessUpdater → 콘텐츠 freshness_state 만 갱신
        ▼
 [사람] AuthorityReviewTask#decide!
        ▼
 AuthorityVerificationEvent 기록 + 상태 전이
```

**PUBLISH 단계는 엔진에 없다.** 콘텐츠 수정은 사람이 별도로 한다.

---

## 2. 데이터 모델 (7 테이블)

| 테이블 | 역할 |
|---|---|
| `authority_sources` | 감시 대상 출처 등록부 · tier · 주기 · 실패 카운터 |
| `authority_documents` | 법령/규정 identity (무엇인가) |
| `authority_versions` | 시점 snapshot — **IMMUTABLE** (언제 무엇이었나) |
| `authority_change_events` | 무엇이 어떻게 바뀌었나 |
| `content_authority_links` | 콘텐츠 ↔ 근거 (Impact Graph 의 간선) |
| `authority_review_tasks` | 사람이 판정할 큐 |
| `authority_verification_events` | 누가 언제 어떤 버전을 보고 무엇으로 판정했나 |

`AUTHORITY_DATA_MODEL.md` 에 상세.

### 기존 `laws` 테이블을 쓰지 않은 이유
로컬·운영 모두 0행이고 어떤 코드도 참조하지 않으며, `source`·`content_hash`·불변성·버전 이력 개념이 없다.
identity(Document)와 snapshot(Version)을 한 테이블에 섞게 되므로 **재사용하지 않고 그대로 남겨 두었다**(삭제하지 않음).

---

## 3. 코드

| 계층 | 파일 |
|---|---|
| 모델 | `app/models/authority_{source,document,version,change_event,review_task,verification_event}.rb`, `content_authority_link.rb` |
| 수집 | `app/services/authority/law_api_fetcher.rb` · `fetch_result.rb` |
| 정규화 | `app/services/authority/normalizer.rb` |
| 비교 | `app/services/authority/diff_engine.rb` |
| 감지 | `app/services/authority/change_detector.rb` |
| 영향 | `app/services/authority/impact_analyzer.rb` |
| 간선 생성 | `app/services/authority/content_link_builder.rb` |
| 상태 | `app/services/content_freshness_updater.rb` |
| 스케줄 | `app/jobs/authority_freshness_check_job.rb` |
| 운용 | `lib/tasks/silmu_freshness.rake` |
| 공개 UI | `app/views/shared/_freshness_notice.html.erb` |

---

## 4. P1 자산 재사용 (§42)

새 지식을 만들지 않았다.

| 재사용 | 용도 |
|---|---|
| `LegalReferenceResolver` (P1) | `audit_cases.legal_basis` → 법령 식별 → Impact Graph 간선. **HIGH confidence 만** |
| `ToolTrust` + `config/tool_trust.yml` (P1) | 도구 계산 근거 → 간선 |
| `AuthorityMetadata` concern (P1) | `freshness_status` 를 엔진 관측값 우선으로 확장 |
| `AuthorityPresenter` (P1) | 공개 렌더 단일 경계에 freshness 노출 추가 |
| `LawApiService` (기존) | 법제처 API 호출 (WAF 우회 포함) |

---

## 5. 안전 경계 (§4)

**엔진이 쓸 수 있는 것**
```
authority_sources / authority_documents / authority_versions
authority_change_events / content_authority_links
authority_review_tasks / authority_verification_events
콘텐츠의 freshness_state · freshness_state_at · last_change_event_id  ← 이 3개뿐
```

**엔진이 쓸 수 없는 것**
```
Topic/Guide/AuditCase 의 본문·제목·법령 텍스트·published
Tool 계산식 · Template 내용
```

강제 장치 3중:
1. `ContentFreshnessUpdater::WRITABLE_COLUMNS` 화이트리스트 + 위반 시 `ArgumentError`
2. `update_columns` 사용 — 콜백 미발동(IndexNow ping·캐시 무효화 없음). 본문이 안 바뀌었으므로 재색인 신호를 보내면 안 된다
3. `test/integration/no_auto_publish_test.rb` — 본문 스냅샷 비교 + **엔진 소스코드에 `Topic/Guide/AuditCase.update` 호출이 없음을 정적 검사**

---

## 6. 실측 (2026-09-06, dev)

| 지표 | 값 |
|---|---:|
| 등록 소스 | 1 (structured 1 / unstructured 0) |
| 추적 문서 | 8 |
| 저장 버전 | 8 |
| 변경 이벤트 | 8 (전부 `NEW_DOCUMENT` 기준선) |
| Impact 간선 | 154 (AuditCase 140 · Tool 14) |
| 간선이 걸린 문서 | 7 / 8 |
| 추적 도구 | 10 |

수집된 실제 시행일:
```
지방계약법            2024.02.17 시행
지방계약법 시행령       2026.06.03 시행
지방계약법 시행규칙      2026.07.01 시행
지방회계법            2026.01.02 시행
지방회계법 시행령       2026.06.02 시행
지방공무원법          2026.06.02 시행
지방공무원 복무규정      2026.06.23 시행
지방공무원 보수규정      2026.08.01 시행
```

---

## 7. 착수 중 발견한 선재 결함

`LawContentFetcher#parse_law_meta` 가 `xml.at_css("법령")` 을 쓰는데 **실제 응답 노드는 `<law>`** 다(자식만 한글 태그).
그래서 파싱이 항상 실패하고 `static_law_meta` 폴백으로 떨어져 **시행일자를 한 번도 받지 못하고 있었다.**

```ruby
# 실측 (2026-09-06)
LawContentFetcher.new.fetch_law_meta("지방자치단체를 … 시행령")
# => { name: "...", url: "...", effective_display: nil }   ← 시행일 없음
xml.at_css("법령")   # => nil
xml.at_xpath("//law") # => 자식 15개
```

Freshness Engine 은 시행일이 핵심이므로 **올바른 파서를 `Authority::LawApiFetcher` 에 새로 두었다.**
구 파서는 이번 범위에서 수정하지 않았다(토픽 렌더 동작이 바뀌므로 별도 판단 필요 — `P2_GATE.md` 참조).
회귀 테스트 `law_api_fetcher_test.rb` 의 `REGRESSION — <law> 노드를 읽는다` 가 이 사실을 고정한다.
