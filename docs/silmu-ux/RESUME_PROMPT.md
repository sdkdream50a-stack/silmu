# RESUME_PROMPT — P1.6 이후 다음 세션 시작점

> 2026-09-06 마감. 다음 = **P1.6 운영 배포 판단** 또는 P2 콘텐츠 확대(게이트 CONDITIONAL).

## 0. 세션 시작 시

```bash
date; date -u
cd /Users/seong/project/silmu
git fetch --all --prune
git status --short --branch
git log --oneline -5
```

## 1. 현재 상태 (2026-09-06 08:20 KST 실측)

```
BRANCH            feature/silmu-p16-task-first-ux
COMMITS           5  (e0342a7..HEAD) — 구현/문서 4 + 이 문서 갱신 1
                    544ff58 ① 검색 recall 복구 + Answer-First
                    12ff740 ② 업무 중심 네비게이션·홈 + 바로 답 정밀도 교정
                    a84b971 ③ Solution Page 첫 화면
                    7343f78 ④ 산출물 14종 + 개수자랑 회귀 강화
                    (HEAD)  ⑤ 이 RESUME_PROMPT 갱신 — 자기 SHA 는 적지 않는다.
                            정확한 값 = `git rev-parse HEAD`
BASE              fix/tool-accuracy-p1-0804 @ e0342a7
UPSTREAM          없음 (no upstream configured) — PUSH 0
워킹트리           app/test/docs/config/db clean
                  (더티는 .omc/.claude/.gitignore/.mcp.json 환경 잔여물뿐)

테스트            411 runs · 2,963 assertions · 0F · 0E · 14 skips
                  (baseline 362 / 2,731 / 0F / 0E / 14 — skips 불변, 기존 테스트 수정 0)
뮤테이션           35축 · 35 KILLED · 0 SURVIVED (최종 코드 기준 재실행, RESTORE_CHECK clean)
누출/변이          내부 메타데이터 누출 0 · 콘텐츠 자동 변이 0 (둘 다 양성대조 선통과)
라우트/스키마       config/routes.rb · db/schema.rb · db/migrate 변경 0
```

### 독립 검증 — **NOT_OBTAINED** (PASS 아님 · FAIL 아님)

```
승인된 lane       kimi (codex-critic 이 OpenAI 쿼터로 막혀 사용자가 재승인)
결과              2회 모두 TIMEOUT · 산출물 0바이트
  1차            첨부 118KB(전체 diff + docs 2종)          status=timeout dur=300
  2차            첨부 18KB(핵심 로직 diff + SEARCH_UX)     status=timeout exit=124 dur=300
원인              call_worker.sh:283 `jq -r '.timeout // 300'` 가 api backend spec 에
                  timeout 키가 없어 300초를 강제한다. backends.json 의 worker.timeout=1500 은
                  이 경로에 적용되지 않고, KIMI_HTTP_TIMEOUT 도 무력화된다
                  (프로세스가 `timeout -k 5 300` 으로 감싸짐 — ps 실측).
```
**자기승인 금지가 유효하므로, 내 자체검증만으로 PASS 를 선언하지 않았다.**
다음 세션이 독립 검증을 확보해야 P1.6 이 닫힌다.

재시도 경로 (택1):
```
① codex-critic     2026-09-07 14:10 이후 쿼터 리셋 — 원래 배정된 비평 lane
② kimi 재시도       입력을 더 줄이거나(파일 1개씩) call_worker 의 300초 상한을 조정
③ 다른 lane 승인    gemini 등 — 사용자 승인 필요
```

### 운영 상태 — **미배포 (실측 확인)**

