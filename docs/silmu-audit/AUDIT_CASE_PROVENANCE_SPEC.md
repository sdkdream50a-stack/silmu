# AUDIT_CASE_PROVENANCE_SPEC — 감사사례 출처 규칙

> **이 사이트에서 가장 시급한 단일 문서다.** 감사사례 257건은 사이트 콘텐츠의 47%를 차지하면서
> 원문 링크 0건 · 내부 커밋 해시 노출 119건 · 재구성 사례에 검증 배지 110건이라는 상태다(TR-01·TR-02).

---

## 1. 현재 상태 (실측 · 2026-09-05)

| 항목 | 값 |
|---|---:|
| 감사사례 총계 | 257 |
| `<main>` 내 공식 원문 링크 보유 | **0** |
| "5단계 정합성 검증 완료" 배지 | 246 (96%) |
| 검토 출처 = 내부 엔지니어링 메타데이터 | **119 (46%)** |
| 검토 출처 = 재구성 공시 | 110 (43%) |
| 검토 출처 = 실명 감사보고서 | 17 (7%) — 전부 "차후 정밀화 backlog" 문구 동반 |
| 검증 표면 없음 | 11 |
| 익명 플레이스홀더(`○○`·`△△`·`K 사무관`) 포함 | 200 |
| 금액이 있으나 조문 근거 없음 | 38 |

---

## 2. Provenance 4분류 (필수)

```
provenance ∈ {
  ACTUAL_AUDIT            실제 감사 지적 (감사원·자체감사·상급기관 감사)
  COURT_OR_TRIBUNAL       판결·결정 (법원·헌재·행정심판·소청)
  OFFICIAL_INTERPRETATION 유권해석·질의회신 (법제처·소관부처·권익위)
  SILMU_RECONSTRUCTED_CASE 공개 패턴을 일반화한 재구성 사례
}
```

**분류되지 않은 사례는 발행하지 않는다.** 현재 257건 전부 미분류 상태이므로 backfill이 P0다.

---

## 3. 분류별 필수 필드

| 필드 | ACTUAL_AUDIT | COURT | INTERPRETATION | RECONSTRUCTED |
|---|:--:|:--:|:--:|:--:|
| `source_agency` | ✅ | ✅ | ✅ | — |
| `audit_year` / 선고·회신 연도 | ✅ | ✅ | ✅ | — |
| `audit_name` / 사건번호 | ✅ | ✅ | ✅ | — |
| `original_document_url` | ✅ | ✅ | ✅ | — |
| `page` | ✅ | | | — |
| `disposition` (처분) | ✅ | ✅ | | — |
| `legal_basis` (조문) | ✅ | ✅ | ✅ | ✅ |
| `verified_at` | ✅ | ✅ | ✅ | ✅ |
| `pattern_basis` (일반화의 근거가 된 공개 패턴) | — | — | — | ✅ |
| `is_fictional_narrative` | false | false | false | **true** |

`disposition ∈ { 시정요구, 주의요구, 통보, 권고, 징계요구, 변상판정, 고발, 개선요구 }`

---

## 4. 표시 규칙 (TR-01·TR-02 직접 수정)

### 4.1 실제 사례
```
🏛 실제 감사 지적 사례
   경기도교육청 2021년 종합감사 · 처분: 시정요구
   감사결과보고서 p.147  [원문 보기 →]
   ✅ 법령 근거 검증 완료 · 2026-06-15 기준
```

### 4.2 재구성 사례 — **제목 옆에 라벨을 강제한다**
```
📘 재구성 사례  (실제 특정 사건이 아닙니다)
   공개된 감사 지적 패턴을 실무 상황으로 재구성했습니다.
   일반화 근거: 경기교육청 2021 · 서울교육청 2025 공개 감사결과의 반복 지적 유형
   ✅ 법령 근거 검증 완료 · 2026-05-30 기준
   ⚠️ 본문의 기관명·인물·금액은 예시입니다.
```

### 4.3 금지 규칙 (기계 검사)
| 규칙 | 내용 |
|---|---|
| PR-1 | `verification_note`(커밋 해시·배치 ID·lawId·dashboard 키)는 **절대 공개 렌더 금지** |
| PR-2 | 내부 backlog 문구("차후 정밀화 backlog" 등) 공개 렌더 금지 |
| PR-3 | `provenance=SILMU_RECONSTRUCTED_CASE`이면 배지 문구에 "사례 검증" 표현 금지 → "법령 근거 검증"으로 한정 |
| PR-4 | `provenance=ACTUAL_AUDIT`인데 `original_document_url`이 없으면 **`OFFICIAL_PARTIAL`로 강등하고 배지 미표시** |
| PR-5 | 재구성 사례의 금액·건수는 "예시" 표기 또는 근거 조문 병기 |
| PR-6 | 익명 플레이스홀더(`○○`·`△△`·`A씨`)가 있으면 자동으로 재구성 후보로 플래그 |

---

## 5. Backfill 절차 (257건)

```
STEP 1  현재 verification_source 문자열 → verification_note 로 전량 복사 (무손실)
STEP 2  문자열 패턴으로 1차 자동 분류
          "silmu 자체 시드|특정 실사례 아님|일반화"  → SILMU_RECONSTRUCTED_CASE   (110건)
          "^(GOE|SEN|BAI|MOE)\s*\d{4}|감사보고서"     → ACTUAL_AUDIT 후보          (17건)
          commit|batch|lawId|mcp|dashboard            → UNVERIFIED (재판정 대기)   (119건)
          (없음)                                      → UNVERIFIED                 (11건)
STEP 3  UNVERIFIED 130건을 본문 서술로 재판정
          익명 플레이스홀더 + 서술형 → SILMU_RECONSTRUCTED_CASE 로 전환 (가장 정직한 기본값)
STEP 4  ACTUAL_AUDIT 후보 17건은 원문 URL 확보 전까지 OFFICIAL_PARTIAL, 배지 미표시
STEP 5  본문-출처 문맥 불일치 재검사 (현재 확인된 1건: budget-item-wrong-travel)
```

STEP 2~4는 `db/content_migrations/` 멱등 패턴으로 수행한다. **새 기계를 만들지 않는다.**

> **핵심 판단:** 근거를 못 찾는 사례를 삭제하지 않는다. **재구성 사례로 정직하게 강등한다.**
> 이미 110건이 그렇게 하고 있다 — 그 정직함을 나머지 130건으로 확장하는 것이 이번 수정의 본질이다.

---

## 6. 완료 판정
| 게이트 | 조건 |
|---|---|
| AP-1 | `provenance` 미분류 감사사례 **0건** |
| AP-2 | 공개 HTML에 `commit`/`batch`/`lawId`/`backlog` 문자열 **0건** |
| AP-3 | 배지 표시 사례 중 `original_document_url` 결손 **0건** |
| AP-4 | 재구성 사례 전부 제목 라벨 노출 |
| AP-5 | 금액 보유 사례 중 근거·예시 표기 결손 **0건** (현재 38건) |
