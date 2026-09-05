# RESUME_PROMPT — 다음 세션 시작 프롬프트

```
silmu.kr 을 이어서 한다.

프로젝트: /Users/seong/project/silmu  (Rails 8.1 + PostgreSQL, Kamal 2 → 141.164.53.97)
선행: docs/silmu-audit/(P0) · docs/silmu-p1/(Trust Layer) · docs/silmu-freshness/(Freshness Engine)
      · docs/silmu-production-rollout/(P1.55 운영 배포 — 완료)

시작 전 읽을 것:
  1. docs/silmu-production-rollout/P2_GATE_DECISION.md   ← 지금 무엇을 해도 되나
  2. docs/silmu-production-rollout/SCHEDULER_ACTIVATION.md ← 스케줄러 등록 조건
  3. docs/silmu-production-rollout/P1_6_HANDOFF.md       ← UI Phase 인터페이스 계약
  4. docs/silmu-freshness/LEGACY_JOB_RISK.md            ← 구 잡을 켜면 안 되는 이유

이번 세션 목표 (택1):
  A. P1.6 UI/UX — 홈·네비게이션·검색 아키텍처.
     P1_6_HANDOFF.md §7 충돌 파일 목록을 먼저 확인하고, 상세 페이지(topics/audit_cases show)는
     나중에 손댄다. AuthorityPresenter 경계를 우회해 DB 를 직접 읽지 않는다.
  B. 운영 잔여 — ① Admin UI 재배포(빌더 재생성 후) ② 소스 장애 알림 배선
     ③ 스케줄러 등록(별도 승인) ④ 자연 주기 관측
  C. 콘텐츠 정리 — 본문 내 내부 작업 표현 4건 편집 (P2_GATE_DECISION R3)
  D. Freshness 확장 — 국가공무원 4종 등록(seed 추가만) 또는 조문 전문 수집(Level 3 diff 실적용)

제약:
  - 구 LegalComplianceJob 의 recurring.yml 주석을 해제하지 않는다.
  - Freshness Engine 은 게시 콘텐츠 본문을 절대 수정하지 않는다 (freshness_state 등 3컬럼만).
  - 운영 DB write 는 dry-run → 사람 검토 → 명시적 실행.
  - 일반행정 콘텐츠 대량 확장은 P2_GATE = CONDITIONAL 해제 후.
  - "자동 감지하고 있습니다" 문구는 스케줄러 가동·관측 후에만.

검증:
  bin/rails test                                    # baseline 353 runs / 2,682 assertions / 0F / 0E / 14 skips
  bin/kamal app exec --reuse 'bin/rails silmu:freshness:status'
  bin/kamal app exec --reuse 'bin/rails silmu:p1:leak_scan'
```

---

## 운영 상태 스냅샷 (2026-09-06)

| 항목 | 값 |
|---|---|
| 운영 리비전 | **`1bb1c4e`** (P0+P1+P1.5+파서수정) · Admin UI `f8975b9` **미배포**(빌더 정지) |
| 브랜치 | `fix/tool-accuracy-p1-0804` · 커밋 5개 · **push 안 함** |
| 마이그레이션 | P1 3 + P1.5 3 = **6/6 운영 적용** |
| P1 backfill | **완료** — ACTUAL_AUDIT 86 · RECONSTRUCTED 110 · UNVERIFIED 61 |
| agency HIGH | AuditCase 210 · Topic 15 · Guide 0 |
| Authority 소스/문서/버전 | 1 / 8 / 8 (실제 법제처 데이터) |
| Impact 간선 | **209** |
| 검토 태스크 | 0 (실제 개정 없음 = 정상) |
| 스케줄러 | **DISABLED** (별도 승인 필요) |
| 구 LegalComplianceJob | 주석 그대로 |
| 푸터 | 보수적 문구 유지 |
| P2_GATE | **CONDITIONAL** |
| 백업 | 일일 자동 + `prewrite_20260905_153316.dump` |

## 운영 명령

```bash
bin/kamal app exec --reuse 'bin/rails silmu:freshness:status'         # 관측
bin/kamal app exec --reuse 'bin/rails silmu:freshness:check'          # 수동 수집
bin/kamal app exec --reuse 'bin/rails silmu:freshness:review_queue'   # 검토 큐
bin/kamal app exec --reuse 'bin/rails silmu:p1:leak_scan'             # 누출 검사
bin/kamal rollback 74056244ec9ecef46b6f867d29ed2ebe103cc7cd           # 코드 롤백
```
Admin 화면: `https://silmu.kr/admin/authority_reviews` (로그인 + step-up 인증)

## 함정 (P0~P1.55 에서 실제로 겪은 것)

1. **"0"을 그대로 믿지 말 것.** unchanged 0 은 changed 1 을 먼저 본 뒤에만 의미가 있다.
2. **HTTP 200 ≠ 유효.** law.go.kr 은 가짜 법령명에도 200 을 준다 — `<title>` 로 판별.
3. **렌더 0 ≠ 데이터 0.** P0 이 "원문 링크 0건"이라 했지만 `source` jsonb 에 URL 이 있었다.
4. **필터 뒤만 세면 누출은 항상 0.** 경계 앞(at_risk)을 함께 센다 — 운영 287건.
5. **dev DB 는 정본이 아니다.** audit_cases 191 vs 운영 257.
6. **`db:rollback STEP=n` 은 "적용된 마지막 n개"다.** 실패 상태에서 돌려 P1 backfill 을 잃은 전례.
7. **`disable_ddl_transaction!` 실패는 부분 적용을 남긴다.**
8. **Cloudflare 캐시 4시간.** backfill 직후 조회는 이전 렌더가 나온다 — `?cb=` + `no-cache` 로 우회 검증.
9. **`bin/docker-entrypoint` 가 `db:prepare` 를 돌린다.** 배포 = 마이그레이션 자동 적용.
10. **Devise 통합 테스트에서 재인증 POST 는 불필요하고 세션을 깨뜨린다** — `warden_admin_hook` 이 이미 처리.
11. **kamal buildx 가 멈출 수 있다.** CPU 0.3%·이미지 미푸시면 정지다. `pkill` 후 재시도.
12. **Tailwind 동적 클래스 금지 / ERB 블록 안에서는 `#` 주석.**
