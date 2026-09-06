# 01 — PRODUCTION COVERAGE AUDIT

> 측정 시각 **2026-09-06 10:43 KST** · 측정 대상 = **운영(production)**, dev 아님
> 운영 리비전 `18fb7350cbd07c069775f69aef51c0ca8956982a` · schema `20260906065000`
> 측정 방법 = 운영 컨테이너 `bin/rails runner` **읽기 전용** (SSH → docker exec, stdin 스크립트)
> 스크립트 원본 = `docs/silmu-p2/_measure/` (본 문서 §9)
> **CONTENT_MUTATION = 0** — §8 실증

---

## 1. 총량 (운영 실측)

| 자산 | 전체 | published | 비고 |
|---|---:|---:|---|
| Topic | 114 | 114 | 미발행 0 |
| Guide | 103 | 103 | 미발행 0 |
| AuditCase | 257 | 257 | 미발행 0 |
| **FAQ** (topic.faqs) | **474 authored** | **465 도달가능** | 9건이 파싱 실패로 소실 — §7 · <br>⚠️ **2026-09-06 R1 정정**: 최초 기재 464/455 는 **배열만 센 값**이었다. `faq_list` 가 이중 인코딩 2건(FAQ 10건)을 구제하고 있어 실제 저작 474 · 도달 465 다. R1 에서 4건 정규화 후 **도달 474** |
| HowTo step (topic.howto_steps) | 55 | 55 | 10개 토픽에만 존재 |
| QuickStat (topic.quick_stats) | 385 | 385 | |
| Tool | 39 (registry) / 38 (route) | — | 코드 정의. DB 아님 |
| Template | 26 | — | 코드 정의(`TemplatesController::TEMPLATES`). DB 아님 |
| Law | 15 | — | `effective_date` NOT NULL = **0/15** |
| AuthorityDocument | 8 | — | §9 참조 |
| StandardTerm | 13,208 | — | 표준어 검사기 사전 |
| TaskGuide | 28 | — | 서무/시설관리/보험/세무/보고/회계 |
| SearchLog | 2,161 | — | 2026-05-22 ~ 2026-09-06 |

§7 인계 수치(Topic 114 · Guide 103 · AuditCase 257)와 **일치**한다.
FAQ 는 "도달 가능 / 저작"으로 갈라야 한다 — 이유는 §7.

> **2026-09-06 R1 정정.** 이 문서가 처음 적은 `455`(도달) / `464`(저작)는 **배열 형태만 센 값**이었다.
> `Topic#faq_list` 는 jsonb 가 JSON **문자열**인 경우도 `JSON.parse` 로 구제한다(운영 2토픽 · FAQ 10건).
> 실측 정정: **저작 474 · 도달 465 · 소실 9**. R1 정규화 후 **도달 474 · 소실 0**.
> 교훈 — 도달 가능 건수는 컬럼을 직접 세지 말고 **실제 접근자(`faq_list`)로 세야 한다.**

---

## 2. Topic 카테고리별 커버리지

| category | Topic | FAQ | HowTo | QuickStat | FAQ보유 | HowTo보유 | 흐름도 | 법령본문 | 유권해석 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| contract | 57 | 214 | 30 | 185 | 53 | 5 | 6 | 57 | 55 |
| budget | 22 | 94 | 0 | 71 | 22 | 0 | 5 | 22 | 14 |
| salary | 12 | 54 | 25 | 48 | 12 | 5 | 1 | 12 | 6 |
| duty | 12 | 48 | 0 | 45 | 12 | 0 | 3 | 12 | 8 |
| travel | 6 | 24 | 0 | 20 | 6 | 0 | 0 | 6 | 6 |
| subsidy | 2 | 9 | 0 | 4 | 2 | 0 | 0 | 2 | 1 |
| expense | 1 | 4 | 0 | 4 | 1 | 0 | 0 | 1 | 1 |
| property | 1 | 4 | 0 | 4 | 1 | 0 | 0 | 1 | 1 |
| other | 1 | 4 | 0 | 4 | 1 | 0 | 0 | 1 | 1 |
| **합계** | **114** | **455** | **55** | **385** | **110** | **10** | **15** | **114** | **93** |

`other` 1건 = `information-disclosure`(정보공개). **운영에 실재한다** — §6·PC3.

## 3. Guide 커버리지

| 분류 | 값 |
|---|---|
| category | 예산 44 · 계약 43 · 복무 13 · 인사 2 · **민원 1** |
| series (8종 × 10편) | 수의계약·공사계약·입찰·예산편성·예산집행·지방보조금·인사복무·출장여비 = 80 |
| series 없음 | 23 |

## 4. AuditCase 커버리지

