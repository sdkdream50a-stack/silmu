# 06 — SOLUTION PAGE CANDIDATES

> §15 Solution Page Contract 를 **상위 후보에 실제로 적용 가능한지** 판정한다.
> 억지로 채우지 않는다 — 근거가 없으면 `NONE` / `UNKNOWN`.
> 이 문서는 **설계 판정**이고 구현이 아니다(§28: 사용자 승인 전 구현 없음).

---

## 1. 지금 Solution Page 가 실제로 무엇인가 (실측)

P1.6 은 **대표 페이지 1개(`topics#show`)에만** Solution Page 첫 화면을 적용했다.

| 요소 | 구현 | 위치 |
|---|---|---|
| 바로 답 | ✅ FAQ 원문 (`Topic.answer_for`) | 검색 결과 |
| 적용 대상 | ✅ `_solution_status.html.erb` (presenter 경유) | `topics/show` L190 |
| 현행성 상태 | ✅ 같은 partial. **거짓 CURRENT 구조적 불가** | 동 |
| 지금 해야 할 일 | ⚠️ `howto_steps.first(5)` — **10/114 토픽에만 데이터 있음** | `topics/show` L289 |
| 자주 묻는 질문 | ✅ `faq_list.first(4)` | L314 |
| 관련 감사사례 | ✅ `@related_audit_cases` | L1414 |
| 공식 근거 | ✅ `_legal_references` · `_authority_source` | shared |
| 다음 업무 / 도구 | ✅ `@related_topics.first` · `@related_tools.first` | L2027 |
| Guide / AuditCase 에 적용 | ❌ 미적용 (P1.6 이 §41 충돌 위험으로 보류) | — |

> **즉 Solution Page 골격은 이미 있다.** P2 가 만들 것은 새 페이지 템플릿이 아니라
> **그 골격을 채울 데이터**(특히 `howto_steps`)와 **적용 범위 확대**다.

## 2. §15 섹션별 데이터 원천 매핑

| §15 섹션 | 현재 데이터 원천 | 채워진 정도 | P2 조치 |
|---|---|---|---|
| 바로 답 | `topic.faqs` | 110/114 (실은 112 — 2건 파싱실패) | **01 §7.1 정정 먼저** |
| 적용 대상 | `topic.target_agency` · `jurisdiction` | **15/114 (13%)** | 판정 규칙 정의 선행(02 §4) |
| 핵심 조건 | `topic.summary` · `quick_stats` | 385 quick_stats | 양호 |
| 지금 해야 할 일 | `topic.howto_steps` | **10/114 (8.8%)** | **최대 공백** |
| 업무 흐름 | `topic.flowchart_mermaid`/`_url` | 15/114 (13%) | 중간 공백 |
| 필요 서류 | 없음 (Template 26종은 별도 페이지) | **0** | 신설 후보 — 07 CHECKLIST |
| 시스템 처리 | 없음 (e-나라도움·나라장터 언급은 본문 텍스트) | **0** | 신설 후보 |
| 기안/결재 예시 | Template `기안문` 5종 | 부분 | 연결만 |
| 흔한 실수 | `topic.practical_tips` | 93/114 (82%) | 양호(텍스트) |
| 감사/법적 리스크 | `related_audit_cases` | 195/257 근거링크 | 양호 |
| 실제 사례 | `AuditCase` | 257 (재구성 110 포함 — §19) | provenance 표기 필요 |
| 도구 | `related_tools` | 39종 · **발견성 문제**(05 §4.3) | 라우팅 개선 |
| 공식 근거 | `topic.law_content` + `ContentAuthorityLink` | 텍스트 114/114 · **구조화 링크 0/114** | 09 문서 |
| 변경 이력 | `AuthorityChangeEvent` 8건 | 사실상 0 | 스케줄러 선행 |

## 3. Solution Page 승격 후보 판정

**승격 = 이미 있는 토픽에 §15 골격을 실제로 채운다.** 새 토픽 생성이 아니다.

