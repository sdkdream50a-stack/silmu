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

## 1. 현재 상태

```
BRANCH        feature/silmu-p16-task-first-ux
BASE          fix/tool-accuracy-p1-0804 @ e0342a7
운영 리비전    2d05bae  (P1.55B — P1.6 는 아직 배포 안 됨)
PUSH          없음
테스트        411 runs · 2,963 assertions · 0F · 0E · 14 skips  (baseline 362/2,731/14 → skips 불변)
뮤테이션      35/35 KILLED
마이그레이션   0 · 라우트 변경 0 · 콘텐츠 변이 0
```

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

## 5. 재개 문장

```
"실무 P1.6 배포하자"          → PRODUCTION_ROLLOUT.md 절차
"실무 정보공개 콘텐츠 만들자"   → P2_HANDOFF.md §2
"실무 P1.6 검증 결과 봐"       → TEST_REPORT.md
```