| category | 건수 |
|---|---:|
| 기타 | 62 |
| 회계 | 43 |
| 예산 | 36 |
| 수의계약 | 29 |
| 입찰 | 24 |
| 계약체결 | 21 |
| 계약이행 | 19 |
| 대금지급 | 11 |
| 하도급 | 6 |
| 검수/검사 | 6 |

## 5. ANSWER / DO / EVIDENCE 3층 커버리지

§10 이 요구한 대로 **자산 개수가 아니라 층별로** 본다.

| 층 | 지표 | 실측 | 판정 |
|---|---|---:|---|
| **ANSWER** | FAQ 보유 토픽 | 110 / 114 (96.5%) | **양호**. 단 도달 실패 2건(§7) |
| | 실제 질의에 "바로 답"이 뜨는 비율 | **20 / 211 (9.5%)** | **낮음** — 03_QUESTION_GAP_RADAR §3 |
| **DO** | HowTo step 보유 토픽 | **10 / 114 (8.8%)** | **결정적 공백** |
| | 흐름도 보유 토픽 | 15 / 114 (13.2%) | 낮음 |
| | 실무 팁 보유 토픽 | 93 / 114 (81.6%) | 양호(텍스트) |
| | Tool 39 · Template 26 | 계약·예산·인사 편중 | §7 도메인 편중 |
| **EVIDENCE** | 법령 본문 보유 토픽 | 114 / 114 (100%) | 양호(텍스트) |
| | 유권해석 보유 토픽 | 93 / 114 (81.6%) | 양호(텍스트) |
| | **구조화 근거 링크(ContentAuthorityLink) 보유 토픽** | **0 / 114 (0%)** | **구조적 공백** |
| | AuditCase 근거 링크 | 195 / 257 (75.9%) | 양호 |
| | Tool 근거 링크 | 14 / 39 (35.9%) | 보통 |

> **핵심**: "글은 있는데 해결까지 못 간다"가 수치로 확인된다.
> ANSWER 층 자산(FAQ 455)은 두껍고, **DO 층(HowTo 55/10토픽)과 구조화 EVIDENCE 층(Topic 링크 0)이 비어 있다.**
> 글 개수를 늘려도 이 두 층은 자동으로 채워지지 않는다.

## 6. Freshness 커버리지 — 전 자산 미판정

| 항목 | 실측 |
|---|---|
| Topic `freshness_state` | **114건 전부 빈 값** |
| Guide `freshness_state` | **103건 전부 빈 값** |
| AuditCase `freshness_state` | **257건 전부 빈 값** |
| `needs_review = true` | 0 |
| `review_due_at` 경과 | 0 |
| `laws.effective_date` NOT NULL | **0 / 15** |

원인은 결함이 아니라 **미가동**이다 — `AuthorityFreshnessCheckJob` 이 `config/recurring.yml` 에 없다
(P1.55B 인계 §4.1). 즉 현재 운영 화면의 현행성 표시는 전부 "미확인" 계열이며,
**FRESHNESS_COVERAGE = 0%** 로 기록한다. 스케줄러 활성화는 별도 승인 사안이라 이번 세션 범위 밖.

## 7. 실측 중 발견한 데이터 결함 2건

### 7.1 FAQ jsonb 파싱 실패 — 공개 토픽 2건 · FAQ 9건 소실 (신규 발견)

```
Topic id=1  slug=bid-announcement (입찰공고)  category=contract  published=true   FAQ 4건 갇힘
Topic id=2  slug=bidding          (입찰)      category=contract  published=true   FAQ 5건 갇힘
```

`faqs` 컬럼에 **JSON 이 아니라 Ruby Hash inspect 문자열**(`"answer"=>"..."`)이 들어 있다.
`Topic#faq_list` 가 `JSON.parse` 실패 → `[]` 반환 → 운영 로그에 매 요청마다
`[Topic#faq_list] JSON 파싱 실패 (id=1)` 이 남는다(측정 중 실제 관측).

결과: **입찰공고·입찰이라는 핵심 계약 토픽의 FAQ 9건이 "바로 답"에도 화면에도 나오지 않는다.**
`howto_steps`·`quick_stats` 는 114/114 정상, Guide/AuditCase 는 무관 — **이 2건이 전부**다.

성격 = **데이터 정정**(P1.6 동결 코드와 무관). 코드는 이미 방어적으로 처리하고 있다.

### 7.2 ~~provenance_confidence 가 UNVERIFIED 를 HIGH 로 표기~~ → **철회 (결함 아님)**

> **2026-09-06 R1 정정.** 아래 판정은 **틀렸다.** `provenance_confidence` 는 "출처 신뢰도"가 아니라
> **분류 판정을 자동 적용해도 되는가**를 나타내는 게이트다(HIGH=자동적용 / MEDIUM=검토큐 / LOW=무변경).
> 정본 = `app/services/audit_case_provenance_classifier.rb` 헤더 + `docs/silmu-p1/PROVENANCE_BACKFILL_REPORT.md` §3.
> 운영에서 분류기를 재실행한 결과 저장값과 **MISMATCH 0 · MEDIUM 0**. 뷰 사용처도 0건이다.
> 상세 = `12_R1_DATA_INTEGRITY_AND_DISCOVERABILITY.md` §2. **아무것도 바꾸지 않았다.**

