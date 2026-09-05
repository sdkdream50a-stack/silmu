# SCHEDULER_ACTIVATION — 스케줄러 판정

> §21 — 수동 2주기가 안전하게 끝난 이후에만 scheduler 를 **검토**한다.

## 1. 현재 상태

```
SCHEDULER = DISABLED
config/recurring.yml — AuthorityFreshnessCheckJob 미등록
config/recurring.yml — weekly_legal_check(구 LegalComplianceJob) 주석 그대로 (변경 없음)
```

## 2. 판정 = NOT_ENABLED (이번 세션)

§21 은 "수동 2주기 완료 후 **검토**"라고 했지 "자동 등록"이라 하지 않았다.
아래 이유로 이번 세션에서는 등록하지 않는다.

| 이유 | 설명 |
|---|---|
| 관측 기간 부족 | RUN 1·2 는 **같은 날 1분 간격**이다. 24시간 주기의 자연 실행을 아직 한 번도 보지 못했다 |
| 실제 개정 미관측 | 감지→검토→종결 사슬이 운영에서 완주된 적이 없다(§39 는 이를 기다리지 말라고 했으나, 스케줄러 자동화는 별개 판단이다) |
| 사용자 승인 범위 | 이번 세션 승인은 "Stage 4까지 (canary 2주기 완주)" 였고 **스케줄러 등록은 별도 승인** 대상으로 명시되었다 |

## 3. §22 안전 요건 — 코드 수준 확인 완료

| 요건 | 구현 | 검증 |
|---|---|---|
| bounded batch | `MAX_DOCUMENTS_PER_RUN = 20` | 회귀 테스트 `잡은 실행당 문서 수가 제한된다` |
| rate limit | 요청 간 `1.0s` (test 환경 제외) | RUN 1 실측 8건 12초 |
| retry | `discard_on StandardError` — 잡 전체 재시도 안 함, 문서 단위로 실패 흡수 | — |
| failure isolation | 소스별 `failure_count`, 5회 초과 시 skip | 회귀 테스트 `연속 실패가 상한을 넘으면 …` |
| observability | 구조화 JSON 로그 + `silmu:freshness:status` + Admin UI | 운영 확인 |
| duplicate run prevention | `due?` 주기 필터 + hash 비교로 동일 내용 시 version 미생성 | 운영에서 3회 실행 → version 8 유지 |

**동시 실행 시 중복 version/event 미생성**은 hash 비교로 보장된다.
다만 **동시성 락은 없다** — 두 프로세스가 정확히 같은 순간에 fetch 하면 이론상 두 version 이 생길 수 있다.
Solid Queue 단일 워커 구성(`SOLID_QUEUE_IN_PUMA=true`, `WEB_CONCURRENCY=2`)에서는 현실적 위험이 낮으나,
스케줄러 등록 시 이 점을 다시 판단해야 한다.

## 4. 등록 시 사용할 설정 (승인 후)

```yaml
# config/recurring.yml
daily_authority_freshness:
  class: AuthorityFreshnessCheckJob
  schedule: "0 7 * * *"     # 매일 07:00 — §21 기본 후보 24h
```
- 초기 빈도를 과도하게 높이지 않는다
- 구 `LegalComplianceJob` 주석은 **그대로 둔다**

## 5. 등록 전 충족 조건

- [ ] 24시간 자연 주기 실행 1회 이상 관측 (수동이 아닌 스케줄 발화)
- [ ] `silmu:freshness:status` 에서 `failed=0` 유지
- [ ] `no_auto_publish_check` PASS
- [ ] 사용자 명시 승인

## 6. 그때까지의 운용

수동 실행으로 충분하다.
```bash
bin/kamal app exec --reuse 'bin/rails silmu:freshness:check'
bin/kamal app exec --reuse 'bin/rails silmu:freshness:status'
```
