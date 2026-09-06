# 13 — R1 PRODUCTION ROLLOUT

> 배포 **2026-09-06 12:09:25 ~ 12:10:44 KST (78.5s)** · 검증 ~12:15 KST
> `PRODUCTION_BEFORE 18fb735` → `PRODUCTION_AFTER ce62d2e`
> 이 문서는 실측 기록이다. exit=0 을 성공으로 치지 않았다.

---

## 1. 배포 대상

```
BRANCH            feature/silmu-p2-general-admin-expansion
APPROVED_HEAD     ce62d2ebee5e465bb230cccf9134e2ada9c71d20
REMOTE_RECOVERY   origin/feature/silmu-p2-general-admin-expansion @ ce62d2e  (신규 브랜치 push · force 아님)
PRODUCTION_BEFORE 18fb7350cbd07c069775f69aef51c0ca8956982a  (P1.6 · 롤백 지점)
PRODUCTION_AFTER  ce62d2ebee5e465bb230cccf9134e2ada9c71d20
MAIN              무변경 — origin/main 7405624 그대로. merge·push 0
DELTA (앱 코드)    7 파일 · +705/-5
                  app/helpers/tools_helper.rb (keywords 8낱말)
                  app/services/faq_payload_normalizer.rb (신규)
                  db/content_migrations/20260906120000_faq_jsonb_normalization.rb (신규)
                  lib/tasks/silmu_faq_integrity.rake (신규)
                  test/ 3종 (신규)
SCHEMA            20260906065000 → 20260906065000 (마이그레이션 0)
ROUTES            변경 0
```

## 2. Docker preflight — P1.55/P1.6 trap 그대로 재현

```
docker info   → Server: failed to connect ... /Users/seong/.docker/run/docker.sock (Docker Desktop OFF)
~/.docker/config.json → credsStore: "desktop" · currentContext: "desktop-linux"
```

그대로 `kamal deploy` 했다면 GHCR 인증에서 멈춘다. `BUILDER_RECOVERY.md` **방식 C(격리 DOCKER_CONFIG)** 만 사용했다.

- `~/.docker` 전체를 scratchpad 로 복사 → `credsStore`·`credHelpers` 제거 → `auths["ghcr.io"].auth` 주입 → `chmod 600`
- **전역 `~/.docker/config.json` 무변경** (배포 후 재확인: `credsStore=desktop` · `currentContext=desktop-linux` 동일)
- 토큰은 파일에만 기록. 출력·로그 미노출

## 3. 배포 명령

```bash
DOCKER_CONFIG=<격리사본> bin/kamal deploy --version=ce62d2ebee5e465bb230cccf9134e2ada9c71d20
```

`--version` 명시 이유는 P1.6 과 같다 — 워킹트리에 `.omc/`·`.claude/`·`.mcp.json`·`.gitignore` 환경 잔재가
더티로 남아 있어 kamal 기본 버전 산출이 `<sha>_uncommitted_<hex>` 를 만든다.
그러면 운영 리비전이 승인 SHA 와 달라져 SHA 기반 롤백 의미가 깨진다.
**환경 잔재는 커밋하지 않았다**(다른 세션 소유분 포함).

```
INFO First web container is healthy on 141.164.53.97
Finished all in 78.5 seconds
EXIT=0
```

## 4. 배포된 artifact 가 정말 ce62d2e 인가

`kamal app version` → `ce62d2ebee5e465bb230cccf9134e2ada9c71d20`
컨테이너 → `silmu-web-ce62d2e...` · Up · `/up` = 200

**컨테이너 안 파일과 `git rev-parse ce62d2e:<path>` blob 해시 대조:**

| 파일 | 판정 |
|---|:--:|
| `app/helpers/tools_helper.rb` | **MATCH** |
| `app/services/faq_payload_normalizer.rb` | **MATCH** |
| `lib/tasks/silmu_faq_integrity.rake` | **MATCH** |
| `db/content_migrations/20260906120000_faq_jsonb_normalization.rb` | **MATCH** |
| `app/models/topic.rb` (동결) | **MATCH** |
| `app/services/search_query_parser.rb` (동결) | **MATCH** |

