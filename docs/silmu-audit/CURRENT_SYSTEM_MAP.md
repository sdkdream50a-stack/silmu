# CURRENT_SYSTEM_MAP — silmu.kr 현행 시스템 지도

> 작성 2026-09-05 · 방법: 실제 저장소·로컬 DB·운영 사이트 전수 크롤(564 URL, 전부 HTTP 200) 실측.
> 추정 금지 원칙에 따라 **측정하지 못한 항목은 `UNMEASURED`로 명시**한다.

---

## 1. 실체 (Repository & Runtime)

| 항목 | 값 | 근거 |
|---|---|---|
| 프로젝트 root | `/Users/seong/project/silmu` | `_shared/projects.md` 별칭 `실무,silmu` → 폴더 `silmu` |
| 현재 브랜치 | `fix/tool-accuracy-p1-0804` (미커밋 변경 다수) | `git status` |
| 최신 커밋 | `7405624 fix(tools): correct qualification evaluation accuracy` | `git log` |
| Framework | Ruby on Rails **8.1** | `db/schema.rb` `ActiveRecord::Schema[8.1]` |
| Ruby / Node | 3.4.8 / 24.12.0 | `.ruby-version`, `.node-version` |
| DB | **PostgreSQL** (확장 `pg_trgm`) · 로컬 `postgresql@16` | `config/database.yml`, `db/schema.rb` |
| 큐/캐시/케이블 | Solid Queue / Solid Cache / Solid Cable (별도 DB) | `config/database.yml` production 4-DB 구성 |
| 배포 | **Kamal 2** → `141.164.53.97` (단일 web) | `config/deploy.yml` |
| 호스트 | `silmu.kr`, `www.silmu.kr`(301), `exam.silmu.kr`(서브도메인 앱) | `config/deploy.yml` proxy.host, `config/routes.rb` |
| 인증 | Devise + OmniAuth | `config/routes.rb` `devise_for` |
| CDN/프록시 | Cloudflare 전제(robots를 컨트롤러 서빙, TTL 제어 주석) | `config/routes.rb` `robots.txt` 주석 |

## 2. 데이터 모델 (23 테이블 / 30 모델)

### 2.1 콘텐츠 코어
| 테이블 | 성격 | 권위 관련 컬럼 |
|---|---|---|
| `topics` | 법령 가이드(사이트의 권위 중심) | `law_content` `decree_content` `rule_content` `interpretation_content` `law_base_date` `law_verified_at` `last_verified_at` `verification_method` `verification_source` `needs_review` `review_reason` `sector` `org_type` |
| `guides` | 업무 가이드/시리즈 | `last_verified_at` `verification_method` `verification_source` `sector` `series` `series_order` `topic_slug` |
| `audit_cases` | 감사 지적 사례 | `legal_basis` `source(jsonb)` `verification_method` `verification_source` `last_verified_at` `severity` `sector` `org_type` `repeated_issue` |
| `laws` | 법령 원문 저장용 | `law_id` `law_type` `ministry` `effective_date` `content` — **로컬 DB 0행** |
| `task_guides` | 업무 AI 가이드 | `status` |
| `standard_terms` | 행정 표준용어(13,208행) | `domain_classification` `revision_round` `agency_name` |

### 2.2 부속·운영
`bookmarks`, `calendar_data`, `cafe_articles`(50,000행 — 커뮤니티 수집), `content_requests`(부정 피드백 backlog), `content_migrations`(콘텐츠 마이그레이션 원장), `law_change_subscriptions`, `search_logs`, `slug_redirects`, `topic_comments`/`topic_events`/`topic_feedbacks`, `analytics_snapshots`, `users`.

### 2.3 exam 서브도메인 (별도 도메인 모델)
`exam_questions`(1,010행), `exam_progresses`, `exam_question_comments`, `exam_question_reports` + `app/models/exam_curriculum/`.

### 2.4 실측 행수 (로컬 `silmu_development`, 2026-09-05)
```
topics 92(pub 92) · guides 103(pub 103) · audit_cases 191(pub 191)
laws 0 · task_guides 5 · standard_terms 13,208 · exam_questions 1,010
cafe_articles 50,000 · search_logs 10 · topic_events 2 · topic_feedbacks 0 · slug_redirects 0 · users 2
```

