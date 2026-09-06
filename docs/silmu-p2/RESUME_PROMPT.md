# RESUME_PROMPT — P2 AUDIT 이후 다음 세션 시작점

> 2026-09-06 세션 ①(감사) + ②(R1 구현).
> **P2_AUDIT = COMPLETE · R1 = COMPLETE(repo) · 배포 대기.**
>
> ⚠️ **R1 이 감사 결과 3건을 정정했다** — 반드시 `12_R1_DATA_INTEGRITY_AND_DISCOVERABILITY.md` §0 을 먼저 읽을 것.
> P-2(provenance 61건)·P-3(고아 category)은 **결함이 아니었고**, FAQ 도달 수치도 455→465 로 틀렸었다.

---

## 0. 세션 시작 시

```bash
date; date -u
cd /Users/seong/project/silmu
git status --short --branch
git log --oneline -5
curl -sI https://silmu.kr/up | head -1
```

기억한 값보다 실측값이 우선이다.

## 1. 상태 (실측 · 2026-09-06)

```
BRANCH                 feature/silmu-p2-general-admin-expansion
BASE                   f7fb1be (= origin/feature/silmu-p16-task-first-ux tip · P1.6 remote recovery)
PRODUCTION_REVISION    18fb7350cbd07c069775f69aef51c0ca8956982a
ROLLBACK               2d05bae9d99fc47518ae212ea24cd806e8fa67c2
운영 health            200 (/up)
P1_6_STATUS            DEPLOYED · CLOSED/FROZEN — 이 세션에서 한 줄도 건드리지 않았다
MAIN                   무변경 · push 0 · force push 0
```

운영 실측 총량 — Topic 114 · Guide 103 · AuditCase 257 · FAQ 455(저작 464) ·
HowTo step 55 · Tool 39 · Template 26 · Law 15 · SearchLog 2,161.

## 2. ⛔ P1.6 FROZEN — 그대로 유지

`docs/silmu-ux/RESUME_PROMPT.md` 상단 목록이 정본. 요약하면:

```
app/services/search_query_parser.rb
app/models/topic.rb  (search_multiple · relaxed_match · answer_for)
app/views/shared/_solution_status.html.erb
app/views/layouts/_nav_v2.html.erb · app/views/home/index.html.erb
test/models/topic_search_test.rb · test/services/search_query_parser_test.rb  (skip 14건 포함)
```

되돌리면 되살아나는 결함 3종(차비→숙박비 오승격 · 차비⊂주차비 · 연상어 synonym)도 그대로다.
**검색 recall 경로를 건드리면 654-query 지문을 다시 떠야 한다.**

이번 P2 감사는 위 파일을 **한 줄도 읽기만** 했다. 산출물 어디에도 그 수정을 요구하는 항목이 없다.

## 3. 이번 세션이 만든 것

```
docs/silmu-p2/
  01_PRODUCTION_COVERAGE_AUDIT.md   운영 실측 · 3층 커버리지 · 데이터 결함 2건 · 양성대조 7종
  02_ADMIN_TAXONOMY.md              §8 15분류 × 운영 · 오탐 4건 명시 · 기관범위 실측
  03_QUESTION_GAP_RADAR.md          후보 211건 전건 재측정 · GAP_TYPE 분포
  04_PRIORITY_MODEL.md              10축(측정5/판단5) · 35테마 점수 · 분포 기반 임계
  05_TOP_OPPORTUNITIES.md           TOP 20 · §27 필드 전건 · 편향 3종 명시
  06_SOLUTION_PAGE_CANDIDATES.md    §15 섹션×데이터 원천 · PROMOTE 6 / HOLD 2 / NEW 2
  07_FUNCTIONAL_ASSET_CANDIDATES.md 기존 39도구 실측 · 발견성 트랙 · Wizard YES/NO 판정
  08_NEWCOMER_MODE.md               /start 7/7 렌더 실측 · 재료 보유 트랙 5종
  09_AUTHORITY_COVERAGE.md          Authority 8문서 · Topic 링크 0% · provenance 결함
  10_IMPLEMENTATION_ROADMAP.md      선행정정 P-1~3 · 추천 R1~R5 · 승인 지점
  11_MEASUREMENT_EVENTS.md          기존 계측 재사용 · 신규 3건만 · 성과 판정 기준
  _measure/  (6종 read-only 스크립트 — 재측정용)
  _data/     (원자료 JSON)
```

## 4. 감사가 뒤집은 전제 — 다음 세션이 잊으면 안 되는 것