| # | 대상 토픽(slug) | 테마 | 지금 없는 섹션 | 채울 수 있나 | 판정 |
|---:|---|---|---|---|---|
| 1 | `private-contract-limit` | 수의계약 한도 | 지금 해야 할 일 · 필요 서류 · 도구 연결 | ✅ 근거 LOADED · 도구 존재 | **PROMOTE** |
| 2 | `split-contract-prohibition` | 분할발주 | 바로 답(표제) · 지금 해야 할 일 · 도구 연결 | ✅ 도구 존재 | **PROMOTE** |
| 3 | `inspection` | 검사·검수 | 지금 해야 할 일 · 필요 서류(서식 3종 연결) | ✅ Template 존재 | **PROMOTE** |
| 4 | `budget-carryover` · `budget-transfer` | 이월·전용 | 지금 해야 할 일 | ✅ 도구 존재 | **PROMOTE** |
| 5 | `entertainment-expense-rules` | 업무추진비 | 대부분 | ⚠️ 근거 EXISTS_NOT_LOADED | **HOLD** — 09 선행 |
| 6 | `information-disclosure` | 정보공개 | 지금 해야 할 일 · 필요 서류 · 시스템 처리 | ⚠️ 정보공개법 미적재 | **HOLD** — 09 선행 |
| 7 | `sick-leave` · `special-leave` · `parental-leave` | 휴가 | 필요 서류 · 지금 해야 할 일 | ✅ 복무규정 LOADED | **PROMOTE** |
| 8 | `concurrent-position` | 겸직 | 지금 해야 할 일(허가 절차) | ✅ 지방공무원법 LOADED | **PROMOTE** |
| 9 | (없음) 일상경비 | 일상경비 | **토픽 자체가 없다** | 신규 필요 | **NEW_TOPIC 후보** |
| 10 | (없음) 예산과목 분류 | 예산과목 | **토픽 자체가 없다**(도구만 있음) | 신규 필요 | **NEW_TOPIC 후보** |

`PROMOTE 6` · `HOLD 2` · `NEW_TOPIC 2`.

## 4. 억지로 채우지 않을 섹션 (§15 명시)

| 섹션 | 왜 비워 두는가 |
|---|---|
| **변경 이력** | `AuthorityChangeEvent` 8건뿐이고 freshness 스케줄러가 꺼져 있다. 지금 채우면 "변경 없음"이 사실이 아니라 **미관측**인데 사실처럼 보인다 → `UNKNOWN` |
| **시스템 처리** | e-나라도움·나라장터·에듀파인 화면은 우리가 검증할 수 없다. 스크린샷·화면명은 기관·연도별로 다르다 → 문장 근거 없이 쓰지 않는다 |
| **적용 대상** | `target_agency` 가 87% 비어 있다. presenter 가 `show_agency_scope?` 로 이미 **근거 없으면 안 그린다**. 그 규칙을 우회해 채우지 않는다 |
| **실제 사례** | 재구성 110건은 `SILMU_RECONSTRUCTED_CASE` 로 **반드시 구분 표기**(§19). 실제 감사사례처럼 섞지 않는다 |

## 5. Guide / AuditCase 로의 확대 — 이번엔 하지 않는다

P1.6 이 `topics#show` 만 적용한 이유는 §41 충돌 위험이었다.
P2 도 **데이터를 먼저 채우고**(howto_steps 10→?), 그 다음에 표면 확대를 판단한다.
순서를 바꾸면 "골격은 늘었는데 안이 빈" 페이지가 103+257개 생긴다.

## 6. P1.6 동결 경계 확인

이 문서의 어떤 항목도 다음을 요구하지 않는다.

```
search_query_parser.rb            무수정
topic.rb search_multiple/relaxed_match/answer_for   무수정
_solution_status.html.erb         무수정 (presenter 규칙 그대로 사용)
_nav_v2 / home/index              무수정
654-query recall 지문             재측정 불필요
```

§3 승격은 **`topic.howto_steps` 데이터 입력**이고 코드 경로가 아니다.