> ⚠️ **로컬 DB는 운영 정본이 아니다.** 운영 sitemap 기준 audit-cases 257 · topics 114 · guides 107.
> 로컬 dev DB는 각각 191 / 92 / 103 으로 **최대 66건 뒤처져 있다.** 이후 모든 콘텐츠 분석은 운영 HTTP 응답을 정본으로 삼았다.

## 3. 콘텐츠 저장·투입 구조

- **정규 법령 엔티티가 없다.** 법령 본문은 `laws` 테이블이 아니라 `topics`의 `law_content`/`decree_content`/`rule_content`/`interpretation_content` **텍스트 컬럼에 문자열로 중복 저장**된다. `laws` 테이블은 로컬 0행.
- 콘텐츠 투입 경로는 3가지:
  1. `db/seeds/**` — **152개 파일** (주제별 시드 스크립트)
  2. `db/content_migrations/**` — 9개 (법령 정정 배치, `content_migrations` 테이블로 멱등 관리, rake `silmu:content:migrate`)
  3. `POST/PATCH /api/v1/topics` — 외부 `blog_autopilot` 전용 내부 API
- 중앙 상수 파일 2종이 도구·검증의 기준값을 소유:
  - `config/legal_standards.yml` — `version: "2026-02-04"`
  - `config/contract_thresholds.yml` — 마지막 업데이트 `2026-03-28`

## 4. 라우팅·표면 (routes.rb 406줄)

| 표면 | 경로 | 비고 |
|---|---|---|
| 토픽 | `/topics`, `/topics/:key`(9 카테고리), `/topics/:slug` | 권위 중심 |
| 가이드 | `/guides`, `/guides/:slug` + 전용 라우트 5종 | |
| 감사사례 | `/audit-cases`, `/audit-cases/:slug`, `/:slug/hwp` | HWP 내려받기 |
| 서식 | `/templates`, `/templates/:id` | |
| 시리즈 | `/series/:slug` | 8개 |
| 도구 | `/tools` + **37개 개별 도구** | 계산기·판단기·문서생성기 |
| 검색 | `/silmu-search`(구 chatbot) | |
| AI | `/ai-assistant` | |
| 기계 판독 | `/sitemap.xml` `/robots.txt` `/llms.txt` `/llms-full.txt` `/feed.rss` `/.well-known/ai.txt` | |
| 관리자 | `/admin/**` (analytics·pagespeed·content_requests·topic_reviews·comments) + step-up 재인증 | |
| 내부 API | `/api/v1/legal_verify`, `/api/v1/topics` | blog_autopilot 연동 |
| exam 서브도메인 | `exam.silmu.kr/**` | 공공조달관리사 시험 대비 |

SEO 유지용 301 리디렉션이 **30건 이상** 하드코딩되어 있다(POST 전용 엔드포인트의 GET 접근 404 방지 등).

## 5. 애플리케이션 계층

- **컨트롤러 77개** (`app/controllers`) — 도구 1개당 컨트롤러 1개 패턴이 지배적.
- **서비스 32개** (`app/services`) — 도구 엔진(`contract_method_service` 등) + 법령 연동(`law_api_service`, `law_content_fetcher`, `law_alias_resolver`, `regulation_verifier`, `blog_legal_verifier`, `legal_content_renderer`) + SEO(`seo_monitor`, `ga4_service`).
- **잡 17개** (`app/jobs`) — SEO/사이트맵/법령동기화/뉴스레터/AEO 인용 모니터.
- **rake 19개** (`lib/tasks`) — `silmu_legal_lint`, `silmu_content_quality`, `verify_regulations`, `silmu_verification_backfill`, `audit_cases_lint` 등 **품질 도구가 이미 존재**한다.
- **테스트 35개 파일** (`test/`) — controllers·models·services·integration·jobs·helpers·javascript.

## 6. 스케줄 (config/recurring.yml — Solid Queue)

