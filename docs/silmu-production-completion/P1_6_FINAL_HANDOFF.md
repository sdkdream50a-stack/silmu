# P1_6_FINAL_HANDOFF — UI/UX Phase 인계

> §26~§28. P1.55 의 `P1_6_HANDOFF.md` 가 정본이며, 이 문서는 **운영 배포 이후 상태로 재확인**한 결과다.

## 1. Public contract 재확인 (§26)

`AuthorityPresenter` 가 운영에 배포되어 있고 아래를 제공한다.

| §26 요구 | API | 확인 |
|---|---|:--:|
| `freshness_status` | `authority.freshness_status` | ✅ 8상태 |
| `verified_at` | `authority.verified_on` | ✅ |
| `effective_at` | `authority.effective_on` | ✅ |
| `change_detected_at` | `authority.pending_change_effective_on` | ✅ (감지된 개정의 시행일) |
| `source_agency` | `authority.source_agency` | ✅ (내부 문자열이면 nil) |
| `official_source_url` | `authority.source_url` | ✅ |
| `review_status` | `record.open_authority_review_tasks` | ✅ |
| `agency_scope` | `authority.show_agency_scope?` / `agency_labels` | ✅ HIGH 만 |
| `verification_scope` | `authority.verification_scope_text` | ✅ 한 문장 |

운영 실렌더로 확인된 예:
```
공식 원문 확인 · 2026-05-21 / "공식 발행 문서 원문까지 확인했습니다."
법령 근거 검증 · 2026-06-09 / "인용한 법령·조문을 … 사례의 사실관계 검증과는 다릅니다."
내용 정합성 검토 · 2026-06-09 / "… 공식 원문 대조는 포함되지 않습니다."
```

## 2. §27 — 내부 모델 직접 접근 금지

P1.6 view 는 `AuthorityVersion` · `AuthorityChangeEvent` · `ContentAuthorityLink` 스키마를
**직접 탐색하지 않는다.** 필요한 값은 전부 presenter 를 통해 나온다.

우회하면 P0 의 내부 메타데이터 누출이 재발한다 — 운영 `leak_scan` 이 보여주듯
경계가 막고 있는 값이 **287건** 있다.

## 3. §28 세 가지 표시 상태

| 상태 | 표현 | 구현 |
|---|---|---|
| Current | `● 현재 기준 확인 / 2026.09.05` | `verification_badge` + `freshness_label` |
| Change | `⚠ 최신 개정사항 검토 중` | `shared/_freshness_notice` (`freshness_attention?`) |
| Weak evidence | `최근 검증 정보 없음` | `verification_status = UNVERIFIED` → "검증 정보 없음" |

**거짓 CURRENT 배지 금지** — `show_agency_scope?` / `show_source?` / `show_verification?` 가
false 면 그리지 않는다. 운영에서 Guide 103건 전부 "적용 대상"을 표시하지 않는 것이 그 예다.

## 4. 재사용 파셜 (운영 배포됨)

```
shared/_verification_badge   record: · variant: inline|sidebar|compact
shared/_provenance_banner    authority:
shared/_authority_source     authority:
shared/_legal_references     references:
shared/_freshness_notice     authority:
shared/_tool_trust           tool_key:
```

## 5. §41 충돌 예상 파일 (P1.55 목록 + 이번 세션 추가)

| 파일 | 위험 | 비고 |
|---|---|---|
| `app/views/topics/show.html.erb` | **높음** | `@authority` · freshness_notice |
| `app/views/audit_cases/show.html.erb` | **높음** | provenance 배너 · trust block · freshness_notice · JSON-LD |
| `app/views/guides/show.html.erb` | 중간 | 검증 배지 |
| `app/views/layouts/application.html.erb` | 중간 | 푸터 문구 |
| `app/views/shared/_verification_badge.html.erb` | 중간 | |
| `app/views/shared/_tool_next_actions.html.erb` | 낮음 | 1줄 |
| `config/routes.rb` | 낮음 | admin authority_reviews 추가됨 |
| `app/views/admin/authority_reviews/**` | 없음 | P1.6 범위 밖 |

**권장 순서**: 홈 · 네비게이션 · 검색 → (안정화 후) 상세 페이지.

## 6. P1_6_READY

```
YES
```
인터페이스가 운영에 배포되어 있고, 파셜·presenter 가 실제로 렌더되고 있음을 운영에서 확인했다.