<details><summary>철회된 원문(기록 보존)</summary>


```
source_type   ACTUAL_AUDIT 86 · SILMU_RECONSTRUCTED_CASE 110 · UNVERIFIED 61
provenance_confidence  HIGH 257  ← 전건
그중 source_type=UNVERIFIED 인데 provenance_confidence=HIGH   61건
is_reconstructed = nil                                        61건
```

`is_reconstructed` 와 `source_type` 사이 **모순은 0건**이다(재구성 사례를 실제 감사로 표시한 건 없음 — PC4 통과).
문제는 다른 축이다: **미검증 61건이 "근거 신뢰도 HIGH" 로 표기**돼 있다.
§19 가 요구한 provenance 구분이 값 자체로는 무너져 있다.

</details>

## 8. CONTENT_MUTATION 실증 = 0

| 지표 | 세션 시작 전(추정 불가 → 첫 측정) 10:43 | 재측정 10:44 | 판정 |
|---|---|---|---|
| `SearchLog.count` | 2,161 | 2,161 | 불변 |
| `SearchLog.maximum(:created_at)` | 2026-09-06T10:24:05+09:00 | 동일 | 세션 시작(10:41) **이전** |
| `Topic.maximum(:updated_at)` | 2026-09-06T00:37:31+09:00 | 동일 | 세션 시작 이전 |
| `Guide.maximum(:updated_at)` | 2026-05-19T13:03:07+09:00 | 동일 | 세션 시작 이전 |
| `AuditCase.maximum(:updated_at)` | 2026-09-06T00:37:31+09:00 | 동일 | 세션 시작 이전 |

세션 실제 시작 = **2026-09-06 10:41:13 KST**. 모든 최종 갱신 시각이 그보다 **앞선다** →
이 세션은 운영 콘텐츠를 쓰지 않았다. 검색 경로도 컨트롤러가 아니라 **모델 직접 호출**로만 재현해
`SearchLog.create` 를 타지 않았다(컨트롤러 `log_search` 우회).

## 9. 검출기 양성대조 (§30)

측정을 믿기 전에 **측정 장치가 양성을 잡는지** 먼저 증명했다.

| 대조 | 방법 | 결과 | 판정 |
|---|---|---|---|
| PC1 있는 것을 있다고 하는가 | "수의계약"·"출장 여비"·"병가" | 각각 토픽 6·6·1 + 바로 답 검출 | **PASS** |
| PC2 없는 것을 없다고 하는가 | "짜장면 곱빼기 결재" 외 2건 | T0 G0 A0 전건 | **PASS** |
| PC3 dev/prod 격차를 구분하는가 | `information-disclosure` | prod 존재 · FAQ 4 · published | **PASS** (§6 교훈 재현) |
| PC4 재구성 사례를 실제 감사로 오분류하는가 | `is_reconstructed` × `source_type` 교차 | 모순 0건 | **PASS**, 단 §7.2 별건 발견 |
| PC5 stale 을 current 로 오분류하는가 | freshness_state · review_due_at | 전건 빈 값 = "current 라고 말한 적 없음" | **PASS** |
| PC6 이 세션이 쓰기를 했는가 | count·max(updated_at) 대조 | 불변 | **PASS** |
| PC7 taxonomy "0건" 이 검출기 탓인가 | 10개 영역 × 5키워드 ILIKE 프로브 | 재산·물품 5토픽·문서/위원회 6토픽 **양성 검출** | **PASS** — 0 은 실제 0 |

PC7 이 중요하다. "정보공개·기록물·민원이 0" 이라는 주장은 같은 프로브가
**다른 영역에서 양성을 잡아냈기 때문에** 신뢰할 수 있다. 검출기가 죽어서 전부 0 이 된 경우가 아니다.

## 10. 측정 스크립트

| 파일 | 용도 |
|---|---|
| `_measure/coverage_audit.rb` | §1~§4 총량·카테고리 |
| `_measure/gap_radar.rb` | 03 문서 — 211 질의 재현 |
| `_measure/positive_control.rb` | §9 PC1~PC6 |
| `_measure/jsonb_integrity.rb` | §7.1 |
| `_measure/taxonomy_probe.rb` | §9 PC7 · 02 문서 |
| `_measure/scope_audit.rb` | 업무카드 게이트·기관범위 |

전부 read-only. 재현 = `ssh root@<운영> 'docker exec -i silmu-web-<rev> bin/rails runner -' < <파일>`