| 잡 | 주기 | 상태 |
|---|---|---|
| `SeoReportJob(weekly)` | 월 09:00 | 활성 |
| `SeoReportJob(monthly)` | 매월 1일 10:00 | 활성 |
| `SeoReportJob(links)` | 수 15:00 | 활성 |
| `SitemapPingJob` | 매일 06:00 | 활성 |
| `GoogleSitemapPingJob` | — | **주석 처리**(2026-05-18 무한루프 사건, Google Ping API 폐지) |
| `LegalComplianceJob(check)` | 월 10:00 | **주석 처리 — 2026-04-13 잠정 중단** |

> 🔴 **법령 정합성 자동 검증 cron이 2026-04-13부터 중단 상태다.** 이것이 §5 감사 결과의 "검증일이 2026-06에서 멈춤"과 직접 연결된다.

## 7. AI / 검색 구조

- **retrieval(질문→문서 검색) 없음.** `app`·`lib`·`config`·`schema.rb` 전체에서 `embedding|pgvector|vector|faiss|semantic search` 일치 **0건**.
- `AiAssistantService` — Claude Haiku 호출. 근거 주입 코드는 **존재한다**: `app/channels/ai_assistant_channel.rb:31-44`가 `topic_slug`를 받으면 해당 토픽의 `law_content`·`decree_content`·`rule_content`·`commentary`·`practical_tips`를 이어붙여 `topic_context`로 넘긴다.
  그러나 **그 경로에 도달하는 링크가 사이트에 없다** — `ai_assistant_path` 참조는 네비게이션 2곳뿐이고 둘 다 `topic_slug` 미전달, 토픽 페이지에 `ai-chat` 위젯 임베드도 없다. 결과적으로 실사용 세션은 무근거로 동작한다.
- 사이트 검색(`/silmu-search`)은 SQL `LIKE`/trgm 기반. `pg_trgm` GIN 인덱스는 `cafe_articles.title`, `standard_terms.synonyms`에만 존재.

## 8. 수집(ingestion)·외부 연동

| 대상 | 코드 | 비고 |
|---|---|---|
| 법제처 OPEN API | `law_api_service`, `law_content_fetcher`, `LawSyncJob`, `LawReferenceWarmJob` | 토픽 법령 딥링크의 원천 |
| 인사혁신처 RSS | `MpmRssMonitorJob` | |
| 커뮤니티(카페) | `lib/tasks/import_articles.rake`, `cafe_articles` 50,000행 | 질문 발굴용 원자재 |
| GA4 | `ga4_service`, `analytics_snapshots` | |
| PageSpeed | `Admin::PagespeedController` | |
| blog_autopilot | `/api/v1/topics`, `/api/v1/legal_verify` | 외부 lane → silmu 쓰기 경로 |

## 9. 이미 존재하는 강점 (재사용 자산)

1. `topics` 114건 전부 **법제처 딥링크 보유** (`<main>` 내 공식기관 링크 813개: law.go.kr 656 · mois 115 · g2b 113).
2. JSON-LD가 풍부하다 — topics에 `Legislation`·`FAQPage`·`HowTo`·`Article`·`SpeakableSpecification`, templates에 `DigitalDocument`.
3. `content_migrations` — 콘텐츠 정정을 멱등·이력추적 가능하게 적용하는 기계장치가 이미 있다.
4. `verification_method` / `verification_source` / `last_verified_at` 컬럼이 3개 콘텐츠 테이블에 **이미 존재**한다 (권위 메타데이터 스키마의 절반이 이미 구축됨).
5. `slug_redirects` 테이블 — 통합·개명 시 301을 데이터로 관리할 수 있다.
6. `legal_standards.yml` / `contract_thresholds.yml` — 기준값 단일화가 이미 되어 있다.

## 10. UNMEASURED (이번 세션에서 확인하지 못한 것)

- 운영 DB 실제 행수·컬럼값 (SSH·DB 접근 미수행. 모든 운영 판단은 공개 HTTP 응답 기반)
- GA4 실제 트래픽·검색 유입·인기 페이지 (자격증명 없음)
- Google Search Console 색인 상태·CTR·카니벌라이제이션 실측
- `exam.silmu.kr` 콘텐츠 품질 (이번 감사 범위 밖)
- 관리자 화면 내부 지표 (로그인 필요)
