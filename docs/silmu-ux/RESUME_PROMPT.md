# RESUME_PROMPT — P1.6 이후 다음 세션 시작점

> 2026-09-06 10:27 KST 갱신. **P1.6 = DEPLOYED**.
> 운영 리비전 `18fb7350cbd07c069775f69aef51c0ca8956982a`.
> 이번 세션은 배포·검증까지만 하고 멈췄다. P2 는 시작하지 않았다.

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
UPSTREAM           없음 · PUSH 0
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