```
착수 전   "P2 = 일반행정 콘텐츠를 넓힌다"
실측 후   콘텐츠 474건은 이미 두껍다. 무너진 것은 DO 층과 발견성이다

  HowTo 보유 토픽          10 / 114   (8.8%)
  Topic 구조화 근거 링크      0 / 114   (0%)
  211 실질의 중 3층 완비     20 / 211   (9.5%)
  도구 39개 중 상위질의 미매칭  상위 20 중 8건
  freshness_state 채워진 콘텐츠  0 / 474
```

**새 글보다 "이미 있는 자산을 답까지 연결하기"가 먼저다.**

## 4-bis. R1 결과 (2026-09-06 · 완료)

```
P-1 FAQ jsonb 정규화   ✅ 운영 적용 — 도달 465 → 474 (9건 회복) · 저작 474 불변 · 내용 창작 0
P-2 provenance 61건    ❌ 결함 아님 — UNCHANGED 61 (분류 게이트를 출처 신뢰도로 오독했던 것)
P-3 고아 category      ❌ 운영에 없음 — dev 전용. 데이터 무변경, 탐지기만 신설
R1  도구 keywords      ✅ 5개 도구·7낱말 — 질의 8개 해소 · 음성대조 5→5 불변 · **배포 전까지 운영 미반영**
테스트                489 runs · 3,125 assertions · 0F · 0E · 14 skips · RuboCop 0 · 뮤테이션 4/4 KILLED
P1.6 동결             7파일 UNCHANGED · 정밀도 가드 3종 운영 재실행 PASS
```

신규 파일: `app/services/faq_payload_normalizer.rb` · `db/content_migrations/20260906120000_faq_jsonb_normalization.rb` ·
`lib/tasks/silmu_faq_integrity.rake` · 테스트 3종. 수정: `app/helpers/tools_helper.rb`(keywords만).

## 5. 다음 행동 — 승인 1건이 필요하다

`10_IMPLEMENTATION_ROADMAP.md` §2 의 R1~R5 중 **무엇을 착수할지**.

| 후보 | 성격 | 크기 | 근거 | 동결 안전 | 상태 |
|---|---|---|---|---|---|
| **배포** | R1 코드를 운영에 반영 | 작음 | — | ✅ | **대기 — 이게 다음 1건** |
| **R2** 수의계약 한도·분할발주 | Moat | 중간 | LOADED | ✅ | 미착수 |
| **R4** 신규자 트랙 3종 | Newcomer | 작음~중간 | — | ⚠️ guides_controller 상수만 | 미착수 |
| **R3** DO 층 10→25 | High-value | 중간~큼 | LOADED | ✅ | 미착수 |
| **R5** 신규 토픽 2건 | 순수 공백 | 중간 | ⚠️ NOT_LOADED — 09 선행 | ✅ | 미착수 |

권장 순서: `배포 → R2 R4 → R3 → (09 적재 판단) → R5`

**TOOL_MISSING 22 테마**(기간제 38 · 일상경비 36 · 휴가 31 · 검사검수 26 · 업무추진비 18 · 선금 16 · 겸직 15 …)는
keyword 로 해소되지 않는다 — 07 문서의 Functional Asset 실제 제작 대상이다.

## 6. 시작하지 않는 것

```
P3 Content Revenue          별도 프로젝트 (§24) · command_center 무수정
Freshness scheduler 활성화   별도 승인
Hermes · 공공데이터 혜택 엔진  §32
대량 editorial write · 자동 발행  AUTO_PUBLISH = OFF
검색 LLM/RAG 교체 · SYNONYMS 확장  P2_HANDOFF §5
main merge / push / force push    승인 없음
```

## 7. 별도 승인으로 남은 이월 항목 (P1.6 에서 그대로)

```
AuthorityFreshnessCheckJob 스케줄러 활성화
laws.effective_date — 2026-09-09(화) 07:00 weekly_law_sync 결과 관측 후 판단
Law(15) ↔ AuthorityDocument(8) 두 스택 관계 확정            ← P2 가 새로 올린 항목
GHCR :credtest 태그 정리
Docker Desktop / credsStore 영구 조치 A/B/C
origin/main 정렬
```

## 8. 재측정하는 법

```bash
# 운영 읽기 전용 실측 (콘텐츠 변이 0)
REV=$(ssh root@141.164.53.97 'docker ps --format "{{.Names}}" | grep ^silmu-web-')
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/_measure/coverage_audit.rb
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/_measure/gap_radar.rb
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/_measure/positive_control.rb
```

`positive_control.rb` 는 **측정 전후에 반드시 돌린다** — PC6 이 콘텐츠 변이 0 을 증명한다.
그리고 "0건"을 보고하기 전에는 PC1·PC2·PC7 이 양성을 잡는지 먼저 확인한다.
