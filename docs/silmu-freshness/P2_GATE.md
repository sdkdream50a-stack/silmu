# P2_GATE — 일반행정 확장 게이트 판정

> §56 — 일반행정 콘텐츠를 수백 개 늘린 뒤 현행화 시스템을 만들면 유지보수 부채가 폭발한다.
> 따라서 확장 전에 현행화 인프라가 **작동**해야 한다.

---

## 1. 게이트 조건 판정

| # | 조건 | 상태 | 근거 |
|:--:|---|:--:|---|
| 1 | Authority Source Registry operational | 🟡 **부분** | 구현·dev 동작 확인. **운영 미배포** |
| 2 | Freshness versioning operational | 🟡 **부분** | immutable 버전 8건 저장·시행일 파싱 확인. 운영 미배포 |
| 3 | Change detection operational | 🟡 **부분** | changed/unchanged control 통과. 운영 1주기 미관측 |
| 4 | Impact graph operational | 🟡 **부분** | 간선 154 · DIRECT/INDIRECT 분류 실증. 운영 미배포 |
| 5 | Review workflow operational | 🟡 **부분** | 결정·검증이벤트·상태전이 동작. **Admin UI 없음(rake 만)** |

## 2. 판정

```
P2_GATE = NOT_YET_OPEN
```

**이유: 다섯 조건 모두 개발 환경에서만 증명되었다.**

"operational" 은 코드가 존재한다는 뜻이 아니라 **운영에서 돌고 있다**는 뜻이다.
P0 에서 얻은 교훈이 정확히 이것이다 — `LegalComplianceJob` 은 코드가 있었지만 2026-04-13 부터 꺼져 있었고, 그동안 푸터는 "자동 검증을 운영하고 있다"고 말하고 있었다.

## 3. 게이트를 열기 위한 최소 조건

| # | 작업 | 판정 기준 |
|:--:|---|---|
| G1 | `PRODUCTION_ROLLOUT_PLAN.md` Stage 1~6 완료 | 운영에서 `silmu:freshness:status` 가 문서 8건·버전 8건·간선 150+ 를 보여준다 |
| G2 | 스케줄 등록 후 **최소 2주기(2일) 무사고 동작** | `failed=0` · `no_auto_publish_check` PASS |
| G3 | 실제 개정 1건을 감지→검토→종결까지 완주 | `AuthorityVerificationEvent` ≥ 1 (운영) |
| G4 | 검토 큐 Admin 화면 | rake 없이 검토 가능 |

G1~G3 은 시간이 필요하다(실제 개정이 일어나야 G3 가 가능). G3 는 **기다리는 것이 정상**이며, 억지로 만들지 않는다.

## 4. 게이트가 열리면 할 수 있는 것

- 일반행정 콘텐츠 확장 (P0 `NEW_INFORMATION_ARCHITECTURE.md` 의 빈 도메인 5개)
- 국가공무원 영역 확장
- 17개 교육청 (`EDUCATION_OFFICE_STRATEGY.md`)
- 푸터 문구 강화 → "법령·지침 변경을 자동 감지하고, 영향받는 콘텐츠를 재검토하고 있습니다"

## 5. 게이트와 무관하게 지금 할 수 있는 것

현행화 인프라에 부채를 만들지 않는 작업들:

| 작업 | 출처 |
|---|---|
| P1 운영 backfill | `docs/silmu-p1/` |
| AI 근거 주입 배선 1줄 (`ai_assistant_path(topic_slug:)`) | P1 `P2_RECOMMENDATION.md` |
| 도구 기준값 2종 갱신 (2026-02-04 / 2026-03-28) | P1 `TOOL_TRUST_REPORT.md` |
| 나머지 26개 도구 기준 등록 | P1 |
| P0 SEO 잔여 (중복 title 6 · `/tools/quote-review` 레이아웃) | P0 `SEO_AUDIT.md` |
| `LawContentFetcher#parse_law_meta` 수정 (`at_css("법령")` → `at_xpath("//law")`) | 이번 세션 발견 |

마지막 항목은 이번 세션에서 **일부러 고치지 않았다** — 고치면 토픽 페이지에 시행일 표기가 새로 나타나므로 렌더 변경을 동반한다. 별도 판단이 필요하다.

## 6. 확장 순서 권고

```
지방계약 ✅ → 지방회계 ✅ → 복무·보수 ✅ → 국가공무원 → 행정규칙(예규·훈령) → 교육부 → 교육청
```
1~3 은 이미 등록되어 있다. 4는 seed 항목 추가만으로 가능하고, 5부터 새 fetcher 가 필요하다.
