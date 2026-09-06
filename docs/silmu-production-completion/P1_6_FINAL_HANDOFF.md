# P1_6_FINAL_HANDOFF — UI/UX Phase 인계

> §26~§28. P1.55 의 `P1_6_HANDOFF.md` 가 정본이며, 이 문서는 **운영 배포 이후 상태로 재확인**한 결과다.
>
> **P1.6 배포 완료(2026-09-06 10:18 KST)** — 운영 리비전 `18fb7350cbd07c069775f69aef51c0ca8956982a`.
> P1.6 은 view·파셜·검색 서비스를 바꿨으나 `AuthorityPresenter` public contract 는 **읽기만** 했다.
> 배포·검증 실측 = `docs/silmu-ux/PRODUCTION_ROLLOUT.md` · `docs/silmu-ux/PRODUCTION_SMOKE.md`.
>
> **P1.55B(2026-09-06) 재확인 완료** — 직전 운영 리비전 `2d05bae`(현 롤백 지점). 아래 public contract 는 이번 배포로 변하지 않았다.
> P1.55B 는 백엔드 알림만 추가했고 **view·presenter·파셜·라우트를 한 건도 건드리지 않았다** → 충돌 위험 증가 없음.

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

## 6. P1.55B 이후 변경분 (P1.6 이 알아야 할 것)

P1.55B 는 **운영자 알림**만 추가했다. public contract 에는 영향이 없다.

| 변경 | P1.6 영향 |
|---|---|
| `authority_sources.first_failed_at` · `alerted_at` (신규 컬럼 2) | 없음 — 공개 화면에 노출되지 않는다 |
| `AuthoritySourceMailer` (신규) | 없음 — 관리자 메일 전용 |
| `AuthorityFreshnessCheckJob#alert_operator` | 없음 — 잡 내부 |
| `silmu:freshness:status` 출력 2줄 | 없음 — 운영 콘솔 전용 |

**§5 충돌 예상 파일 목록은 그대로 유효하다** — P1.55B 가 건드린 view 는 0건이다.

## 7. 푸터 문구 (§10) — 아직 강화 금지

현재 운영 문구는 보수적으로 유지된다.

> 실무.kr은 법령·지침의 현행성을 지속적으로 점검하고 있습니다.
> 중요한 업무 판단 전에는 각 페이지의 기준일과 공식 근거를 함께 확인해 주세요.

P1.6 에서 아래 표현을 **아직 쓸 수 없다**:

```
법령 변경을 자동 감지하고 있습니다 / 항상 최신입니다 / 100% 최신
실시간 현행화 / 완전 자동 검증
```

이유: `AuthorityFreshnessCheckJob` 스케줄러가 **아직 꺼져 있다**.
자연 주기로 무인 검증이 실증된 뒤에야 문구를 강화할 수 있다.
알림 인프라가 생긴 것은 그 조건의 **선행 요건**을 채운 것이지 조건 자체를 채운 것이 아니다.

## 8. P1_6_READY

```
YES
```
인터페이스가 운영에 배포되어 있고, 파셜·presenter 가 실제로 렌더되고 있음을 운영에서 확인했다.
P1.55B 는 이 판정을 바꾸지 않았다(view 변경 0건).
