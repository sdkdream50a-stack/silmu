# CANARY_RUN_1 — 첫 운영 수집 (기준선)

> §16~§19 — scheduler 를 켜기 전 수동 1회. baseline 을 "법령 개정"으로 보여주지 않는다.

## 1. 소스 등록

```
$ bin/rails silmu:freshness:seed_sources
AuthoritySource 1개 · AuthorityDocument 8개 등록
```
P1.5 에서 정한 Tier-1 법제처 structured source. **범위를 임의 확대하지 않았다**(§15).

## 2. 실행

```
$ bin/rails silmu:freshness:check
시작 00:39:09 → 종료 00:39:21   (12초)
[AuthorityFreshness] {"checked":8,"unchanged":0,"changed":8,"failed":0,"tasks_created":0,"skipped_failing":0}
```

## 3. §17 관측 항목

| 항목 | 값 |
|---|---:|
| fetch attempts | 8 |
| fetch successes | **8** |
| parse failures | **0** |
| versions created | **8** |
| change events | **8** (전부 `NEW_DOCUMENT`) |
| review tasks | **0** |
| duration | 12초 |
| external request count | 8 (요청 간 1초 rate limit) |

## 4. 수집된 실제 시행일

| 문서 | 시행일 | 공포일 | MST | 제개정 |
|---|---|---|---|---|
| 지방자치단체를 당사자로 하는 계약에 관한 법률 | 2024-02-17 | 2023-08-16 | 253973 | 타법개정 |
| 〃 시행령 | **2026-06-03** | 2026-05-19 | 286149 | 타법개정 |
| 〃 시행규칙 | **2026-07-01** | 2026-06-19 | 287365 | 일부개정 |
| 지방회계법 | 2026-01-02 | 2025-10-01 | 276363 | 타법개정 |
| 지방회계법 시행령 | 2026-06-02 | 2026-06-02 | 286643 | 일부개정 |
| 지방공무원법 | 2026-06-02 | 2026-06-02 | 286499 | 일부개정 |
| 지방공무원 복무규정 | 2026-06-23 | 2026-06-23 | 287219 | 일부개정 |
| 지방공무원 보수규정 | **2026-08-01** | 2026-07-30 | 288435 | 일부개정 |

공포일 ≠ 시행일이 실제 데이터로 확인된다(예: 지방회계법 2025-10-01 공포 → 2026-01-02 시행).

## 5. §18·§19 — Baseline 이 개정으로 보이지 않는가

| 검사 | 결과 |
|---|---|
| `change_type` | 8건 전부 `NEW_DOCUMENT` (개정 아님, 기준선) |
| `impact_status` | 8건 전부 `NO_CONTENT_LINKED` |
| **review tasks 생성** | **0건** |
| **콘텐츠 `freshness_state`** | topics 0 · guides 0 · audit_cases 0 |
| 공개 화면 `⚠ 최신 개정사항 검토 중` | **0건** |

→ **거짓 경고 0.** §19 실패 조건에 해당하지 않는다.

이것이 가능한 이유: **간선(ContentAuthorityLink)을 RUN 1 이후에 생성했다.**
반대 순서로 했다면 8건의 기준선이 전 콘텐츠에 검토 태스크를 쏟아냈을 것이다.

## 6. 영향 간선 생성 (RUN 1 이후)

```
$ bin/rails silmu:freshness:build_links            # dry-run
link build (DRY-RUN): 생성 예정=209 · 미해석 326 · 미등록법령 257 · 기존 2
$ bin/rails silmu:freshness:build_links APPLY=1
link build: 생성=209 · 미해석 326 · 미등록법령 257
현재 총 링크=209
```
dry-run 예정 **209 = 실제 생성 209** (수치 일치 검증).

- 미해석 326: 자치법규·기관 내부지침·해석 불가 대용어 → 링크하지 않음
- 미등록법령 257: 해석은 됐으나 아직 감시 대상이 아닌 법령 → 링크하지 않음

## 7. 판정

```
RUN_1 = SUCCESS
  fetch 8/8 · parse failure 0 · versions 8 · events 8(baseline) · tasks 0
  거짓 경고 0 · 콘텐츠 변경 0
```
