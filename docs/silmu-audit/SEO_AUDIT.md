# SEO_AUDIT — 검색·구조화 데이터 감사

> 방법: 운영 sitemap 564 URL 전수 크롤(전부 HTTP 200) + `<main>` 본문 분리 분석.
> 원칙: **SEO용 글을 따로 찍어내지 않는다.** `Question → Solution Page → Evidence → Tool` 구조 자체가 자산이 되게 한다.
> ⚠️ GSC·GA4 자격증명이 없어 **색인 상태·CTR·실제 카니벌라이제이션은 UNMEASURED**다. 아래는 전부 사이트 자체에서 관측 가능한 사실이다.

---

## 1. 총괄

| 지표 | 값 | 판정 |
|---|---:|---|
| sitemap URL | 564 | — |
| HTTP 200 응답률 | **564 / 564 (100%)** | ✅ dead link 0 |
| canonical 불일치 | **1** | ⚠️ |
| `<title>` 완전 중복 | **6건 (2그룹)** | ⚠️ |
| meta description 부재/과단(<70자) | **57** | ⚠️ |
| `<title>` 65자 초과 | **58** | ⚠️ |
| thin content (<800자) | **30** | ⚠️ |
| 내부링크 인바운드 0 (고아) | **54** | ⚠️ |
| `<h1>` 개수 이상 | 2 (0개 1건, 5개 1건) | ⚠️ |
| `<article>` 시맨틱 태그 | **0** (전 페이지) | ⚠️ |

sitemap 구성: audit-cases 258 · topics 115 · guides 108 · tools 38 · templates 27 · series 8 · static 10.

---

## 2. 구조화 데이터 (JSON-LD) — 강점과 공백

| 섹션 | 보유 타입 | 판정 |
|---|---|---|
| topics (114) | `Article` 111 · `Legislation` 114 · `FAQPage` 112 · `HowTo` 10 · `BreadcrumbList` 114 · `SpeakableSpecification` 114 · `DefinedTerm` 115 · `Audience`/`EducationalAudience` | ✅ 매우 우수 |
| audit-cases (257) | `Article` 257 · `BreadcrumbList` 257 · `SpeakableSpecification` 257 | ⚠️ **`Legislation` 0 · `FAQPage` 0** |
| guides (107) | `HowTo` 103 · `FAQPage` 81 · `BreadcrumbList` 103 | ✅ 양호 |
| templates (26) | `DigitalDocument` 26 | ✅ |
| tools (37) | `WebSite`/`Organization`만 | 🔴 **도구 전용 스키마 0** |

**핵심 공백 2개**
1. **감사사례에 `Legislation` 연결이 없다.** 근거 법령을 본문에 쓰면서 구조화하지 않는다 — TR-01(원문 링크 0건)과 같은 뿌리다.
2. **도구 37개에 `SoftwareApplication`/`HowTo` 스키마가 없다.** "실무 도구"는 이 사이트의 최대 차별점인데 검색엔진에는 일반 페이지로 보인다.

또한 토픽에는 `reviewedBy: {"@type":"Organization","name":"실무.kr 법령검증팀"}`와 `contentReferenceTime`이 이미 들어 있다 — **E-E-A-T 신호가 이미 구조화되어 있다.** 문제는 이 신호를 뒷받침할 검증이 3개월 멈춘 것이다(TR-05).

---

## 3. 카니벌라이제이션

### 3.1 완전 동일 `<title>` — 즉시 수정 대상
| 중복 제목 | URL |
|---|---|
| `Q&A 20문항 총정리 — 왕초보 완전정복 10편 \| 실무.kr` (**4건**) | `/guides/budget-execution-complete-10`<br>`/guides/construction-contract-complete-10`<br>`/guides/hr-welfare-complete-10`<br>`/guides/travel-expense-complete-10` |
| `지방보조금 완전정복 4편 — 보조금 집행 실무 \| 실무.kr` (**2건**) | `/guides/local-subsidy-complete-4`<br>`/guides/local-subsidy-guide` |

첫 그룹은 **시리즈명이 제목에서 빠져** 4개 시리즈의 10편이 전부 같은 제목이 됐다.
→ `[시리즈명] Q&A 20문항 총정리 — N편` 형태로 시리즈 접두어를 넣으면 해결된다. `guides.series` 컬럼이 이미 있다.

