# RESUME_PROMPT — P1.6 이후 다음 세션 시작점

> 2026-09-06 갱신. 독립검증 **확보 완료 · verdict=FAIL**.
> 다음 = **Answer-First 매칭 정책 결정**(§5). 배포는 그 전에 열지 않는다.

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
COMMITS           6  (e0342a7..HEAD) — 구현/문서 4 + RESUME 갱신 1 + 수리 1(76f616a)
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

테스트            414 runs · 2,971 assertions · 0F · 0E · 14 skips (수리 3테스트 포함)
                  (baseline 362 / 2,731 / 0F / 0E / 14 — skips 불변, 기존 테스트 수정 0)
뮤테이션           35축 + 수리 4축 · 전부 KILLED · 0 SURVIVED · RESTORE_CHECK clean
누출/변이          내부 메타데이터 누출 0 · 콘텐츠 자동 변이 0 (둘 다 양성대조 선통과)
라우트/스키마       config/routes.rb · db/schema.rb · db/migrate 변경 0
```

### 독립 검증 — **FAIL** (2026-09-06 확보 완료)

```
lane             kimi (사용자 승인). codex-critic 은 OpenAI 쿼터로 계속 blocked
방법             18KB 단일 페이로드 재전송 금지 → 서로 독립된 **소형 shard 8개**로 분할
결과             8/8 회수 (A1 재시도 1회 포함)
```
**직전 세션의 timeout 원인은 페이로드 크기가 아니라 인프라였다.**
`producer_guard.resolve_timeout` 이 read tier 를 `DEFAULT_TIMEOUT_PROFILE["read"]=300` 으로
고정하고 registry 의 `timeout:1500` 을 **한 번도 참조하지 않는다**(유효값 fallback 이 조회 실패를 은폐).
harness `_shared/backends.json` 의 kimi 에 `timeout_profile:{read:900}` 을 선언해 해소했다.
실증 = A1 이 300s 에서 죽고, 900s 에서 **384s 로 성공**했다.

#### 확정 결함 (실측 재현됨)
```
[HIGH] 바로 답 1글자 오승격        "차 어떻게" → "…계속비계약의 차이는?"   → **수리 완료(76f616a)**
[HIGH] 낱말 내부 부분일치 잔존      "차비" ⊂ "주차비"                      → **미수리 · OPEN**
[HIGH] 일반 토큰 과반 통과          "차비 지급 기준" → "숙박비 지급 기준"    → **미수리 · OPEN**
[MED]  "기존 진입점 삭제 0" 이 거짓  홈 인기검색어 칩 8개 삭제(질문칩 4개로 교체)·nav 헬퍼 3개 이동
[MED]  task_entry count 이중집계    contract +30 / budget +20 / duty +10 (게이트 전용·판정 불변)
[MED]  JSON-LD HowTo 무명 단계      가시영역은 필터, 스키마는 미필터 (현재 실데이터 120/120 정상 = 0건)
[LOW]  freshness else → 초록        신규 상태 추가 시 자동 "verified" (현재 도달값은 CURRENT 계열뿐)
[LOW]  relaxed_match "과반" 오표기   짝수 토큰에서 정확히 절반
```
#### 독립 재검증(수리분) = **NO_GO**
남은 HIGH 2건이 "바로 답" 의 **확신 있는 오답** 경로를 열어둔다.
수리하려면 Answer-First 매칭 정책(경계 인식 매칭 / distinctive 토큰 필수 /
검색용 동의어와 바로답용 동의어 분리) 중 하나를 **선택**해야 한다 — 최소 수리 범위 밖이다.

#### 반증된 지적 (내 증거 오류가 원인)
```
"테스트 411 이 아니라 431 이어야" → 오류. 신규 6파일 중 3개는 **수정**이다.
                                   20 runs(기존)→50 + 19(신규) = +49. 411 은 정확.
"픽스처 6건 추가로 skip 임계 교차" → 오류. topics.yml 변경은 **주석 6줄뿐**, 토픽 0건 추가.
"verified_on 이 String 이면 500"   → 반증. DB datetime 이다.
"howto_steps 심볼키면 섹션 증발"    → 반증. 실데이터 120/120 문자열 키(jsonb).
"rank_sql SQL 주입 UNKNOWN"        → 해소. sanitize_sql_array/sanitize_sql_like 로 전 경로 안전.
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
NEXT = Answer-First 매칭 정책 결정   (P1.6 배포의 유일한 잔여 게이트)
```
독립 검증은 **확보됐고 verdict 는 FAIL** 이다. 배포는 열지 않는다.
남은 HIGH 2건은 같은 뿌리다 — `answer_for` 가 경계 없는 `include?` 부분일치 위에서
"일반 토큰 과반"만으로 승격을 허용한다.

사용자가 정책 하나를 고르면 그 다음은 기계적이다:
```
A. 경계 인식 매칭        "차비" 가 "주차비" 안에서 안 걸리게. 단 "연가"⊂"연가보상비" 같은
                        의도된 포함관계도 함께 막히므로 허용목록이 필요하다.
B. distinctive 토큰 필수  질의의 가장 긴(또는 첫) 내용 토큰이 반드시 히트해야 승격.
                        "차비 지급 기준" → 차비 미매칭 → NONE. 구현이 가장 작다.
C. 동의어 이원화          검색 recall 용 SYNONYMS 와 바로답 승격용 SYNONYMS 를 분리.
                        recall 을 안 깎지만 유지 대상이 둘로 늘어난다.
```
셋 다 recall 절충이 있으므로 **측정 후 선택**한다 — 5개 task case + 단일토큰 회귀가 기준선이다.

## 6. 재개 문장

```
"실무 P1.6 정책 A/B/C 골랐어"   → §5 선택 후 수리·재검증
"실무 P1.6 독립검증 다시"      → kimi shard 재호출(brief 는 shards/ 에 보존)
"실무 P1.6 배포하자"          → **현재 차단**. 잔여 HIGH 2건 수리 후에만
"실무 정보공개 콘텐츠 만들자"   → P2_HANDOFF.md §2
"실무 P1.6 검증 결과 봐"       → TEST_REPORT.md
```
