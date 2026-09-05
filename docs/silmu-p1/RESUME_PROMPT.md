# RESUME_PROMPT — 다음 세션 시작 프롬프트

```
silmu.kr P2 를 시작한다.

프로젝트: /Users/seong/project/silmu  (Rails 8.1 + PostgreSQL, Kamal → 141.164.53.97)
선행: docs/silmu-audit/ (P0 감사) · docs/silmu-p1/ (P1 Authority Trust Layer, 구현 완료)

시작 전 읽을 것:
  1. docs/silmu-p1/P1_IMPLEMENTATION_REPORT.md   ← 무엇이 만들어졌나
  2. docs/silmu-p1/P2_RECOMMENDATION.md          ← 무엇을 이 순서로
  3. docs/silmu-p1/MIGRATION_PLAN.md             ← 운영 적용 절차
  4. docs/silmu-p1/FRESHNESS_JOB_REPORT.md       ← LegalComplianceJob DO_NOT_ENABLE 사유

이번 세션 목표 (P2_RECOMMENDATION 1~4번):
  ① 운영 backfill 실행 — MIGRATION_PLAN §2 순서대로. dry-run CSV 를 먼저 검토하고
     confidence=MEDIUM 행과 "ACTUAL_AUDIT 인데 source_url 빈 행"(있으면 안 됨)을 확인한다.
  ② LegalComplianceJob 안전화 — RegulationVerifier 에 dry_run: 기본 true 추가,
     JSON 파싱 실패 시 AI 에스컬레이션 제거. 그 전까지 recurring.yml 주석 해제 금지.
  ③ 도구 기준값 2종 갱신 (contract_thresholds 2026-03-28 / legal_standards 2026-02-04)
  ④ AI 근거 주입 배선 — topics/show 사이드바에 ai_assistant_path(topic_slug: @topic.slug) 링크 1줄
     + 응답에 grounded 여부 표시. 벡터 DB·RAG 구축 금지.

제약:
  - 스키마 변경은 additive·nullable·reversible 만. strong_migrations 우회 금지.
  - 운영 DB destructive 변경 금지. backfill 은 반드시 dry-run 먼저.
  - MEDIUM/LOW confidence 자동 적용 금지 (부정확한 metadata 는 빈 metadata 보다 위험).
  - 확실히 식별되지 않는 법령에 URL 생성 금지 (§15).
  - 일반행정 콘텐츠 대량 생성 금지 — AGENCY_RULE_MODEL 상속 구현 이후.
  - Hermes / Revenue OS / 다른 lane 무수정.

검증:
  bin/rails test               # baseline 288 runs / 2,482 assertions / 0F / 0E / 14 skips 대비 비퇴화
  bin/rubocop <변경 파일>
  bin/rails silmu:p1:leak_scan # positive control OK + 실제 누출 0 + at_risk > 0
```

---

## 현재 상태 스냅샷 (2026-09-05)

| 항목 | 값 |
|---|---|
| 브랜치 | `fix/tool-accuracy-p1-0804` (P1 변경 **미커밋**) |
| 테스트 | 288 runs · 2,482 assertions · 0 failures · 0 errors · 14 skips |
| 마이그레이션 | 3개 (dev 적용 완료 · **운영 미적용**) |
| backfill | dev 만 적용 (audit_cases 191 / topics 92 / guides 103) |
| 운영 규모 | audit_cases 257 · topics 114 · guides 107 |
| `LegalComplianceJob` | **DO_NOT_ENABLE** — `recurring.yml` 무변경 |
| AI 배선 | **NOT_CHANGED** — 진입점 부재(버그 아님), 1줄 변경안 문서화됨 |

## 함정 (P0·P1 에서 실제로 겪은 것)

1. **"0건"을 그대로 믿지 말 것.** P0 에서 3개 중 2개가 양성대조 후 뒤집혔다. `leak_scan` 은 그래서 at_risk 를 함께 센다.
2. **HTTP 200 은 링크 유효성의 증거가 아니다.** law.go.kr 은 가짜 법령명에도 200 을 준다 — `<title>` 로 판별한다.
3. **로컬 dev DB 는 정본이 아니다.** 운영보다 최대 66건 stale.
4. **Tailwind 동적 클래스 금지.** `bg-#{x}-50` 은 JIT 가 스캔하지 못해 CSS 가 생성되지 않는다.
5. **ERB 블록 안에서는 `<%# %>` 를 쓸 수 없다.** JSON-LD 같은 Ruby 해시 리터럴 안에서는 `#` 주석을 쓴다(테스트가 이를 잡았다).
6. **`strong_migrations` 는 `change_table bulk` 를 검사하지 못한다.** 우회(`safety_assured`)하지 말고 개별 `add_column` 으로 쓴다.
7. **`grep` 으로 컨트롤러에 코드 삽입 시 액션을 확인할 것.** 첫 매치가 `show` 가 아닐 수 있다(실제로 `download_hwp` 에 잘못 들어갔다).
