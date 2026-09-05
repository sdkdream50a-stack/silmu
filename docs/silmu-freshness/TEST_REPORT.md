# TEST_REPORT

## 1. 전체 — 비퇴화

| | P0 | P1 | **P1.5** |
|---|---:|---:|---:|
| runs | 242 | 288 | **339** |
| assertions | 2,173 | 2,482 | **2,635** |
| failures | 0 | 0 | **0** |
| errors | 0 | 0 | **0** |
| skips | 14 | 14 | **14** |

```
339 runs, 2635 assertions, 0 failures, 0 errors, 14 skips
```
신규 skip 0. `bin/rubocop` 신규 30파일 **0 offenses**.

## 2. 신규 테스트 (7파일 51 runs)

| 파일 | 커버 |
|---|---|
| `test/services/authority/change_detection_test.rb` | changed/unchanged/negative control · 정규화 오탐 |
| `test/services/authority/law_api_fetcher_test.rb` | 파서 positive/negative · `<law>` 노드 회귀 |
| `test/services/authority/source_registry_test.rb` | 주기 · tier · 실패 구분 · retry 상한 · bounded |
| `test/services/authority/impact_and_review_test.rb` | DIRECT/INDIRECT · 우선순위 · 멱등 · 상태 전이 · 검증 이벤트 |
| `test/models/authority_version_immutability_test.rb` | 불변성 |
| `test/models/authority_effective_date_test.rb` | 시행일 vs 공포일 · 미래 시행 |
| `test/integration/no_auto_publish_test.rb` | **§48 자동 수정 금지** |

오프라인 픽스처 사용(§45) — 단위 테스트는 외부 사이트에 의존하지 않는다.
픽스처는 2026-09-06 법제처 실제 응답이다(`test/support/authority_test_helper.rb`).

## 3. Positive Control (§43·§44)

**모든 "0" 주장에 대조가 있다.**

| 0-단정 | 대조 | 결과 |
|---|---|---|
| 변경 이벤트 0 (unchanged) | **changed control 을 먼저 실행해 1건 생성 확인** | 변경 8 → 재실행 0 |
| 자동 콘텐츠 수정 0 | 스냅샷이 실제 본문 변경을 잡는지 먼저 확인 (`POSITIVE CONTROL — 스냅샷이 실제 본문 변경을 잡아낸다`) | 잡아냄 → 이후 0 유의미 |
| 자동 수정 0 (정적) | 엔진 소스에 `Topic/Guide/AuditCase.update` 호출 검색 | 0건 |
| 미해석 링크 0 아님 | dry-run 예정 = 실제 생성 수치 일치 검증 | 154 = 154 |
| 공개 누출 0 (P1 계승) | at_risk 115건 측정 후 누출 0 | 유의미 |

### 라이브 대조 (외부 API)
| 항목 | 결과 |
|---|---|
| POSITIVE — 존재하는 법령 8종 fetch | 8/8 성공 · 시행일·공포일·MST 획득 |
| NEGATIVE — 가짜 법령명 | `PARSE_FAILED (totalCnt=0)` — 성공으로 오인 안 함 |
| UNCHANGED — 동일 문서 재수집 | 버전 +0 · 이벤트 +0 |
| CHANGED — 개정 fixture | 이벤트 1 · `EFFECTIVE_DATE_CHANGED` · level 3 · `제25조 modified` |

## 4. §47 상태 머신

```
CURRENT → (변경) → REVIEW_REQUIRED → (NO_IMPACT) → VERIFIED_AFTER_CHANGE   ✅
CURRENT → (변경·자동 NO_IMPACT) → CURRENT                                  ✅
REVIEW_REQUIRED → (IMPACT_CONFIRMED) → REVIEW_REQUIRED 유지                ✅
(SOURCE_UNAVAILABLE 은 콘텐츠를 삭제·비공개하지 않는다)                        ✅
```

## 5. §48 자동 수정 금지 — 가장 중요한 회귀

6개 테스트로 강제한다.
1. **POSITIVE CONTROL** — 스냅샷이 본문 변경을 실제로 감지
2. 전체 사이클(감지→분석→상태갱신→결정) 후 본문 무변경 · **변경이 실제로 감지됐는지도 함께 단언**
3. 잡 실행 후 본문 무변경
4. freshness 갱신이 화이트리스트 3컬럼만 건드림
5. 알 수 없는 상태 거부
6. **엔진 소스코드 정적 검사** — `Topic|Guide|AuditCase` + `.update/.destroy` 패턴 0건

2번이 중요하다. "아무 일도 안 일어나서 본문이 그대로"인 경우를 통과시키지 않는다.

## 6. 개발 중 테스트가 잡은 결함 3건

| 결함 | 발견 |
|---|---|
| `dependent: :destroy` 순서 — versions 가 change_events 보다 먼저 삭제되어 FK 위반 | 불변성 테스트 |
| 순환 FK — `documents.current_version_id` 때문에 문서 삭제 불가 | 불변성 테스트 |
| 도구 우선순위 보정이 clamp 하한에 막혀 무효 | 우선순위 테스트 |

그 외 스스로 발견해 고친 것:
- dry-run 이 중복 링크를 이중 계수 (155 vs 154) → 계획 키 집합으로 수정, 수치 일치 확인
- `IMPACT_CONFIRMED → VERIFIED_AFTER_CHANGE` 전이가 위험 → `REVIEW_REQUIRED` 유지로 수정

## 7. 미검증 (UNMEASURED)

- **운영 DB 에서의 엔진 동작** — dev 에서만 실행
- 조문 전문 diff (Level 3) 의 실 법령 적용 — 현재 canary 는 메타데이터만 수집하므로 fixture 로만 검증
- UNSTRUCTURED (PDF/HWP) fetcher — 미구현
- 장기 스케줄 안정성 — 1주기 이상 관측 필요
- 부하·동시성 — 단일 프로세스만 확인
