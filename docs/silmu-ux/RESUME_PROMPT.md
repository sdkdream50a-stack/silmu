# RESUME_PROMPT — P1.6 이후 다음 세션 시작점

> 2026-09-06 10:36 KST 최종. **P1.6 = DEPLOYED · CLOSED/FROZEN**.
> 운영 리비전 `18fb7350cbd07c069775f69aef51c0ca8956982a`.
> 배포·검증·보존까지 끝났다. P2 는 시작하지 않았다.

## ⛔ P1.6 BASELINE — FROZEN

```
P1_6_STATUS            DEPLOYED · CLOSED/FROZEN (2026-09-06 10:36 KST)
PRODUCTION_REVISION    18fb7350cbd07c069775f69aef51c0ca8956982a
ROLLBACK_REVISION      2d05bae9d99fc47518ae212ea24cd806e8fa67c2   (P1.55B · 서버에 이미지 보유)
REMOTE_RECOVERY_BRANCH origin/feature/silmu-p16-task-first-ux @ ee2ab24
                       (= 18fb735 + 배포기록 docs 커밋 1. 18fb735 가 원격의 조상임을 확인)
MAIN                   무변경 — main 에 P1.6 커밋 0. merge·push 하지 않았다.
```

**P2 는 아래 파일을 baseline 으로 취급한다. 무심코 고치지 말 것.**
고쳐야 한다면 먼저 이유를 적고, 회귀(430 runs·뮤테이션 12축)를 다시 돌린 뒤에 건드린다.

| 파일 | 이 파일이 지키는 것 |
|---|---|
| `app/services/search_query_parser.rb` | STOPWORDS·PARTICLES(자연어 recall) · `GENERIC_TOKENS`·`answer_tokens`(Answer-First 정밀도) |
| `app/models/topic.rb` — `search_multiple`/`relaxed_match` | 검색 recall. **654 쿼리 지문으로 불변 실증됨** — 손대면 그 지문을 다시 떠야 한다 |
| `app/models/topic.rb` — `answer_for` | DISTINCTIVE TOKEN GATE. 일반토큰 오승격·낱말 안쪽 부분일치 차단 |
| `app/views/shared/_solution_status.html.erb` | Freshness 를 presenter 출력으로만 표시(뷰 자체 추론 금지) |
| `app/views/layouts/_nav_v2.html.erb` · `home/index.html.erb` | 업무 중심 IA·진입점 |
| `test/models/topic_search_test.rb` · `test/services/search_query_parser_test.rb` | 위 성질의 회귀. **기존 skip 14건 건드리지 말 것** |

특히 다음 3가지는 **되돌리면 실제 결함이 되살아난다**(전부 실측 재현 이력 있음):
1. `answer_for` 의 distinctive 게이트 제거 → "차비 지급 기준"에 "숙박비 지급 기준"이 답으로 뜬다
2. 낱말경계 완전일치를 `include?` 로 환원 → "차비"가 "주차비" 안쪽에서 걸린다
3. `SYNONYMS` 에 연상어 재유입(차비→여비 등) → 상위범주 FAQ 가 확신 있게 승격된다

## 0. 세션 시작 시

```bash
date; date -u
cd /Users/seong/project/silmu
git status --short --branch
git log --oneline -5
DOCKER_CONFIG=<격리사본> bin/kamal app version   # 운영 리비전 실측
```

## 1. 현재 상태 (실측)

```
BRANCH             feature/silmu-p16-task-first-ux
HEAD               (git rev-parse HEAD 로 확인 — 자기 SHA 는 적지 않는다)
BASE               fix/tool-accuracy-p1-0804 @ e0342a7
UPSTREAM(갱신)      origin/feature/silmu-p16-task-first-ux  ← 2026-09-06 push 완료(신규 브랜치·force 아님)
운영 리비전         18fb7350cbd07c069775f69aef51c0ca8956982a   ← P1.6
직전 운영 리비전     2d05bae9d99fc47518ae212ea24cd806e8fa67c2   ← 롤백 지점(서버에 이미지 보유)
워킹트리            app/test/config/db clean
                   (더티는 .omc/.claude/.gitignore/.mcp.json 환경 잔여물 — 다른 세션 소유분 포함,
                    커밋하지 말 것)
테스트              430 runs / 3,008 assertions / 0F / 0E / 14 skips
뮤테이션            12/12 KILLED · SURVIVED 0
독립검증            kimi shard R1·R2·R3 전부 PASS_WITH_NONBLOCKING_FINDINGS · 차단 0
```

## 2. 배포·검증 산출물

- `docs/silmu-ux/PRODUCTION_ROLLOUT.md` — 배포 실측(Docker trap · artifact 대조 · 캐시 구분 · 롤백)
- `docs/silmu-ux/PRODUCTION_SMOKE.md` — 5개 업무 질의 · 정밀도 가드 3건 · Solution · 모바일 · SEO · 누출 · 콘텐츠 변이 · 스케줄러

## 3. 이번 세션이 남긴 것 (다음 세션 판단 필요)

1. **콘텐츠 공백 — 수의계약 한도**
   `private-contract-limit` FAQ 2건이 모두 "한도 금액이 얼마인가"를 표제로 답하지 않는다.
   Answer-First 는 온토픽 FAQ 를 정직하게 고르고 있으나 사용자가 가장 원하는 답이 없다.
   → **편집 backlog**(콘텐츠 작업이지 코드 작업이 아니다).

2. **인계 문서 정정 — 정보공개**
   "정보공개 콘텐츠 0건"은 development DB 기준이었다. 운영에는 `information-disclosure`
   토픽과 FAQ 4건이 실재한다. dev/prod 데이터 격차를 전제로 판정하지 말 것.

3. **Answer-First 정책 C(동의어 이원화)** — 미착수. 필요성이 실측되면 착수.
   현재 정책 B(distinctive token gate)로 HIGH 2건은 닫혔다.

4. **단일 토큰 질의 12건의 바로 답 상실** — 정책 B 의 구조적 비용(검색 결과는 유지).
   되살리려면 낱말 안쪽 부분일치를 재개방해야 하고 그러면 "차비⊂주차비"가 함께 돌아온다.
   → 형태소 분석 없이는 해소 불가. 열지 않았다.

5. **GHCR 시험 태그 `:credtest`** — P1.55B 가 남긴 정리 대상. 이번 세션도 삭제하지 않았다.

6. **Docker Desktop / credsStore 영구 조치 미결** — 매 배포마다 격리 DOCKER_CONFIG 를
   손으로 만든다. A/B/C 중 영구 채택은 사용자 환경 결정 사항.

## 4. 다음 작업 후보 (이번 세션에서 시작하지 않음)

- P2 일반행정 확장
- 정보공개 신규 콘텐츠
- Freshness scheduler enable
- AI/RAG 검색
