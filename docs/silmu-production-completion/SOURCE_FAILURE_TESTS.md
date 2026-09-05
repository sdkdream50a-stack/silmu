# SOURCE_FAILURE_TESTS — 소스 장애 알림 검증

> P1.55B §32~§34·§39~§41. 파일 = `test/services/authority/source_failure_alert_test.rb` (9 tests · 49 assertions).

## 1. 실패 주입 방법 (외부 네트워크 의존 없음)

`fetch_strategy: "manual"` 은 `Authority::ChangeDetector` 가 지원하지 않는 전략이라
**결정적으로 `PARSE_FAILED`** 를 만든다. 잡 1회 실행 = 실패 1회.

```ruby
@source   = create_source(fetch_strategy: "manual", name: "테스트 법령 출처")
@document = create_document(source: @source)
def run_check = AuthorityFreshnessCheckJob.new.perform(document_ids: [ @document.id ])
```

메일 장애는 **배달 계층에서** 재현한다(몽키패치·목 gem 없이 — 저장소 하우스 스타일과 동일한 명시적 주입).

```ruby
class FailingDelivery
  def deliver!(_mail) = raise(MailServerDown, "메일 서버 다운")
end
ActionMailer::Base.add_delivery_method :failing_for_test, FailingDelivery
```

메일러 렌더링까지 실제로 수행한 뒤 발송에서 실패하므로 운영 장애에 가깝다.

## 2. §32 임계값 대조 — 실측 결과

| 조건 | 기대 | 실측 |
|---|:--:|:--:|
| 실패 1회 | alert 0 | **0** ✅ |
| 실패 2회 | alert 0 | **0** ✅ |
| **실패 3회** | **alert 1** | **1** ✅ |
| 같은 episode 4회째 | 추가 0 | **0** ✅ |
| 복구(`record_success!`) | episode 리셋 | `failure_count=0` · `first_failed_at=nil` · `alerted_at=nil` ✅ |
| 복구 후 새 3회 | new alert 1 | **1** (누적 2) ✅ |
| degraded(5회) 스킵 소스 | alert 1 | **1** ✅ |

## 3. §33 zero-claim gate

`alert 0` 을 주장하는 단언과 `alert 1` 양성 대조를 **같은 테스트 안에서 순서대로** 실행한다.

```ruby
run_check; assert_equal 0, alert_count   # 1회
run_check; assert_equal 0, alert_count   # 2회
run_check; assert_equal 1, alert_count   # 3회 ← 양성 대조
```

검출기(메일 발송 경로)가 죽어 있으면 세 번째 단언이 실패하므로,
앞의 두 `0` 은 "기능이 없어서 0" 이 아니라 "임계값에 미달해서 0" 임이 증명된다.

## 4. §34 수집 독립성 (알림 실패 격리)

메일 서버가 죽은 상태에서 3회째 실패를 실행:

```
report[:checked]      = 1     ← 수집이 중단되지 않았다
report[:failed]       = 1
report[:alerts_sent]  = 0
source.failure_count  = 3     ← 수집 상태는 정상 기록됐다
deliveries            = 0
source.alerted_at     = nil   ← 실패했으므로 완료로 찍지 않는다
```

그리고 메일 경로가 복구되면 **다음 주기에 재시도되어 1건 발송**됨을 별도 테스트로 확인했다.

## 5. §39 콘텐츠 무변경 — 탐지기 양성 대조 포함

"본문이 안 바뀌었다" 를 주장하기 전에 **탐지기가 변경을 잡는다는 것부터** 증명한다.

```ruby
before = content_body_snapshot
refute_empty before["Topic"]                     # 스냅샷이 비면 무변경 주장은 무의미

probe.update_columns(summary: "…·MUTATION_PROBE")
assert_not_equal before, content_body_snapshot   # ← 양성 대조: 탐지기가 살아 있다
probe.update_columns(summary: original)
assert_equal before, content_body_snapshot       # 복원 확인

3.times { run_check }
assert_equal 1, alert_count                      # ← 양성 대조: 알림 경로가 실행됐다
assert_equal before, content_body_snapshot       # 그러고도 본문 무변경
```

테스트 환경 콘텐츠 실재 확인: `Topic 6 · Guide 2 · AuditCase 3` (fixture) — 공허한 비교가 아니다.

## 6. 뮤테이션 검사 — green 이 증거인지 확인

테스트가 실제로 실패할 수 있는지 7개 결함을 주입해 확인했다. **7/7 KILLED.**

| # | 주입한 결함 | 결과 |
|---|---|:--:|
| M1 | `ALERT_THRESHOLD` 3 → 99 | 6 failures / 1 error — KILLED |
| M2 | 중복 억제 제거 (`alerted_at` 무시) | 1 failure — KILLED |
| M3 | `first_failed_at` 을 매 실패마다 덮어씀 | 1 failure — KILLED |
| M4 | `record_success!` 가 episode 를 닫지 않음 | 1 failure — KILLED |
| M5 | 알림 실패 격리 `rescue` 제거 | 2 errors — KILLED |
| M6 | degraded 분기의 알림 제거 | 1 failure — KILLED |
| M7 | 실패 분기의 알림 제거 (알림 경로 사망) | 5 failures / 1 error — KILLED |

주입 해제 후 소스 파일이 원본과 **byte-identical** 임을 `diff` 로 확인했고, 기준선도 green 으로 복귀했다.

`SURVIVED=0` 은 내가 고른 7개 축에 한한 결과다 — 다른 축의 결함까지 없다는 뜻은 아니다.

## 7. 전체 스위트 (§40)

```
P1.55A 기준선 : 353 runs · 2,682 assertions · 0 failures · 0 errors · 14 skips
P1.55B 이후   : 362 runs · 2,727 assertions · 0 failures · 0 errors · 14 skips
```

```
신규 테스트 = +9 · 신규 assertion = +45
신규 skip   = 0
회귀        = 0
```

## 8. Lint (§42)

```
bundle exec rubocop <변경 파일 6개>
→ 6 files inspected, no offenses detected
```
