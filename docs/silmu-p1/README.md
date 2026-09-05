# silmu.kr P1 — Authority Trust Layer

> 2026-09-05 · 선행 `docs/silmu-audit/` (P0 감사)
> **PROVENANCE → AUTHORITY → SCOPE → FRESHNESS**

## 한 줄
P0 는 "감사사례에 공식 원문 링크 0건"이라 보고했다. DB 를 열어보니 **원문 URL·페이지·발행기관이 이미 있었고 렌더되지 않았을 뿐**이었다. P1 은 새 출처를 만들지 않고 **있던 사실을 보이게** 했다.

## 문서
| 문서 | 내용 |
|---|---|
| [P1_IMPLEMENTATION_REPORT.md](P1_IMPLEMENTATION_REPORT.md) | 구현 전체 · 아키텍처 · 파일 목록 · 안 한 것 |
| [PROVENANCE_BACKFILL_REPORT.md](PROVENANCE_BACKFILL_REPORT.md) | 감사사례 출처 분류 결과 · confidence gate |
| [PUBLIC_METADATA_LEAK_REPORT.md](PUBLIC_METADATA_LEAK_REPORT.md) | 내부/공개 분리 · 누출 0 의 근거 |
| [LEGAL_REFERENCE_RESOLUTION_REPORT.md](LEGAL_REFERENCE_RESOLUTION_REPORT.md) | 텍스트 근거 → 링크 승격 · URL 전수 검증 |
| [TOOL_TRUST_REPORT.md](TOOL_TRUST_REPORT.md) | 도구 37개 공통 신뢰 레이어 |
| [FRESHNESS_JOB_REPORT.md](FRESHNESS_JOB_REPORT.md) | 신선도 모델 · **LegalComplianceJob DO_NOT_ENABLE** |
| [AGENCY_SCOPE_REPORT.md](AGENCY_SCOPE_REPORT.md) | 적용 기관 범위 (HIGH confidence only) |
| [MIGRATION_PLAN.md](MIGRATION_PLAN.md) | 운영 적용 명령 · 영향범위 · 롤백 |
| [TEST_REPORT.md](TEST_REPORT.md) | 288 runs / 0F / 0E · positive control 목록 |
| [P2_RECOMMENDATION.md](P2_RECOMMENDATION.md) | 다음 우선순위 |
| [RESUME_PROMPT.md](RESUME_PROMPT.md) | 다음 세션 시작 프롬프트 |

## 데이터
`silmu_p1_provenance_backfill.csv` (191행) · `silmu_p1_agency_scope.csv` (386행) — dev 기준 dry-run

## 재실행
```bash
bin/rails silmu:p1:provenance_dry_run    # DB 변경 없음
bin/rails silmu:p1:provenance_backfill   # HIGH confidence 만
bin/rails silmu:p1:agency_dry_run
bin/rails silmu:p1:agency_backfill
bin/rails silmu:p1:leak_scan             # positive control 포함
```
