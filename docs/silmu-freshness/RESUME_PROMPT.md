# RESUME_PROMPT — 다음 세션 시작 프롬프트

```
silmu.kr 을 이어서 한다.

프로젝트: /Users/seong/project/silmu  (Rails 8.1 + PostgreSQL, Kamal → 141.164.53.97)
선행: docs/silmu-audit/ (P0 감사) · docs/silmu-p1/ (Authority Trust Layer)
      · docs/silmu-freshness/ (P1.5 Freshness Engine, 구현 완료 · 운영 미배포)

시작 전 읽을 것:
  1. docs/silmu-freshness/CURRENT_FRESHNESS_ARCHITECTURE.md  ← 무엇이 만들어졌나
  2. docs/silmu-freshness/PRODUCTION_ROLLOUT_PLAN.md         ← 운영 적용 절차 (Stage 1~7)
  3. docs/silmu-freshness/P2_GATE.md                         ← 지금 무엇을 해도 되나
  4. docs/silmu-freshness/LEGACY_JOB_RISK.md                 ← 구 잡을 켜면 안 되는 이유

이번 세션 목표 (택1, 위에서부터 권장):
  A. 운영 배포 — ROLLOUT_PLAN Stage 1~6.
     각 Stage 마다 판정 기준을 확인하고, dry-run 결과를 사람이 검토한 뒤 다음 단계로 간다.
     Stage 7(스케줄 등록)은 Stage 4~6 성공 후에만.
  B. P1 잔여 — AI 근거 주입 배선 1줄 + 도구 기준값 2종 갱신 (P2_GATE §5)
  C. Freshness 확장 — 국가공무원 4종 등록(seed 추가만) 또는 행정규칙 fetcher

제약:
  - 구 LegalComplianceJob 의 recurring.yml 주석을 해제하지 않는다 (LEGACY_JOB_RISK.md).
  - 엔진은 게시 콘텐츠 본문을 절대 수정하지 않는다. freshness_state 등 3컬럼만.
  - 운영 DB write 는 자동 실행 금지. dry-run → 사람 검토 → 명시적 실행.
  - 스키마 변경은 additive·nullable·reversible. strong_migrations 우회 금지.
  - 확실히 식별되지 않는 법령에 링크·간선을 만들지 않는다.
  - 일반행정 콘텐츠 대량 확장은 P2_GATE 통과 후.

검증:
  bin/rails test                                   # baseline 339 runs / 2,635 assertions / 0F / 0E / 14 skips
  bin/rubocop <변경 파일>
  bin/rails silmu:freshness:status                 # 관측
  bin/rails silmu:freshness:no_auto_publish_check  # 본문 무변경 확인
  bin/rails silmu:p1:preflight                     # P1 backfill 사전점검 (쓰기 없음)
```

---

## 현재 상태 스냅샷 (2026-09-06)

| 항목 | 값 |
|---|---|
| 브랜치 | `fix/tool-accuracy-p1-0804` (P0·P1·P1.5 전부 **미커밋**) |
| 테스트 | 339 runs · 2,635 assertions · 0F · 0E · 14 skips |
| 마이그레이션 | P1 3개 + P1.5 3개 (dev 적용 · **운영 미적용**) |
| Authority 소스/문서/버전 | 1 / 8 / 8 (dev, 실제 법제처 데이터) |
| Impact 간선 | 154 (AuditCase 140 · Tool 14 · 도구 10종) |
| 검토 태스크 | 0 (실제 개정이 아직 없음 — 정상) |
| 구 `LegalComplianceJob` | **DO_NOT_ENABLE** · `recurring.yml` 무변경 |
| 새 잡 스케줄 | **아직 등록 안 함** (Stage 7) |
| 푸터 | 과장 문구 제거 완료 |
| P2 게이트 | **NOT_YET_OPEN** (운영 미배포) |

## 함정 (P0·P1·P1.5 에서 실제로 겪은 것)

1. **"0"을 그대로 믿지 말 것.** P0 에서 3개 중 2개가 양성대조 후 뒤집혔다. unchanged 0 은 changed 1 을 먼저 본 뒤에만 의미가 있다.
2. **HTTP 200 ≠ 유효.** law.go.kr 은 가짜 법령명에도 200 을 준다 — `<title>` 로 판별한다.
3. **렌더 0 ≠ 데이터 0.** P0 이 "원문 링크 0건"이라 했지만 `source` jsonb 에 URL 이 이미 있었다.
4. **필터 뒤만 세면 누출은 항상 0.** 경계 앞(at_risk)을 함께 세야 한다.
5. **로컬 dev DB 는 정본이 아니다.** 운영보다 최대 66건 stale.
6. **`db:rollback STEP=n` 은 "마지막 n개 적용된" 마이그레이션을 되돌린다.** 이번 세션에서 새 마이그레이션이 실패한 상태로 rollback 했더니 **직전 P1 마이그레이션까지 되돌아가 backfill 값이 소실**됐다. 롤백 전에 `db:migrate:status` 로 대상을 확인할 것.
7. **`strong_migrations` 는 `change_table bulk` 를 검사 못 하고, 사후 FK 추가·검증에 `disable_ddl_transaction!` 을 요구한다.** 우회하지 말 것.
8. **`disable_ddl_transaction!` 마이그레이션이 실패하면 부분 적용이 남는다.** 재실행 전 생성된 테이블을 확인·정리해야 한다.
9. **`t.references ... foreign_key: true` 는 인덱스를 이미 만든다.** 별도 `add_index` 하면 중복 오류.
10. **`dependent: :destroy` 는 선언 순서대로 실행된다.** FK 참조 방향과 반대면 위반이 난다.
11. **Tailwind 동적 클래스 금지.** `bg-#{x}-50` 은 JIT 가 스캔하지 못한다.
12. **ERB 블록(Ruby 해시 리터럴) 안에서는 `<%# %>` 를 못 쓴다.** `#` 주석을 쓴다.