### 3.2 유사 주제 클러스터 7개
`분할수의계약` 5건, `계약방법 부적정` 2건, `정당채주 지급 위반` 2건, `수의계약 체결 부적정` 2건 등.
→ 감사사례는 사례별 고유성이 있으므로 **통합보다 허브 페이지(TASK) 아래 정렬**이 옳다.

---

## 4. 고아 페이지 54건

| 섹션 | 건수 |
|---|---:|
| audit-cases | **53** |
| guides | 1 |

sitemap에는 있으나 사이트 내부 어디에서도 링크되지 않는다. 대부분 `goe-2021-*` 계열이다.
→ **감사사례 목록/카테고리 페이지의 노출 규칙이 일부 사례를 누락**하고 있음을 시사한다.
→ 신 IA의 TASK 허브가 만들어지면 자연히 해소된다(모든 사례는 TASK에 붙는다).

---

## 5. 메타데이터 결손

| 항목 | 섹션별 |
|---|---|
| description <70자 | templates **26/26** · topics 18 · guides 8 · tools 3 · static 2 |
| title >65자 | 58건 (주로 감사사례 — `… — 감사 지적 사례와 실무 대응 방법 \| 실무.kr` 접미어가 길다) |
| thin <800자 | templates **26** · static 2 · tools 2 |

**templates 26건이 세 지표를 모두 위반한다** (본문 중앙값 527자, description 전무).
→ 삭제 대상이 아니다. 서식은 검색 수요가 확실하다. **서식별 근거·작성요령·관련 TASK 링크를 붙여 보강**한다.

감사사례 제목 접미어(`— 감사 지적 사례와 실무 대응 방법`)는 SERP에서 절삭되면서 모든 결과가 비슷해 보이게 만든다.
→ 접미어를 짧게(`— 감사사례`) 하거나 제거하고, 차별점(기관·처분·금액)을 앞으로 옮긴다.

---

## 6. 기술 SEO

| 항목 | 상태 |
|---|---|
| canonical | 563/564 정상 · **`/tools/quote-review` 1건 비어 있음** |
| robots meta | 이상 없음 |
| `www` → apex 301 | ✅ (`routes.rb` 호스트 제약) |
| `sitemap.xml` | ✅ 동적 생성 |
| `robots.txt` | ✅ 컨트롤러 서빙 (Cloudflare TTL 제어) |
| `llms.txt` / `llms-full.txt` | ✅ 40KB / 563KB — **AI 검색 대응 자산** |
| `/.well-known/ai.txt` | ✅ 301 |
| RSS | ✅ `/feed.rss` |
| 404 방지 301 | 30+건 하드코딩 (POST 전용 엔드포인트 GET 접근 등) |
| `<article>` 시맨틱 | **0건** — 본문 경계가 기계에 명확하지 않음 |
| sitemap 누락 | 확인된 것 없음 (564 = 전 공개 URL로 보임) |

---

## 7. 우선순위

| 순위 | 항목 | 근거 | 비용 |
|---|---|---|---|
| 1 | 중복 `<title>` 6건 해소 | 직접 카니벌라이제이션 | 매우 낮음 |
| 2 | `/tools/quote-review` canonical 복구 | 명백한 버그 | 매우 낮음 |
| 3 | 감사사례에 `Legislation` JSON-LD 추가 | TR-01과 동시 해결 | 낮음 |
| 4 | 도구에 `SoftwareApplication`+`HowTo` 스키마 | 최대 차별점의 미노출 | 낮음 |
| 5 | templates 26건 description·본문 보강 | 세 지표 동시 위반 | 중간 |
| 6 | 감사사례 제목 접미어 단축 | SERP 동질화 | 낮음 |
| 7 | 고아 53건 링크 연결 | TASK 허브로 해결 | 중간 (IA 의존) |
| 8 | `<article>` 시맨틱 도입 | 본문 경계 명확화 | 낮음 |

> **금지:** 순위 개선을 위한 신규 콘텐츠 대량 생성. P0 감사 종료 전 P3 착수 금지(§20).
