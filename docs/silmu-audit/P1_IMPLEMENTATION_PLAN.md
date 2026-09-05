# P1_IMPLEMENTATION_PLAN — 다음 단계 구현 계획

> 전제: **P0가 닫히기 전에 P3(일반행정 콘텐츠 확장)·P4(자동화)를 대량 착수하지 않는다.**
> 이 계획의 성격: 콘텐츠를 다시 쓰는 계획이 아니라 **근거를 보이게 만드는 계획**이다.

---

## 0. 우선순위 정의

| 등급 | 정의 | 현재 건수 |
|---|---|---:|
| **P0** Trust Critical | 잘못된 근거 표시·잘못된 기관 적용·검증 위장 | 271 (→ 시스템 결함 4개) |
| **P1** Structural | 분류·메타데이터·provenance·근거 연결 | 139 |
| **P2** User Experience | 업무 흐름·탐색·검색·내부링크 | 97 |
| **P3** Expansion | 일반행정 신규 콘텐츠 | — |
| **P4** Automation | Question Radar·Change Detection·AI | — |

---

## Phase 1 — P0 신뢰 수술 (콘텐츠 무수정, 표면·메타데이터만)

> **가장 중요한 사실: P0 271건은 4개의 수정으로 대부분 닫힌다.** 271개의 글을 고치는 일이 아니다.

### P1-1. 검증 배지와 출처의 분리 · TR-01 / TR-02 · 영향 229건
| 작업 | 내용 |
|---|---|
| 1-1-a | `verification_note :text` 컬럼 추가 (관리자 전용) |
| 1-1-b | 기존 `verification_source` 전량을 `verification_note`로 **복사**(무손실) |
| 1-1-c | `verification_method`를 5개 enum으로 표준화 (`AUTHORITY_METADATA_SCHEMA` §2.6) |
| 1-1-d | 렌더 템플릿에서 `verification_note` 노출 **제거** — 커밋 해시·batch·lawId·dashboard 키 공개 중단 |
| 1-1-e | 배지 문구 `5단계 정합성 검증 완료` → `법령 근거 검증 완료`로 한정 |
| **검증** | 공개 HTML에 `commit`/`batch`/`lawId`/`backlog` 문자열 **0건** (크롤 재실행으로 기계 확인) |

### P1-2. 감사사례 provenance 부여 · TR-02 · 영향 257건
| 작업 | 내용 |
|---|---|
| 1-2-a | `provenance` `original_document_url` `source_page` `disposition` `audit_year` `audit_name` 컬럼 추가 |
| 1-2-b | `AUDIT_CASE_PROVENANCE_SPEC` §5 STEP 1~5 backfill (`db/content_migrations/` 멱등 패턴) |
| 1-2-c | 재구성 사례에 **제목 옆 라벨** 강제 (`📘 재구성 사례 — 실제 특정 사건이 아닙니다`) |
| 1-2-d | `provenance=ACTUAL_AUDIT`인데 원문 URL 없으면 → `OFFICIAL_PARTIAL` 강등 + 배지 미표시 |
| 1-2-e | 내부 backlog 문구 공개 노출 제거 (17건) |
| **검증** | `provenance` 미분류 0건 · 배지 표시 사례 중 원문 URL 결손 0건 |

### P1-3. 도구 면책·기준일 표면 · TR-03 · 영향 37건
| 작업 | 내용 |
|---|---|
| 1-3-a | 공통 파셜 `_tool_authority_footer` 신설 |
| 1-3-b | `legal_standards.yml` / `contract_thresholds.yml`의 `version`을 **코드에서 직접 읽어** 화면 표시 |
| 1-3-c | 면책 문구 30건에 적용 |
| **검증** | 도구 37/37에 기준일·근거·면책 노출 · 상수 파일 수정 시 화면 값이 자동 변경됨 |

### P1-4. 감사사례 수치 근거 보강 · TR-04 · 영향 38건
금액이 있으나 조문 근거가 없는 38건에 근거 조문을 붙이거나, 재구성 사례의 수치를 "예시"로 표기.
**함께 처리:** 이미 본문에 있는 조문 문자열(219건 보유)과 텍스트 도메인 표기(94건)를 법제처 딥링크로 승격 — 새 조사 없이 링크만 생성한다.
**검증**: 금액 보유 사례 중 근거·예시 표기 결손 0건.

### P1-5. 검증 신선도 자기고발 · TR-05
`review_due_at` 도입 → 경과 시 자동 `STALE_SUSPECTED` 강등 + 배지 문구 변경.
`LegalComplianceJob` 중단 사유 규명(무한루프 전례 확인) → 재가동 판단.
**검증**: 검토일 경과 항목이 화면에서 스스로 "재검증 필요"를 말한다.

> **Phase 1 전체 특성: 콘텐츠 본문을 한 글자도 고치지 않는다.** 스키마 additive + 템플릿 + backfill.

---

## Phase 2 — P1 구조 (기관 차원 도입)

