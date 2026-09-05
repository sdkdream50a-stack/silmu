# P1_6_HANDOFF — UI/UX Phase 인터페이스 계약

> §35 — P1.6 가 Freshness internals 를 직접 해석하지 않게 presenter/interface 를 제공한다.

---

## 1. 단일 진입점

```ruby
authority = AuthorityPresenter.new(record)   # record: Topic | Guide | AuditCase
```
컨트롤러에서 `@authority` 로 이미 제공된다(`topics#show`, `audit_cases#show`).
**P1.6 는 모델·엔진을 직접 만지지 않는다.**

## 2. §35 요구 필드 대응

| 요구 | Presenter API | 반환 |
|---|---|---|
| `freshness_status` | `authority.freshness_status` | `CURRENT` `REVIEW_DUE` `CHANGE_DETECTED` `REVIEW_REQUIRED` `VERIFIED_AFTER_CHANGE` `STALE_SUSPECTED` `SOURCE_UNAVAILABLE` `UNKNOWN` |
| `verified_at` | `authority.verified_on` | `Time` or nil |
| `effective_at` | `authority.effective_on` | `Date` or nil |
| `change_detected_at` | `authority.pending_change_effective_on` | 감지된 개정의 **시행일** (Date) or nil |
| `source_agency` | `authority.source_agency` | 내부 문자열이면 **nil** (필터 통과분만) |
| `official_source_url` | `authority.source_url` | 원문 URL or nil |
| `review_status` | `record.open_authority_review_tasks` | `AuthorityReviewTask` relation |

## 3. 보조 API (UI 판단용)

```ruby
authority.freshness_label        # "현재 기준 확인" / "최신 개정사항 검토 중" …
authority.freshness_attention?   # 경고를 띄워야 하는가 (bool)
authority.change_pending?        # CHANGE_DETECTED | REVIEW_REQUIRED
authority.stale?                 # REVIEW_DUE | STALE_SUSPECTED | SOURCE_UNAVAILABLE

authority.verification_label     # "공식 원문 확인" / "법령 근거 검증" / "내용 정합성 검토" …
authority.verification_scope_text # 무엇을 검증했는지 한 문장
authority.show_verification?

authority.provenance_label       # "실제 감사결과" / "실무.kr 재구성 사례" …
authority.provenance_note
authority.reconstructed?
authority.document_backed?       # 원문 URL 이 실제로 있는가

authority.show_source?           # 출처 블록을 그려도 되는가
authority.public_source_label    # "경기도교육청 감사관실 · 감사사례집 · 2021"
authority.source_page

authority.show_legal_references?
authority.legal_references       # [Reference(label:, official_url:, resolved?)]
authority.linkable_legal_references

authority.show_agency_scope?     # HIGH confidence 일 때만 true
authority.agency_labels          # ["공립학교"] …
```

## 4. UI 가 지켜야 할 규칙

| 규칙 | 이유 |
|---|---|
| `show_*?` 가 false 면 **그리지 않는다** | §29 — 약한 연결에 신뢰 배지를 강제하면 거짓 신뢰가 된다 |
| `public_source_label` 이 nil 이면 출처 블록을 만들지 않는다 | 내부 메타데이터가 걸러진 결과다. 대체 문구를 지어내지 말 것 |
| `freshness_attention?` 이 true 면 **숨기지 않는다** | §31 — 중요 업무 콘텐츠에서 검토 중임을 감추지 않는다 |
| 색상 클래스는 **리터럴**로 | Tailwind JIT 가 동적 조립 클래스를 스캔하지 못한다 |
| `verification_label` 을 임의 축약하지 말 것 | "검증 완료" 같은 축약이 P0 TR-02 사고의 원인이었다 |

## 5. §36 UX North Star 와의 접점

```
3초  — 이 사이트가 무엇을 해주는지
10초 — 내 업무/질문 발견
30초 — 핵심 답과 다음 행동
```
Freshness UI 는 이 예산 안에서 **세 가지만** 답한다.
```
현재 기준인가?     → freshness_status / freshness_label
무엇을 근거로?     → legal_references / public_source_label
언제 확인했나?     → verified_on / effective_on
```
기술 정보(diff·change_type·impact_class·version)는 **공개 UI 에 노출하지 않는다.** Admin 전용이다.

## 6. 재사용 가능한 파셜

```
shared/_verification_badge   record: · variant: inline|sidebar|compact
shared/_provenance_banner    authority:
shared/_authority_source     authority:     (근거·적용·출처 Trust Block)
shared/_legal_references     references:
shared/_freshness_notice     authority:
shared/_tool_trust           tool_key:
```
P1.6 가 디자인을 바꾸더라도 **이 경계를 우회해 DB 를 직접 읽지 않는다.**
우회하면 P0 의 내부 메타데이터 누출이 재발한다.

## 7. §41 병렬 작업 시 충돌 예상 파일

P1.6 를 별도 worktree/브랜치에서 진행할 경우 다음이 겹친다.

| 파일 | 충돌 위험 |
|---|---|
| `app/views/topics/show.html.erb` | **높음** — 이번에 `@authority` 배선·freshness_notice 삽입 |
| `app/views/audit_cases/show.html.erb` | **높음** — provenance 배너·trust block·freshness_notice |
| `app/views/guides/show.html.erb` | 중간 — 검증 배지 |
| `app/views/layouts/application.html.erb` | 중간 — 푸터 문구 |
| `app/views/shared/_verification_badge.html.erb` | 중간 |
| `app/views/shared/_tool_next_actions.html.erb` | 낮음 — 1줄 삽입 |
| `app/controllers/topics_controller.rb` / `audit_cases_controller.rb` | 낮음 — `@authority` 1줄 |

권장: P1.6 는 **레이아웃·네비게이션·홈·검색** 부터 시작하고, 위 상세 페이지는 이 Phase 가 안정된 뒤 손댄다.