## 5. FAQ content migration — 중복 적용 없음

**배포 훅이 content migration 을 자동 실행하지 않는다**(실측):
`bin/docker-entrypoint` 는 `./bin/rails db:prepare`(스키마)만 돌리고,
`silmu:content_migrate` 는 `.kamal/hooks/*` 어디에도 없다.

| 지표 | 배포 전 | 배포 후 |
|---|---:|---:|
| FAQ 저작 | 474 | **474** |
| FAQ 도달가능 | 474 | **474** |
| FAQ 소실 | 0 | **0** |
| 비배열 payload | 0 | **0** |
| 저장형태 | array 114 | **array 114** |
| `ContentMigration` 행 수 | 9 | **9** (`20260906120000` 미기록 = 미실행) |

§5 지시대로 **임의 재실행하지 않았다.** 멱등성은 이미 증명돼 있다 —
dev 에서 2차 실행 0건, 그리고 마이그레이션의 첫 분기가 `next if raw.is_a?(Array)` 인데
운영은 114/114 배열이므로 실행해도 write set 이 구조적으로 공집합이다.

## 6. R1 도구 발견성 — **운영에서 8/8 재현** ✅

측정은 모델 호출이 아니라 **실제 사용자 경로**(`GET /silmu-search/search` · Turbo-Frame)로 했고,
Cloudflare 캐시는 질의마다 고유 파라미터로 우회했다(`cf-cache-status: BYPASS` 확인).

| # | 질의 | BEFORE | AFTER | 운영에서 노출된 도구 링크 |
|---:|---|---:|---:|---|
| 1 | 수의계약 한도 | 0 | **1** | `/tools/contract-method` |
| 2 | 수의계약한도 | 0 | **1** | `/tools/contract-method` |
| 3 | 소액수의 | 0 | **1** | `/tools/contract-method` |
| 4 | 분할발주 | 0 | **1** | `/tools/split-contract-checker` |
| 5 | 분리 발주 | 0 | **1** | `/tools/split-contract-checker` |
| 6 | 수입인지 | 0 | **1** | `/tools/contract-guarantee` |
| 7 | 보조금정산 | 0 | **1** | `/tools/subsidy-settlement-checker` |
| 8 | 국외출장 / 국외 | 0 | **1** | `/tools/travel-calculator` |

**HTML 에 낱말이 있는 것과 도달 가능한 것은 다르다** — 그래서 두 가지를 더 봤다.

1. 링크 대상 5종 전부 **HTTP 200**
2. 모바일 390px 검색 결과에서 그 링크가 **실제로 보이고 눌린다**:
   `/tools/contract-method` · **350×72px** · `turbo-frame#search-results` 안 ·
   라벨 "계약방식 결정 도우미 — 추정가격과 계약유형으로 적정 계약방식과 필요서류를 확인합니다."

## 7. 음성대조 — precision 유지 ✅

| 질의군 | 결과 |
|---|---|
| 병가 · 특별휴가 · 육아휴직 · 겸직 · 검수 · 선금 · 업무추진비 · 일상경비 | 전건 **도구 0건** |
| 병가 진단서 · 지급 기준 · 정보공개 처리기한 · 민원 처리기한 · 기록물 이관 | 전건 **도구 0건** |
| 계약 (넓은 질의) | **4건** — 변경 전과 동일 |
| 출장비 · 이월 · 전용 · 인지세 · 연말정산 · 설계변경 · 초과근무 · 수도광열비 · 집행률 | 각 **1건** — 변경 전과 동일 |
| **발주** | **1건** (`split-contract-checker`) — **승인된 기존 baseline** |

`발주` 0→1 은 substring AND 매칭의 구조적 파급으로 이미 판정·테스트 고정된 항목이다.
**이것 말고 새로 늘어난 false positive 는 0건.**