### P2-1. `target_agency` backfill · TR-06 · 영향 549건
- `CONTENT_AUDIT.csv`의 `target_agency`/`jurisdiction` 추론값을 **초안**으로 사용
- UNSPECIFIED 352건은 사람 판정 큐로 (`Admin::TopicReviewsController` 재사용)
- **게이트: `target_agency`가 비면 발행 금지**

### P2-2. `agency_rules` 테이블 + YAML 승격 (`AGENCY_RULE_MODEL` §4)
`legal_standards.yml`·`contract_thresholds.yml`을 `agency_rules` 행으로 승격.
계약·복무 2개 도메인 파일럿 → 전 도메인.

### P2-3. 가이드 검증 표면 · TR-07 · 49건
guides에도 authority 메타데이터 적용. 법령명 0건 가이드 18건은 근거 보강 또는 `SECONDARY_SOURCE` 명시.

### P2-4. `content_evidence_links` 구축 (`SOURCE_GRAPH_DESIGN` G1~G4)
토픽 813 딥링크 → 엣지 자동 생성. `laws` 테이블 정규화.

### P2-5. AI grounding · TR-09 — **최고 ROI**
주입 코드는 **이미 있다**(`ai_assistant_channel.rb:31-44`). 없는 것은 ① 그 경로로 가는 UI 배선(토픽 페이지 위젯 임베드 또는 `topic_slug` 링크) ② 질문→토픽 retrieval 두 가지뿐이다.
`llms-full.txt`(563KB)가 이미 완성된 코퍼스이고 `pg_trgm`도 설치되어 있다. 답변에 **출처 링크와 기준일을 강제 표기**하고, 근거를 못 찾으면 답하지 않는다.
→ 북극성 ④ "일반 AI보다 근거가 확실하다"가 이 작업으로 처음 성립한다.

### P2-6. 운영↔개발 정본 정리 · TR-11
콘텐츠 정본 경로를 하나로 선언하고(`content_migrations` 권장), dev DB 동기화 절차를 문서화.

---

## Phase 3 — P2 UX / SEO

| 작업 | 근거 |
|---|---|
| 중복 `<title>` 6건 해소 (시리즈 접두어) | SEO_AUDIT §3.1 |
| `/tools/quote-review` 레이아웃 이탈 복구 (canonical·description·JSON-LD 부재) | SEO_AUDIT §6 |
| 감사사례 `Legislation` JSON-LD 추가 | SEO_AUDIT §2 |
| 도구 `SoftwareApplication`+`HowTo` 스키마 | SEO_AUDIT §2 |
| templates 26건 description·본문 보강 | SEO_AUDIT §5 |
| 고아 53건 링크 연결 | TASK 허브 도입과 함께 |
| Solution Page 블록 ⑥⑦(시스템 처리·기안 문구) 신설 | SOLUTION_PAGE_SPEC §2 |
| `/work` 계층 + 홈 CTA (도메인 임계 충족분만) | NEW_INFORMATION_ARCHITECTURE §5 |

---

## Phase 4 — P3 확장 (P0 종료 후)

빈 도메인 5개(01 인사 · 08 민원 · 12 행정절차/법무 · 14 문서/보고/위원회 · 15 디지털행정)를 채운다.
**단, `agency_rules`가 가동된 뒤에 시작한다.** 기관 차원 없이 일반행정 콘텐츠를 만들면 TR-06을 549건에서 1,000건으로 늘릴 뿐이다.

---

## Phase 5 — P4 자동화

| 작업 | 선행 조건 |
|---|---|
| 내부 계측 복구 (`search_logs` 10행 · `topic_events` 2행 · `topic_feedbacks` 0행) | 없음 — **지금 해도 됨, 비용 최저** |
| AI 질문 익명 저장 | — |
| Question Radar (`cafe_articles` 50,000행) | 계측 복구 후 |
| Change Detection (조문 diff → 영향 그래프) | `content_evidence_links` |

---

## 절대 하지 않을 것

- 콘텐츠 대량 자동 재작성
- 운영 DB 파괴적 마이그레이션 (모든 스키마 변경은 additive·nullable)
- 기존 URL 이동 (통합 시 `slug_redirects` 301만)
- 콘텐츠 삭제 (현재 `DELETE_CANDIDATE` **0건** — 지울 것이 없다)
- P0 종료 전 일반행정 콘텐츠 대량 생성
- 자동 발행 시스템

---

## 완료 판정 게이트 (기계 검사)

| # | 게이트 | 현재 | 목표 |
|---|---|---:|---:|
| G1 | 공개 HTML의 내부 메타데이터 문자열 | 119+17 | **0** |
| G2 | `provenance` 미분류 감사사례 | 257 | **0** |
| G3 | 검증 배지 표시 + 원문 URL 결손 | 246 | **0** |
| G4 | `target_agency` UNSPECIFIED | 352 | **0** |
| G5 | 기준일 없는 도구 | 32 | **0** |
| G6 | 면책 없는 도구 | 30 | **0** |
| G7 | 금액 有 · 조문 無 감사사례 | 38 | **0** |
| G8 | 중복 `<title>` | 6 | **0** |
| G9 | 검증 정지 기간 | 3개월 | 배지가 스스로 고발 |
