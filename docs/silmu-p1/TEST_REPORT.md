# TEST_REPORT

## 1. 전체 결과 — 비퇴화 확인

| | P0 baseline | P1 이후 | 변화 |
|---|---:|---:|---:|
| runs | 242 | **288** | +46 |
| assertions | 2,173 | **2,482** | +309 |
| failures | 0 | **0** | — |
| errors | 0 | **0** | — |
| skips | 14 | **14** | — |

```
288 runs, 2482 assertions, 0 failures, 0 errors, 14 skips
```
기존 skip 14건은 P0 baseline 과 동일한 선재 상태다(신규 skip 0).

### Lint
```
bin/rubocop <신규 30파일>  →  30 files inspected, no offenses detected
```
(초기 6건 `Layout/SpaceInsideArrayLiteralBrackets` 는 `-a` 로 교정 후 테스트 재실행하여 회귀 없음 확인)

### Build / Assets
`bin/rails test` 실행 시 esbuild + tailwind 빌드가 함께 수행되며 오류 없음.
Tailwind 동적 클래스 문제를 예방하기 위해 배지의 색상 클래스를 **전부 리터럴**로 작성했다(`bg-#{accent}-50` 금지) — JIT 가 스캔하지 못해 스타일이 사라지는 결함을 사전 차단.

---

## 2. 신규 테스트 (7파일 46 runs)

| 파일 | 커버 |
|---|---|
| `test/services/internal_metadata_filter_test.rb` | 내부/공개 분리 · positive 7 / negative 4 / ambiguous 3 |
| `test/services/legal_reference_resolver_test.rb` | KNOWN resolve / UNKNOWN 금지 / AMBIGUOUS 금지 / 상속 / 괄호 / URL 규약 |
| `test/services/authority_classifier_test.rb` | provenance·agency confidence gate |
| `test/services/tool_trust_test.rb` | 기준일 파일 연동 · 미등록 도구 근거 미생성 · 면책 전량 |
| `test/models/audit_case_authority_test.rb` | 검증 범위 분리 · freshness 4상태 · §10 승격 금지 · agency 표시 게이트 |
| `test/models/authority_schema_test.rb` | ADDITIVE 보존 · nullable · 배열 컬럼 |
| `test/integration/public_metadata_leak_test.rb` | 렌더 경계 회귀 + positive control + 과잉차단 방지 |

---

## 3. Positive Control 을 갖춘 테스트 (§17·§36)

P0 에서 0-단정 3개 중 2개가 양성대조 후 뒤집혔다. 그래서 이번에는 **"검출기가 있는 것을 세는가"를 먼저 증명**한다.

| 대상 | 양성 대조 | 결과 |
|---|---|---|
| 내부 메타데이터 필터 | 실제 누출됐던 문자열 7종 투입 | 7/7 차단 |
| 필터 과잉차단 | 정상 출처 4종 투입 | 4/4 통과 |
| 누출 회귀 테스트 | 경계를 우회한 문자열이 검출되는지 확인 | 검출됨 |
| 누출 테스트 유효성 | 정상 출처가 **표시되는지** 확인 | 표시됨 (전부 차단해도 통과하는 무의미 테스트 방지) |
| 법령 URL 해석기 | 생성 가능한 URL 41개 전수 조회 | 41/41 실제 법령 도달 |
| 법령 URL 음성 대조 | 가짜 법령명 조회 | HTTP **200** 이지만 `<title>=오류페이지` → **200 은 증거가 아님을 확인** |
| `leak_scan` rake | canary 문자열로 검출기 자체 검사 | 실패 시 `abort` |
| `leak_scan` 유의미성 | at_risk 115건 측정 | 0이 아니므로 "누출 0"이 의미를 가짐 |

---

## 4. 실물 확인 (dev 서버 렌더, 실제 데이터)

| 페이지 | 확인 |
|---|---|
| `/audit-cases/goe-2021-management-allowance-mispayment` | `🟢 실제 감사결과` 배너 · `공식 원문 확인` 배지 · `경기도교육청 감사관실 · 감사사례집 · 2021 p.122 [공식 원문 보기]` |
| `/audit-cases/private-contract-over-limit` | `📘 실무.kr 재구성 사례` 배너 + `⚠️ 본문의 기관명·인물·금액은 예시` · `법령 근거 검증` 배지(범위 문구 포함) · 법령 링크 · `적용 대상 지방자치단체` |
| `/tools/contract-method` | 적용기준 · 기준일 2026-03-28 · 계산근거 링크 2 · 면책 |
| `/tools/pdf` | 면책만 (근거 미등록 도구는 근거를 지어내지 않음) |

전 페이지에서 `Phase A` `batch 0` `commits` `eed3ceb` `lawId` `backlog` `dashboard` `운영 정합` **검출 0**.
(`5단계` 는 전역 푸터의 정상 문구로 잔존 — `FRESHNESS_JOB_REPORT.md` §4 참조)

---

## 5. 마이그레이션 테스트

```
bin/rails db:rollback STEP=3   → 3개 reverted
bin/rails db:migrate           → 3개 migrated
```
`test/models/authority_schema_test.rb` 가 기존 컬럼 보존(16개)·nullable·배열 타입을 강제한다.

---

## 6. 미검증 (UNMEASURED)

- **운영 DB 에서의 backfill 결과** — dev(191) 기준만 측정. 운영 257건은 재실행 필요
- 조문 단위 딥링크 정확도 — 법령 단위까지만 검증
- 시각적 회귀(스크린샷 비교) — 텍스트 렌더만 확인
- `exam.silmu.kr` 서브도메인 — 이번 범위 밖