## 8. P1.6 회귀 — 운영 재확인 ✅

동결 7파일 `git diff f7fb1be ce62d2e` **전건 UNCHANGED** → 배포 artifact 안에서도 blob MATCH.
`SEARCH_CODE_TOUCHED = NO` → 654-query 지문 재측정 불필요.

**Answer-First 정밀도 가드 3종** (운영 HTTP 경로)

| 질의 | 바로 답 | 검색 결과 | 판정 |
|---|---|---:|---|
| 차비 지급 기준 | **없음** | 토픽 2 | PASS — 숙박비 오승격 없음 |
| 차비 얼마 | **없음** | 토픽 2 | PASS — 차비⊂주차비 없음 |
| 지급 기준 | **없음** | 토픽 6 | PASS — 고유 토큰 0 → 정직한 nil |

검색은 살아 있고 틀린 답만 없다.

**task case 5종** (운영 HTTP 경로)

| 질의 | 토픽 | 바로 답 |
|---|---:|---|
| 수의계약 한도 | 7 | 수의계약 한도 금액에 부가세가 포함되나요? |
| 병가 며칠 쓰면 진단서 내야 하나요 | 2 | 병가에 진단서는 언제부터 제출해야 하나요? |
| 출장비 얼마 지급하나 | 7 | 자가용으로 출장 시 여비는 어떻게 받나요? |
| 정보공개 처리기한 | 1 | — (03 문서의 기존 NO_DIRECT_ANSWER 갭 그대로) |
| 처음 계약을 맡았어요 | 6 | — (기존 WEAK_CONTENT 그대로) |

## 9. FAQ 무결성 — 되살아난 9건이 공개 화면에 있다 ✅

| 토픽 | 도달 FAQ | 저장형태 |
|---|---:|---|
| `bid-announcement` | 4 | Array |
| `bidding` | 5 | Array |
| `estimated-price` | 5 | Array |
| `late-penalty` | 5 | Array |

대표 질의 `입찰공고 기간` → 운영 "바로 답":
> **입찰공고 기간은 최소 며칠인가요?**
> 추정가격에 따라 다릅니다. 10억원 미만: 7일, 10억~50억원: 15일, 50억원 이상: 40일 이상입니다. …

**CONTENT_INVENTED = 0** — 공개 토픽 페이지 본문과 복구 원문(롤백 payload)을 대조했다.

| 토픽 | 질문 원문 일치 | 답변 원문 일치 |
|---|---|---|
| `bid-announcement` | **4/4** | **4/4** |
| `bidding` | **5/5** | **5/5** |

## 10. 모바일 390px / SEO

**모바일** (Playwright · 390×844)

| 화면 | 가로 오버플로 | 비고 |
|---|---|---|
| HOME `/` | **0** (scrollW 382 = clientW 382) | |
| SEARCH RESULTS `/silmu-search?q=수의계약 한도` | **0** | 바로 답 렌더 · 토픽 링크 25 · 도구 링크 350×72 클릭 가능 |
| TOOL LANDING `/tools/split-contract-checker` | **0** | h1 정상 · 가시 인터랙티브 50 |

> **검출기 양성대조**: 일부러 900px 요소를 주입하니 `overflowCount 1 · scrollW 900` 으로 잡혔고,
> 제거하니 0 으로 돌아왔다. 즉 위의 `0` 은 검출기가 죽어서 나온 0 이 아니다.

선재 항목(이번 범위 밖): 탭 타깃 24px 미만 28개 · 서드파티 스크립트 콘솔 오류 4건
(Clarity·CF Insights·GTM·iconify). R1 은 뷰·JS·에셋을 **한 줄도 바꾸지 않았다**(diff 공란).

**SEO**

```
/ · /start · /topics · /tools · /templates · /guides · /audit-cases · /silmu-search
/topics/{private-contract-limit, bid-announcement, bidding}
/tools/{contract-method, split-contract-checker}          → 전건 HTTP 200
/sitemap.xml 200 · /robots.txt 200
canonical 3건 표본 정상 · routes.rb 변경 0 · 신규 redirect/404 0
```

