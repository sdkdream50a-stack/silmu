# AGENCY_RULE_MODEL — 기관별 규칙 계층 설계

> 해결하려는 문제: 같은 질문("연가는 며칠인가", "수의계약 한도는 얼마인가")에 대해 **기관마다 정답이 다르다.**
> 현재 사이트는 이 차원을 갖고 있지 않다 — 549건 중 **352건(64%)이 `target_agency=UNSPECIFIED`**, 국가·지방 규정을 함께 말하면서 적용 대상을 밝히지 않는 항목이 85건(TR-06).

---

## 1. 왜 복제가 답이 아닌가

기관 유형은 7종, 지역은 17개, 학교유형·회계체계까지 곱하면 조합이 수백이다.
콘텐츠를 조합마다 복제하면:
- 법령 1건 개정 시 수백 건을 고쳐야 한다 (현재도 검증이 3개월 멈춰 있다 — TR-05)
- 검색 카니벌라이제이션이 폭증한다 (이미 6건 중복 — TR-10)
- 복제본 간 불일치가 새로운 신뢰 사고를 만든다

→ **상속(inheritance) 모델을 쓴다.**

---

## 2. 차원 정의

```
agency_type ∈ {
  CENTRAL_GOVERNMENT          중앙행정기관
  LOCAL_GOVERNMENT            시·도 / 시·군·구 / 사업소 / 읍·면·동
  EDUCATION_OFFICE            시·도교육청
  EDUCATION_SUPPORT_OFFICE    교육지원청
  PUBLIC_SCHOOL               공립학교
  PRIVATE_SCHOOL              사립학교
  PUBLIC_INSTITUTION          공기업 / 준정부기관 / 기타공공기관
}

official_type   ∈ { NATIONAL_OFFICIAL, LOCAL_OFFICIAL, EDUCATION_OFFICIAL,
                    PUBLIC_INSTITUTION_EMPLOYEE, CONTRACT_WORKER }
region          ∈ { ALL } ∪ 17개 시도
education_office∈ { ALL } ∪ 17개 시도교육청
school_type     ∈ { PUBLIC, PRIVATE, NONE }
fiscal_system   ∈ { NATIONAL_FINANCE, LOCAL_FINANCE, EDU_SPECIAL_ACCOUNT, SCHOOL_ACCOUNTING }
applicable_from : date
applicable_to   : date | null
```

`fiscal_system`을 별도 차원으로 둔 이유: **학교회계와 일반 지방회계 혼용(오류 유형 E)**이 감사사례에서 반복 관측되기 때문이다. 기관유형만으로는 이 구분이 안 된다(같은 교육청 소속이어도 본청은 교육비특별회계, 학교는 학교회계).

---

## 3. 상속 모델

```
                    COMMON_RULE
                 (모든 기관 공통 골격)
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
 CENTRAL_OVERRIDE   LOCAL_OVERRIDE   EDUCATION_OVERRIDE
        │                 │                 │
        │                 │        ┌────────┴────────┐
        │                 │        ▼                 ▼
        │                 │  SCHOOL_OVERRIDE   PRIVATE_SCHOOL_OVERRIDE
        │                 ▼
        │          REGION_OVERRIDE (시도·교육청 자치법규)
        ▼
 INSTITUTION_OVERRIDE (공공기관 자체 규정)
```

### 해석 규칙 (결정적)
1. `COMMON_RULE`에서 시작한다.
2. 사용자의 `agency_type` 경로를 따라 **더 구체적인 override가 이전 값을 덮는다.**
3. `applicable_from ≤ 기준일 < applicable_to` 인 버전만 후보다.
4. **동일 구체성 수준에서 충돌하면 병합하지 않고 `AMBIGUOUS`로 표시하고 두 값을 모두 보여준다.**
   — 임의 병합이 지금까지의 관할 혼재를 만들었다. 모르는 것은 모른다고 표시한다.
5. override가 없으면 상위 값을 그대로 쓰되, **"공통 규칙 적용"이라고 명시**한다(침묵하지 않는다).

---

## 4. 데이터 표현

새 테이블 1개만 추가한다. 콘텐츠 테이블은 건드리지 않는다.

```ruby
create_table :agency_rules do |t|
  t.string  :task_key,        null: false   # 예: "contract.private.limit"
  t.string  :rule_key,        null: false   # 예: "single_estimate.goods.limit"
  t.string  :scope_level,     null: false   # COMMON | CENTRAL | LOCAL | EDUCATION | SCHOOL | REGION | INSTITUTION
  t.string  :agency_type
  t.string  :region
  t.string  :education_office
  t.string  :school_type
  t.string  :fiscal_system
  t.jsonb   :value,           null: false, default: {}   # {amount: 20000000, unit: "KRW"} 등
  t.string  :law_ref                                     # 근거 조문
  t.string  :official_source_url
  t.date    :applicable_from, null: false
  t.date    :applicable_to
  t.string  :authority_status, null: false
  t.datetime :verified_at
  t.timestamps
  t.index [:task_key, :rule_key, :scope_level]
  t.index [:task_key, :applicable_from]
end
```

### 시드 소스는 이미 있다
`config/legal_standards.yml`과 `config/contract_thresholds.yml`이 **사실상 `COMMON_RULE` + `LOCAL_OVERRIDE`를 이미 담고 있다.**
```yaml
# legal_standards.yml (version: 2026-02-04)
contract:
  single_estimate:   { goods: 20_000_000, service: 20_000_000, construction: 20_000_000 }
  multiple_estimate: { goods: 50_000_000, construction_general: 400_000_000, ... }
```
→ 이 YAML을 `agency_rules` 행으로 승격하면서 `scope_level`·`applicable_from`·`official_source_url`을 채우는 것이 첫 작업이다. **새 지식을 만들지 않고 기존 상수에 차원을 붙이는 일이다.**

---

## 5. 화면 계약

Solution Page 상단에 기관 선택기를 둔다. 선택은 쿠키/계정에 저장한다(`users`에 `default_agency_*` 추가).

```
[내 기관: 시·도교육청 ▾]

✅ 당신 기관 기준 답
   물품 1인 견적 수의계약 한도 = 2,000만원
   근거: 지방계약법 시행령 §25①5 나목 (2026-05-20 기준) · 원문 →

ℹ️ 다른 기관은 다릅니다
   중앙행정기관  → 국가계약법 시행령 §26  (금액 상이)
   공공기관      → 자체 계약사무규칙 우선 · 기관 규정 확인 필요
```

**금지:** 기관을 고르지 않았다는 이유로 아무 값이나 기본 노출하지 않는다. 미선택 시 "적용 기관을 선택하세요"를 먼저 보여준다 — 지금의 UNSPECIFIED 64%가 만드는 위험이 바로 이것이다.

---

## 6. 도입 순서

| 단계 | 내용 | 위험 |
|---|---|---|
| A1 | `target_agency` 컬럼 backfill (549건) | 없음 (읽기 전용 메타) |
| A2 | `agency_rules` 테이블 생성 + YAML 2종 승격 | 낮음 (신규 테이블) |
| A3 | 계약·복무 2개 도메인에서 override 실증 (파일럿) | 낮음 |
| A4 | Solution Page 기관 선택기 노출 | 중간 (UX 변경) |
| A5 | 전 도메인 확대 | — |

A1·A2는 **화면 변화 0**이다. 데이터 기반을 먼저 깔고, 화면은 그 다음이다.
