# SOURCE_FAILURE_IMPLEMENTATION — 소스 장애 알림 구현

> P1.55B §22~§31·§35. 설계 정본 = `SOURCE_FAILURE_ALERTING.md`.
> 목적: **공식 출처가 조용히 죽는 것을 막는다.** 관리자가 화면을 보지 않아도 알 수 있어야 한다.

## 1. 왜 스케줄러보다 먼저인가

```
AuthorityFreshnessCheckJob::MAX_CONSECUTIVE_FAILURES = 5
→ 5회 연속 실패하면 잡이 그 소스를 건너뛴다(degraded).
→ 알림이 없으면 소스는 "조용히" 감시 대상에서 빠진다.
```

스케줄러를 먼저 켜면 사람이 모르는 채로 현행성 감시가 정지할 수 있다.
그래서 이번 세션은 **알림 인프라까지만** 만들고 스케줄러는 켜지 않았다(§31·§48).

## 2. 기존 자산 재사용 (§23·§28 — 새 모델·새 SaaS 금지)

`authority_sources` 가 이미 갖고 있어 **재사용한 것**:

```
key · name · agency · official_url
failure_count            연속 실패 횟수
last_failure_kind        FETCH_FAILED / PARSE_FAILED / SOURCE_UNAVAILABLE
last_failure_message
last_checked_at · last_success_at
```

알림 목적지도 기존 것을 그대로 썼다:

```
ENV["ADMIN_EMAIL"]  = sdkdream50a@gmail.com   (config/deploy.yml 에 이미 설정됨)
ApplicationMailer                              (기존 레이아웃)
```

새 외부 SaaS·새 모델·새 대시보드를 만들지 않았다.

## 3. 추가한 것 — additive nullable 2개뿐 (§24)

`db/migrate/20260906065000_add_failure_alert_state_to_authority_sources.rb`

```ruby
add_column :authority_sources, :first_failed_at, :datetime   # 장애 episode 시작
add_column :authority_sources, :alerted_at,      :datetime   # 중복 발송 억제
```

`ADDITIVE / NULLABLE / REVERSIBLE / 인덱스 없음 / 백필 없음` — strong_migrations 통과.
동등 개념이 기존 스키마에 없었기 때문에만 추가했다(§24).

## 4. `record_failure!` / `record_success!` 계약 (§25·§27)

`app/models/authority_source.rb`

```ruby
ALERT_THRESHOLD = 3

def record_success!(at: Time.current)
  update!(last_checked_at: at, last_success_at: at, failure_count: 0,
          last_failure_kind: nil, last_failure_message: nil,
          first_failed_at: nil, alerted_at: nil)      # ← episode 를 닫는다
end

def record_failure!(kind, message, at: Time.current)
  update!(last_checked_at: at, failure_count: failure_count + 1,
          last_failure_kind: kind, last_failure_message: message.to_s.truncate(1000),
          first_failed_at: first_failed_at || at)     # ← 최초 실패에만 찍는다
end

def alert_due? = failure_count >= ALERT_THRESHOLD && alerted_at.nil?
def mark_alerted!(at: Time.current) = update!(alerted_at: at)
```

`first_failed_at` 은 후속 실패로 **옮겨지지 않는다** — episode 지속 시간을 재기 위해서다.
`record_success!` 가 `alerted_at` 을 지우므로, **복구 후 새 장애에서는 다시 알린다**(§27).

기존 semantics(실패 카운트·종류 구분·성공 시 리셋)는 그대로 유지했다.

## 5. 임계값 (§26 — 설계 정본과 일치)

```
1~2회 연속 실패  →  로그만
3회             →  운영자 메일 1회 (ALERT_THRESHOLD, episode 당 1회)
5회 이상        →  degraded — 잡이 소스를 건너뜀 (기존 동작)
```

## 6. 발동 지점 (§29 — 수집을 막지 않는다)

`app/jobs/authority_freshness_check_job.rb`

```ruby
def alert_operator(source)
  return false unless source.alert_due?

  AuthoritySourceMailer.failure_alert(source).deliver_now
  source.mark_alerted!
  Rails.logger.warn "[AuthorityFreshness] 소스 장애 알림 발송: …"
  true
rescue StandardError => e
  Rails.logger.error "[AuthorityFreshness] 알림 발송 실패(수집은 계속): #{e.class} #{e.message}"
  false
end
```

두 곳에서 호출한다.

| 지점 | 이유 |
|---|---|
| `when :failed` 분기 | 정상 경로 — 3회째 실패에서 알린다 |
| `failure_count >= 5` 스킵 분기 | **degraded 상태에서도 아직 안 알렸으면 알린다.** 여기서 막으면 사람이 알 경로가 없다 |

발송에 실패하면 `alerted_at` 을 **찍지 않는다** → 다음 주기에 자동 재시도된다.
잡 리포트에 `alerts_sent` 가 추가됐다(observable).

## 7. 실패 종류 (§30)

기존 `FAILURE_KINDS = %w[FETCH_FAILED PARSE_FAILED SOURCE_UNAVAILABLE]` 를 그대로 쓴다.
`CONSECUTIVE_FAILURE` 는 별도 enum 이 아니라 `failure_count` 로 표현된다 — enum 을 늘리지 않았다.

## 8. 관측 (§35)

`bin/rails silmu:freshness:status` 에 장애 episode 2줄을 추가했다(장애가 있을 때만 출력).

```
  law_go_kr            tier1 STRUCTURED_API   enabled=true 주기=168h
    마지막 검사=2026-09-06 01:20 마지막 성공=2026-09-06 01:20 연속실패=0
    장애시작=2026-09-06 03:11 알림=2026-09-06 05:40 임계값=3회      ← 추가
```

`/admin/authority_reviews` 는 이미 연속 실패를 붉은색으로 표시하고 있어 그대로 뒀다.
새 대시보드는 만들지 않았다.

## 9. 안전 계약 유지

```
콘텐츠 자동 수정          없음 — 알림은 상태만 전달한다
LegalComplianceJob        건드리지 않음 (config/recurring.yml 주석 그대로)
LegalComplianceMailer     재사용하지 않음 (구 unsafe 잡과의 결합 회피)
스케줄러                  여전히 OFF — recurring.yml 에 AuthorityFreshnessCheckJob 없음
```

## 10. 변경 파일

```
db/migrate/20260906065000_add_failure_alert_state_to_authority_sources.rb   신규
db/schema.rb                                                               컬럼 2개
app/models/authority_source.rb                                             수정
app/jobs/authority_freshness_check_job.rb                                  수정
app/mailers/authority_source_mailer.rb                                     신규
app/views/authority_source_mailer/failure_alert.html.erb                   신규
lib/tasks/silmu_freshness.rake                                             관측 2줄
test/services/authority/source_failure_alert_test.rb                       신규
```
