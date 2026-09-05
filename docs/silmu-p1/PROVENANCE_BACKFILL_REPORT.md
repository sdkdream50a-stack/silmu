# PROVENANCE_BACKFILL_REPORT — 감사사례 출처 분류

> ⚠️ 아래 수치는 **로컬 dev DB(191건)** 기준이다. 운영은 257건이며 dev 가 최대 66건 stale 하다(P0 TR-11).
> 운영 적용 시 동일 rake 로 재실행하고 결과를 다시 기록해야 한다 — `MIGRATION_PLAN.md` 참조.

---

## 1. 원칙

**Backfill ≠ 공식 원문을 새로 만들어 넣는 것 (§25).**
분류기는 외부 조회·추론을 하지 않고, `audit_cases` 테이블에 이미 있는 값만 읽는다:
`source`(jsonb) · `verification_source` · `legal_basis` · `sector` / `org_type`.

---

## 2. 결과 (dry-run → 적용)

```
$ bin/rails silmu:p1:provenance_dry_run   # DB 변경 없음, CSV 생성
$ bin/rails silmu:p1:provenance_backfill  # HIGH confidence 만 적용
provenance backfill: applied=191 skipped(non-HIGH)=0
```

### source_type
| 분류 | 건수 | 근거 |
|---|---:|---|
| `ACTUAL_AUDIT` | **86** | `source` jsonb 에 발행기관·문서명·원문 URL·페이지가 모두 존재 |
| `SILMU_RECONSTRUCTED_CASE` | **63** | 콘텐츠가 스스로 재구성임을 명시 (47건 `특정 실사례 아님` / 16건 `source="silmu-2026"`) |
| `UNVERIFIED` | **42** | 출처 자리에 내부 로그만 있거나(→ note 이관) 출처 정보 없음 |

### verification_status (검증 "범위" 분리)
| 상태 | 건수 |
|---|---:|
| `OFFICIAL_SOURCE_VERIFIED` | 86 |
| `LEGAL_REFERENCE_VERIFIED` | 101 |
| `UNVERIFIED` | 4 |

### 기타
| 지표 | 값 |
|---|---:|
| `is_reconstructed = true` | 63 |
| `is_reconstructed = false` (실제 사례로 확인) | 86 |
| `is_reconstructed = null` (미판정 — false 와 구분) | 42 |
| 공개 원문 URL 보유 | **86** (이전 화면 노출 0) |
| `verification_note` 로 무손실 이관된 내부 문자열 | 63 |

---

## 3. Confidence Gate (§27)

| 등급 | 처리 | 이번 결과 |
|---|---|---:|
| HIGH | 자동 적용 | 191 |
| MEDIUM | 검토 큐 (자동 적용 안 함) | 0 |
| LOW | 무변경 | 0 |

**MEDIUM 규칙은 살아 있다.** "기관명 문자열은 있으나 원문 URL·페이지가 없는" 경우가 MEDIUM인데,
로컬 dev 에는 해당 행이 없었다. 운영(257건)에는 P0 에서 관측된 `GOE 2021 경기교육청 감사보고서 (조문번호 명시 없음 — 차후 정밀화 backlog)` 유형 17건이 있으며, 이 중 `source` jsonb 가 비어 있는 행은 MEDIUM 으로 떨어져 **자동 승격되지 않는다.** (§10 원문 미확인 시 ACTUAL_AUDIT 승격 금지)

회귀 테스트: `test/services/authority_classifier_test.rb` — `"MEDIUM — 기관명은 있으나 원문 URL 이 없으면 자동 적용하지 않는다"`

---

## 4. 원문 URL 도달성 실측

분류에 사용된 `source.url` 의 distinct 값 **10개 전부**를 실제로 조회했다.

| 결과 | 건수 |
|---|---:|
| HTTP 200 + 실제 파일 수신 | **10 / 10** |

- `goe.go.kr` 감사사례집 PDF — 200, `application/pdf`, 2.93 MB
- `sen.go.kr` 첨부파일 9종 — 200, 147 KB ~ 315 KB

즉 `ACTUAL_AUDIT` 승격 86건은 **실제로 열리는 원문**에 근거한다.

---

## 5. 산출물

| 파일 | 내용 |
|---|---|
| `silmu_p1_provenance_backfill.csv` | 191행 dry-run (content_id · slug · old_source · proposed_* · confidence · reason · requires_review) |
| `tmp/silmu_p1_provenance_backfill.csv` | 재실행 시 갱신되는 원본 경로 |

## 6. 남은 일

- 운영 257건 재실행 (dev 에 없는 66건 포함)
- MEDIUM 검토 큐 UI — 현재는 CSV. `Admin::TopicReviewsController` 패턴 재사용 권장
- `COURT_CASE` / `OFFICIAL_INTERPRETATION` 은 taxonomy 에 정의되어 있으나 현재 데이터에 해당 행이 없어 0건