```
PRODUCTION_DEPLOYED   NO
PRODUCTION_REVISION   2d05bae (P1.55B) 유지
```
추론이 아니라 측정으로 확인했다.
```
원격 브랜치 중 P1.6 커밋 포함한 것        0개
feature 브랜치 upstream                 미설정
이 세션 kamal/docker deploy 실행         0회
https://silmu.kr/ 원본 응답(cf EXPIRED)  P1.6 마커 4종 전부 absent
                                        구 홈 문구("실무 가이드"·"감사 지적 사례") present
```
단, HTTP 로 배포 SHA 를 직접 읽는 경로가 없어 **SHA 자체는 미직독(UNREAD)** 이고
위 판정은 **콘텐츠 기준**이다. 정확한 SHA 는 배포 호스트에서 확인해야 한다.

## 2. P1.6 이 한 일 (요약)

```
① 자연어 검색 recall 복구 — stopword·조사분리·과반 완화. LLM 없음
② Answer-First — 기존 FAQ 331건을 "바로 답"으로 노출(생성 없음)
③ 업무 중심 네비게이션·홈 — 기존 진입점 삭제 0, URL 변경 0
④ 업무 진입 카드 — 런타임 count 게이트(콘텐츠 생기면 자동 등장)
⑤ Solution Page 첫 화면 — 적용 대상·현행성·지금 해야 할 일
⑥ Zero-result UX — 다른 표현 안내 + 요청 경로
```
문서 정본 = `docs/silmu-ux/` 14종.

## 3. 다음 세션에서 **하지 않는** 것

```
AuthorityFreshnessCheckJob 스케줄러 활성화   별도 승인 사안
LegacyLegalComplianceJob                  영구 비활성
푸터 문구 강화 / nav 에 "법령·변경" 추가      스케줄러 실증 전 금지
main merge / push                         승인되지 않음
P2 일반행정 콘텐츠 대량 생성                 P2_GATE=CONDITIONAL
검색을 LLM/RAG 로 교체                      먼저 현 구조의 한계를 측정한 상태다
동의어 대량 생성                            연상어를 넣으면 "바로 답"이 다른 질문에 답한다(실측)
```

## 4. 이월 항목

| 항목 | 상태 |
|---|---|
| P1.6 운영 배포 | 미실행. 절차 = `PRODUCTION_ROLLOUT.md` (배포 전 `docker info` 필수) |
| 정보공개 콘텐츠 | 전 자산 0건. task test D 가 유일하게 미개선. **P2 1순위** |
| `bid-notice-requirements` category="입찰" | 라우트 제약 밖 고아. 데이터 정정 필요 |
| HowTo JSON-LD malformed step | 선재 결함. 구조화 데이터 품질 |
| `closeDocPopup()` a11y | 선재 결함 |
| Guide/AuditCase Solution Page | 미적용(§41 충돌 위험 높음) |
| `laws.effective_date` | 2026-09-08 07:00 weekly_law_sync 관측 대기 |
| 알림 실도달 | LIVE_UNPROVEN (P1.55B 이월) |
| Docker 배포 우회 A/B/C | 미결정 (BUILDER_RECOVERY §6) |

## 5. 다음 정확한 작업

```
NEXT = P1.6 Production Rollout   (단, 독립 검증 확보가 선행 게이트)
```
Kimi findings remediation 은 **해당 없음** — kimi 가 timeout 으로 끝나 finding 이 0건이다.
고칠 대상이 없으므로 remediation 은 빈 작업이다.

순서:
```
1. 독립 검증 확보   codex-critic(9/7 14:10 이후) 또는 kimi 재시도 또는 다른 lane 승인
2. FAIL 이면        finding severity 별 수리 → 재검증
   PASS 이면        PRODUCTION_ROLLOUT.md 절차 (배포 전 `docker info` 필수)
```

## 6. 재개 문장

```
"실무 P1.6 독립검증 다시"      → codex-critic/kimi 재호출
"실무 P1.6 배포하자"          → PRODUCTION_ROLLOUT.md (검증 확보 후)
"실무 정보공개 콘텐츠 만들자"   → P2_HANDOFF.md §2
"실무 P1.6 검증 결과 봐"       → TEST_REPORT.md
```
