# silmu.kr P0 Authority Audit — 산출물 색인

> 실측 2026-09-05 · 운영 `https://silmu.kr` sitemap 564 URL 전수 크롤(전부 HTTP 200) + 저장소·로컬 DB 조사
> 이번 단계는 **AUDIT → MODEL → PRIORITY → PLAN**이며 콘텐츠 생성·전면 리뉴얼·파괴적 마이그레이션은 수행하지 않았다.

## 감사 (무엇이 사실인가)
| 문서 | 내용 |
|---|---|
| [CURRENT_SYSTEM_MAP.md](CURRENT_SYSTEM_MAP.md) | 현행 코드·DB·라우팅·잡·AI 구조 실측 지도 |
| [AUTHORITY_AUDIT_REPORT.md](AUTHORITY_AUDIT_REPORT.md) | 권위 감사 결과 종합 |
| [TRUST_RISK_REGISTER.md](TRUST_RISK_REGISTER.md) | TR-01~TR-12 신뢰 위험 등록부 |
| [CONTENT_AUDIT.csv](CONTENT_AUDIT.csv) | 549건 전수 분류 (KEEP/UPDATE/MERGE/REBUILD/DELETE_CANDIDATE) |
| [SEO_AUDIT.md](SEO_AUDIT.md) | 검색·구조화 데이터 감사 |

## 설계 (무엇으로 바꿀 것인가)
| 문서 | 내용 |
|---|---|
| [NEW_INFORMATION_ARCHITECTURE.md](NEW_INFORMATION_ARCHITECTURE.md) | 15 도메인 · 업무×기관×근거 3축 IA · 홈 IA |
| [AUTHORITY_METADATA_SCHEMA.md](AUTHORITY_METADATA_SCHEMA.md) | 권위 메타데이터 표준 V1 |
| [SOURCE_HIERARCHY.md](SOURCE_HIERARCHY.md) | Tier 1~4 출처 등급 |
| [AGENCY_RULE_MODEL.md](AGENCY_RULE_MODEL.md) | 기관별 규칙 상속(COMMON_RULE + OVERRIDE) |
| [SOLUTION_PAGE_SPEC.md](SOLUTION_PAGE_SPEC.md) | 표준 실무 해결 페이지 12블록 |
| [AUDIT_CASE_PROVENANCE_SPEC.md](AUDIT_CASE_PROVENANCE_SPEC.md) | 감사사례 출처 4분류·표시 규칙·backfill |
| [DECISION_WIZARD_ARCHITECTURE.md](DECISION_WIZARD_ARCHITECTURE.md) | 판단형 도구 공통 엔진 |
| [SOURCE_GRAPH_DESIGN.md](SOURCE_GRAPH_DESIGN.md) | 근거 그래프 · incremental migration |
| [QUESTION_RADAR_DESIGN.md](QUESTION_RADAR_DESIGN.md) | 질문 레이더 (설계만) |
| [CHANGE_DETECTION_DESIGN.md](CHANGE_DETECTION_DESIGN.md) | 법령 변경 감지 (설계만) |

## 실행 (무엇을 이 순서로)
| 문서 | 내용 |
|---|---|
| [P1_IMPLEMENTATION_PLAN.md](P1_IMPLEMENTATION_PLAN.md) | Phase 1~5 · 완료 게이트 G1~G9 |
| [RESUME_PROMPT.md](RESUME_PROMPT.md) | 다음 세션 시작 프롬프트 |

## 재현 도구
```bash
# 1) 운영 전수 크롤 → 구조 추출
python3 tools/extract_pages.py       # pages/*.html → extracted.json
# 2) 분류 → CSV
python3 tools/build_audit.py         # → CONTENT_AUDIT.csv + audit_summary.json
```
`data/` — 크롤 시점의 배지·출처·근거법령 원자료 (badges.json, guide_badges.json, topic_basis.json, audit_summary.json)

## 한 줄 결론
> 콘텐츠의 양과 법령 정확성은 이미 상당한 수준이다. 무너져 있는 것은 **출처를 사용자에게 보여주는 방식**이다.
> 토픽 114건은 법제처 딥링크 813개를 붙이고 있는 반면, **감사사례 257건은 클릭 가능한 공식 원문 링크가 0건이면서 96%가 "5단계 정합성 검증 완료" 배지를 달고 있다.**
> 조문 자체는 219건에 적혀 있다 — 결함의 정확한 이름은 "근거 부재"가 아니라 **"검증 불가능한 근거 표기"**다.
