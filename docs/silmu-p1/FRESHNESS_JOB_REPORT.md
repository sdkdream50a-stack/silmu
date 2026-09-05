# FRESHNESS_JOB_REPORT — 신선도 모델 · LegalComplianceJob 판정

---

## 1. Freshness 모델 (§20) — 구현 완료

| 상태 | 조건 |
|---|---|
| `CURRENT` | `review_due_at >= 오늘` |
| `REVIEW_DUE` | 기한 경과, 유예 90일 이내 |
| `STALE_SUSPECTED` | 기한 경과 + 90일 초과 |
| `UNKNOWN` | 기한을 알 수 없음 |

- 신규 컬럼: `verified_at`(기존 `last_verified_at` 재사용) · `effective_at` · `review_due_at`
- `review_due_at` 이 비어 있어도 `last_verified_at + 180일` 로 **유도**한다. 그래야 backfill 이전 행도 스스로 낡음을 말한다.
- **화면이 자기고발한다**: `REVIEW_DUE`/`STALE_SUSPECTED` 가 되면 배지가 emerald → amber 로 바뀌고 아이콘이 `verified` → `update` 로, 문구에 `재검증 필요 — 공식 원문을 함께 확인하세요` 가 붙는다.

> P0 TR-05 의 본질은 "검증이 3개월 멈췄는데 화면은 계속 '검증 완료'라고 말한 것"이었다. 이제 멈추면 화면이 말한다.

회귀 테스트: `test/models/audit_case_authority_test.rb`
- `"재검증 기한이 지나면 스스로 강등된다"` (CURRENT/REVIEW_DUE/STALE_SUSPECTED/UNKNOWN 4상태)
- `"review_due_at 이 없으면 검토일로부터 유도한다"` (400일 미검증 → STALE_SUSPECTED)

---

## 2. LegalComplianceJob 판정 — **DO_NOT_ENABLE**

### 2.1 현재 상태
`config/recurring.yml`
```yaml
# 법령 정합성 자동 검증 (잠정 중단 2026-04-13)
# weekly_legal_check:
#   class: LegalComplianceJob
```

### 2.2 §22 6개 조건 판정

| 조건 | 판정 | 근거 |
|---|:--:|---|
| idempotent | ⚠️ 부분 | 리포트 생성은 반복 가능하나 실행마다 메일 발송 |
| **non-destructive** | ❌ **실패** | 아래 2.3 |
| reasonable external load | ❌ 실패 | `verify_all` 이 발행 토픽 전체 × 검증 대상 필드마다 Anthropic API 호출. 또한 job 안에서 `Open3.capture3("bundle exec rake legal:ci_check")` 로 **Rails 를 통째로 재부팅**한다 |
| **failure-safe** | ❌ **실패** | `rescue JSON::ParserError` 경로가 실패 시 오히려 `run_ai_verification([])` 로 **전체 AI 검증을 실행**한다. rake 출력 형식이 바뀌면 매 실행마다 유료 호출 + DB 자동 수정이 돈다 |
| observable | ⚠️ 부분 | 로그·메일뿐. `ADMIN_EMAIL` 미설정이면 아무 기록도 남지 않는다. 결과 원장 없음 |
| tested | ❌ 실패 | `LegalComplianceJob` 관련 테스트 **0건** (`grep -rln 'LegalComplianceJob' test/` = 없음) |

### 2.3 결정적 사유 — AI 출력이 발행 콘텐츠를 직접 덮어쓴다

호출 경로:
```
LegalComplianceJob#run_basic_check
  └─ (중대 오류 발견 OR JSON 파싱 실패) → run_ai_verification
       └─ RegulationVerifier#verify_all
            └─ Topic.published.find_each → verify_topic → verify_field
                 └─ if response[:needs_update] && response[:corrections].present?
                      └─ apply_corrections
```

`app/services/regulation_verifier.rb:382`
```ruby
if updated_content != content
  topic.update!(field => updated_content)   # ← 발행 토픽 본문을 AI 출력으로 덮어쓴다
  log "  💾 #{field} 저장 완료"
end
```

- **dry-run 플래그 없음** — `grep -nE 'dry|DRY|guard|approve|confirm'` 결과 `ENV["ANTHROPIC_API_KEY"]` 단 1건
- **사람 승인 게이트 없음**
- **diff 검토·롤백 기록 없음** (`content_migrations` 원장을 쓰지 않는다)

즉 cron 을 되살리면 **주 1회 AI 가 발행 중인 법령 해설 본문을 무단 수정**한다.
같은 파일에 `GoogleSitemapPingJob` 무한루프 사건(2026-05-18) 전례가 있다. 그때는 트래픽이 샜고, 이번엔 콘텐츠가 샌다.

### 2.4 판정
```
DO_NOT_ENABLE
```
주석을 해제하지 않았다. `config/recurring.yml` 은 **무변경**이다.

---

## 3. 활성화를 위한 개선안 (P2)

조건을 만족시키려면 순서대로:

| # | 작업 | §22 대응 |
|---|---|---|
| 1 | `RegulationVerifier` 에 `dry_run:` 옵션 추가 — 기본값 `true`. `apply_corrections` 는 `dry_run == false` 일 때만 `update!` | non-destructive |
| 2 | 제안 수정을 `content_migrations` 또는 신규 검토 큐에 적재하고 **사람 승인 후** 적용 | non-destructive |
| 3 | JSON 파싱 실패 시 AI 로 에스컬레이션하지 않고 **실패로 종료**(알림만) | failure-safe |
| 4 | `Open3` 로 rake 재부팅하지 않고 lint 로직을 직접 호출 | external load |
| 5 | 실행당 API 호출 상한·비용 상한 도입 | external load |
| 6 | 실행 결과를 DB 원장에 기록(성공/실패/변경 제안 수) | observable |
| 7 | 테스트 추가 — dry-run 이 쓰지 않음 / 파싱 실패가 AI 를 부르지 않음 / 상한 초과 시 중단 | tested |
| 8 | 그 다음에야 `recurring.yml` 주석 해제 | — |

**1·3번만 해도 위험의 대부분이 사라진다.**

---

## 4. 함께 처리해야 할 사실 오류

전역 푸터(`layouts/application.html.erb:490`):
> 실무.kr은 본 콘텐츠의 정확성을 높이기 위해 법제처 OPEN API 기반 자동 검증 및 5단계 게이트를 **운영하고 있으나**…

자동 검증 cron 은 2026-04-13 이후 꺼져 있다. 이 문장은 현재 사실과 다르다.
법적 고지 문구이므로 임의 수정하지 않았다. **문구 수정 또는 cron 복원 중 하나가 필요하다.**
