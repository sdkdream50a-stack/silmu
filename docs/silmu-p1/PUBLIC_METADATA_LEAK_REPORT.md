# PUBLIC_METADATA_LEAK_REPORT — 내부 메타데이터 분리

> P0 최대 신뢰 결함(TR-01): 공개 페이지 `<cite>` 안에 git 커밋 해시가 "검토 출처"로 표시되고 있었다.

---

## 1. 무엇이 새고 있었나 (P0 채증)

```
Phase A~E batch 01~03 (commits eed3ceb..12dff5d) — 법제처 OPEN API 5단계 게이트 검증
법제처 OPEN API mcp spot check + 부정확 정정 (lawId 001234·…, 2026-05-19 batch 02)
sen_2025_audit_disclosure_dashboard
GOE 2021 경기교육청 감사보고서 (조문번호 명시 없음 — 차후 정밀화 backlog)
```

경로: `audit_cases/show.html.erb` → `render 'shared/verification_badge', source: @audit_case.verification_source`
즉 **DB 자유 문자열이 뷰로 직결**되어 있었다.

---

## 2. 조치 (§11·§12·§13)

### 2.1 두 층 분리
| 층 | 필드 | 공개 |
|---|---|---|
| INTERNAL_METADATA | `verification_note`(신규) — batch·commit·lawId·parser_version·backfill·import_job | ❌ 절대 렌더 금지 |
| PUBLIC_AUTHORITY_METADATA | `source_agency` `source_title` `source_url` `source_year` `source_page` `legal_basis` `verification_status` `effective_at` | ✅ |

**DB 에서 지우지 않았다.** 기존 `verification_source` 는 그대로 두고 `verification_note` 로 **복사**했다(무손실). 관리자·감사 추적에는 필요하다.

### 2.2 단일 경계
모든 공개 권위 정보는 `AuthorityPresenter` 를 통과하고, 그 안에서 `InternalMetadataFilter` 가 차단한다.
차단 패턴 18종: `commit(s)` · 커밋 범위 해시(`[0-9a-f]{7,40}\.\.[0-9a-f]{7,40}`) · `batch\s*\d*` · `lawId` · `mcp` · `spot check` · `OPEN API` · `dashboard` · `Phase [A-Z0-9]` · `backlog` · `seed_source` · `parser_version` · `backfill` · `import_job` · `internal` · `<name>_<year>_<...>` 형태 · `차후 정밀화` · `운영 정합`

---

## 3. 측정 — "0건"을 그대로 믿지 않는다 (§36)

`silmu:p1:leak_scan` 은 **presenter 출력만 보면 구조적으로 항상 0** 이 나온다(필터를 통과한 값이므로).
그런 0 은 증거가 아니다. 그래서 셋을 함께 측정한다.

```
$ bin/rails silmu:p1:leak_scan
positive control: OK (알려진 누출 문자열을 차단함)
leak_scan: 검사 386건 · 경계가 막아낸 at_risk 115건 · 실제 누출 0건
```

| 측정 | 값 | 의미 |
|---|---:|---|
| ① positive control | PASS | 검출기가 알려진 누출 문자열을 실제로 잡는다. 실패하면 태스크가 `abort` 한다 |
| ② at_risk | **115** | 경계가 없었다면 누출됐을 레코드 수 = 경계의 실효 가치 |
| ③ leaking | **0** | presenter 를 통과해 실제로 새는 레코드 |

②가 115라서 ③의 0이 의미를 갖는다. 만약 ②도 0이었다면 "검사할 게 없어서 0"이었을 것이다.

---

## 4. 회귀 테스트 (§33)

`test/integration/public_metadata_leak_test.rb` — 문자열 하드코딩이 아니라 **실제 렌더 경계와 HTTP 응답 본문**을 검사한다.

| 테스트 | 내용 |
|---|---|
| presenter 차단 | 누출 문자열을 가진 레코드에서 `public_source_label` 이 `nil` |
| 공개 응답 검사 | `GET /audit-cases/:slug` 응답 본문에 `Phase`·`batch`·`commit`·`eed3ceb`·`lawId`·`backlog`·`internal`·`mcp`·`dashboard` 부재 |
| `verification_note` | 어떤 공개 응답에도 등장하지 않음 |
| **POSITIVE CONTROL** | 경계를 우회한 문자열을 만들면 검출 로직이 **실제로 걸러낸다**는 것을 증명 — 이게 없으면 위 테스트들의 통과는 무의미 |
| 과잉 차단 회귀 방지 | 정상 출처(`경기도교육청 감사관실` + 원문 URL)는 공개 페이지에 **표시된다** |
| 재구성 고지 | 재구성 사례 페이지에 "실제 감사결과 원문을 그대로 재현한 것이 아니라" 문구가 **나타난다** |

마지막 두 개가 중요하다 — 전부 차단해 버려도 누출 테스트는 통과하기 때문이다.

---

## 5. 실물 확인 (dev 서버 렌더)

| 페이지 | 확인 결과 |
|---|---|
| `/audit-cases/goe-2021-management-allowance-mispayment` | `출처: 경기도교육청 감사관실 · 감사사례집 · 2021 p.122 [공식 원문 보기]` — 커밋 해시 없음 |
| `/audit-cases/private-contract-over-limit` | `📘 실무.kr 재구성 사례` 배너 + `법령 근거 검증` 배지 — `운영 정합` 꼬리표 사라짐 |

## 6. 남은 노출 1건 (결정 요청)

전역 푸터(`layouts/application.html.erb:490`)에
`실무.kr은 … 법제처 OPEN API 기반 자동 검증 및 5단계 게이트를 운영하고 있으나`
문장이 남아 있다. 이는 내부 메타데이터 누출은 아니지만 **현재 사실과 다르다** — 자동 검증 cron 은 2026-04-13 이후 꺼져 있다(`FRESHNESS_JOB_REPORT.md`).
법적 고지 문구라 임의로 고치지 않았다. 문구 수정 또는 cron 복원 중 하나가 필요하다.
