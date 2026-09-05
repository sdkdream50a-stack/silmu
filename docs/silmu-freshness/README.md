# silmu.kr P1.5 — Law & Regulation Freshness Engine

> 2026-09-06 · 선행 `docs/silmu-audit/`(P0) · `docs/silmu-p1/`(P1)
> **DETECT → VERSION → DIFF → IMPACT → REVIEW → VERIFY → PUBLISH**

## 한 줄
구 `LegalComplianceJob` 은 AI 출력으로 게시 콘텐츠를 덮어쓸 수 있었다.
새 엔진은 **그 경로를 구조적으로 갖지 않는다** — 쓰는 곳이 `authority_*` 테이블과 콘텐츠 `freshness_state` 3컬럼뿐이고, 회귀 테스트가 소스코드 수준에서 이를 강제한다.

## 문서
| 문서 | 내용 |
|---|---|
| [CURRENT_FRESHNESS_ARCHITECTURE.md](CURRENT_FRESHNESS_ARCHITECTURE.md) | 파이프라인 · 코드 지도 · 안전 경계 · 실측 |
| [AUTHORITY_DATA_MODEL.md](AUTHORITY_DATA_MODEL.md) | 7 테이블 상세 |
| [VERSIONING_SPEC.md](VERSIONING_SPEC.md) | 불변성 · 시행일 vs 공포일 |
| [SOURCE_REGISTRY.md](SOURCE_REGISTRY.md) | 감시 대상 · Tier · 주기 · 확장 순서 |
| [DIFF_ENGINE_SPEC.md](DIFF_ENGINE_SPEC.md) | Level 1~4 · 정규화 |
| [IMPACT_GRAPH_SPEC.md](IMPACT_GRAPH_SPEC.md) | 간선 생성 · DIRECT/INDIRECT · 우선순위 |
| [REVIEW_WORKFLOW.md](REVIEW_WORKFLOW.md) | 상태 전이 · 결정 · 검증 이벤트 |
| [PUBLIC_FRESHNESS_UI.md](PUBLIC_FRESHNESS_UI.md) | 8상태 표시 · 푸터 정정 · AI 게이트 |
| [EDUCATION_OFFICE_STRATEGY.md](EDUCATION_OFFICE_STRATEGY.md) | 17개 교육청 (설계만) |
| [LEGACY_JOB_RISK.md](LEGACY_JOB_RISK.md) | 구 잡 위험 · DO_NOT_ENABLE |
| [OBSERVABILITY.md](OBSERVABILITY.md) | 관측 · 실패 가시성 |
| [TEST_REPORT.md](TEST_REPORT.md) | 339 runs · positive control 목록 |
| [PRODUCTION_ROLLOUT_PLAN.md](PRODUCTION_ROLLOUT_PLAN.md) | Stage 1~7 · 롤백 |
| [P2_GATE.md](P2_GATE.md) | 확장 게이트 판정 = **NOT_YET_OPEN** |
| [RESUME_PROMPT.md](RESUME_PROMPT.md) | 다음 세션 |

## 운용
```bash
bin/rails silmu:freshness:seed_sources           # 감시 대상 등록 (멱등)
bin/rails silmu:freshness:check                  # 변경 감지 → 영향 → 검토 태스크
bin/rails silmu:freshness:build_links            # 간선 dry-run (APPLY=1 로 적용)
bin/rails silmu:freshness:status                 # 관측 대시보드
bin/rails silmu:freshness:review_queue           # 열린 검토 큐
bin/rails silmu:freshness:no_auto_publish_check  # 본문 무변경 확인
bin/rails silmu:p1:preflight                     # P1 운영 backfill 사전점검 (쓰기 없음)
```
