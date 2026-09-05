# SOURCE_FAILURE_ALERTING — 소스 장애 알림 (설계 정본)

> §8~§10. P1.55A 에서 설계만 남겼고, **P1.55B 에서 이 설계대로 구현됐다.**
> 구현 = `SOURCE_FAILURE_IMPLEMENTATION.md` · 검증 = `SOURCE_FAILURE_TESTS.md`.

## 1. 현재 상태 (이미 있는 것)

`authority_sources` 가 §9 요구 필드를 대부분 이미 갖고 있다.

| §9 요구 | 컬럼 | 상태 |
|---|---|:--:|
| source | `key` · `name` · `agency` | ✅ |
| document | `authority_documents.key` (FK) | ✅ |
| failure_type | `last_failure_kind` (`FETCH_FAILED` / `PARSE_FAILED` / `SOURCE_UNAVAILABLE`) | ✅ |
| failure_count | `failure_count` | ✅ |
| first_failed_at | — | 🔴 **없음** |
| last_failed_at | `last_checked_at` 로 근사 가능 | 🟡 부분 |
| last_success_at | `last_success_at` | ✅ |

§8 의 `CONSECUTIVE_FAILURE` 는 별도 종류가 아니라 `failure_count` 로 표현된다.

관측 경로:
```
bin/rails silmu:freshness:status      → 소스별 연속실패 + 종류 표시
/admin/authority_reviews              → 감시 대상 표에 연속실패 표시(붉은색)
```

## 2. 없는 것

```
사람에게 능동적으로 알리는 경로가 없다.
관리자가 화면을 보지 않으면 소스가 조용히 죽는다.
```

## 3. 기존 인프라 조사 (§9 — 새 SaaS 추가 금지)

재사용 후보:

| 자산 | 위치 | 적합성 |
|---|---|---|
| `LegalComplianceMailer` | `app/mailers/` | ❌ 구 unsafe 잡과 결합. 재사용 시 그 잡을 되살리는 인상을 준다 |
| `SeoReportJob` 메일 발송 | `app/jobs/seo_report_job.rb` | 🟡 메일 발송 패턴 참고 가능 |
| `ADMIN_EMAIL` 환경변수 | `config/deploy.yml` (`sdkdream50a@gmail.com`) | ✅ 이미 설정됨 |
| 서버 `backup.sh` 의 ALERT 로그 | `/root/backup.log` | ✅ 동작 확인됨(seteuk_preview 경고 실재) — 패턴 참고 |
| Sentry | `config/initializers/sentry.rb` | 🟡 존재 — 예외 보고용. 상태 알림에는 부적합할 수 있음 |

→ **새 알림 SaaS 를 추가할 필요 없다.** ActionMailer + `ADMIN_EMAIL` 로 충분하다.

## 4. §10 임계값 설계안

```
1~2회 연속 실패   → 내부 로그만 (현재 동작)
3회 이상          → operator warning (메일 1회, 중복 발송 억제)
5회 이상          → source degraded — 잡이 해당 소스를 건너뜀 (이미 구현됨)
```

`AuthorityFreshnessCheckJob::MAX_CONSECUTIVE_FAILURES = 5` 와 정합한다.
5회에서 이미 스킵하므로, **3회에서 알리지 않으면 사람이 알 기회가 없다.**

## 5. 구현안 (다음 세션)

```ruby
# 1) 마이그레이션 (additive)
add_column :authority_sources, :first_failed_at, :datetime
add_column :authority_sources, :alerted_at, :datetime      # 중복 발송 억제

# 2) AuthoritySource#record_failure! 확장
#    - first_failed_at 을 최초 실패 시에만 설정
#    - record_success! 에서 first_failed_at / alerted_at 초기화

# 3) AuthorityFreshnessCheckJob 안에서
#    failure_count == 3 이고 alerted_at 이 비어 있으면 메일 1회 + alerted_at 기록
```

주의:
- **알림 실패가 수집을 막으면 안 된다** — 메일 발송은 `rescue` 로 감싸고 로그만 남긴다
- 매 실행마다 보내지 않는다(`alerted_at` 억제)
- Freshness Engine 의 READ-ONLY 원칙과 충돌하지 않는다(콘텐츠를 건드리지 않음)

## 6. 상태

```
IMPLEMENTED = YES   (P1.55B · 2026-09-06)
DESIGN      = 위 5번 — 설계 변경 없이 그대로 구현됨
우선순위     = 스케줄러 등록보다 먼저 (사람이 화면을 안 보면 조용히 죽으므로) — 지켜짐
```

P1.55B 에서 설계안 대비 **추가된 판단 1건**:
5회(degraded)에서 잡이 소스를 건너뛰는 분기에서도 아직 안 알렸으면 알린다.
3·4회의 발송이 모두 실패한 채 5회에 도달하면 사람이 알 경로가 사라지기 때문이다.