## 11. Authority / Freshness — 무변경 ✅

| 지표 | 배포 전 | 배포 후 |
|---|---|---|
| AuthoritySource / Document / Version / ChangeEvent | 1 / 8 / 8 / 8 | **동일** |
| ReviewTask / VerificationEvent | 0 / 0 | **동일** |
| ContentAuthorityLink | 209 | **동일** |
| `freshness_state` | 전건 빈 값 | **동일** |
| `laws.effective_date` NOT NULL | 0 | **동일** |
| **SCHEDULER** | OFF | **OFF** |

`AUTHORITY_FRESHNESS_CORE_MODIFIED = NO`. 코드 diff 도 공란.

## 12. P-2 / P-3 — 다시 "수리"하지 않았다 ✅

§1 지시대로 감사에서 정정된 항목을 재차 건드리지 않았다.

| 항목 | 배포 전 | 배포 후 |
|---|---|---|
| provenance (`source_type`\|`confidence`) | UNVERIFIED\|HIGH 61 · ACTUAL_AUDIT\|HIGH 86 · RECONSTRUCTED\|HIGH 110 | **동일** |
| `topics.category` 분포 | 9종 | **동일** |

## 13. 변이 회계 (§16)

| 대상 | EXPECTED | ACTUAL |
|---|---|---|
| R1 tool keywords (코드 배포) | 5 도구 · 8 낱말 | **동일** |
| P-1 FAQ 정규화 (이미 적용됨) | 추가 변이 **0** | **0** |
| Topic / Guide / AuditCase 본문 | 0 | **0** (건수·`max(updated_at)` 불변) |
| provenance metadata | 0 | **0** |
| category | 0 | **0** |
| Authority / Freshness 데이터 | 0 | **0** |
| 스키마 마이그레이션 | 0 | **0** |
| **UNEXPECTED_MUTATION** | 0 | **0** |

**부수 변이 1건 — `SearchLog` 2,161 → 2,206 (+45).**
§9 가 "실제 도달 경로로 확인"을 요구했고, 운영 검색 컨트롤러는 매 질의마다 `SearchLog` 를 남긴다.
즉 이 45행은 **내 검증 질의 기록**이며 콘텐츠 변이가 아니다. 계측 로그를 오염시킨 셈이므로 적어 둔다 —
다음에 `SearchLog` 로 갭을 잴 때 2026-09-06 12:10~12:15 구간은 사람 트래픽이 아니다.

## 14. 롤백

```
ROLLBACK_TARGET   18fb7350cbd07c069775f69aef51c0ca8956982a   (서버에 이미지 보유)
ROLLBACK_READY    YES
ROLLBACK_EXECUTED NO — §17 FAIL 조건 0건
명령              DOCKER_CONFIG=<격리사본> bin/kamal app version   (현재 확인)
                  DOCKER_CONFIG=<격리사본> bin/kamal deploy --version=18fb7350cbd07c069775f69aef51c0ca8956982a
```

§17 FAIL 조건 대조: 도구 8/8 재현 ✅ · 음성대조 증가 0 ✅ · P1.6 회귀 0 ✅ ·
FAQ 변형/소실 0 ✅ · 500/주요 404 0 ✅ · Authority/Freshness 변화 0 ✅ · 예상 외 변이 0 ✅

## 15. 남은 것

1. `bin/rake silmu:faq_integrity` · `silmu:category_integrity` 를 배포 후 체크나 CI 에 붙일지 판단
2. GHCR 시험 태그 `:credtest` 정리 (P1.55A 잔재 · 이번에도 미삭제)
3. Docker Desktop / credsStore 영구 조치 A/B/C 미결 — 매 배포마다 격리 config 를 다시 만든다
4. `db/content_migrations/20260906120000` 은 운영 `ContentMigration` 에 미기록.
   다음에 `silmu:content_migrate` 를 돌리면 실행되지만 write set 은 공집합이다(§5)
