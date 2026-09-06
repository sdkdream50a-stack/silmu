# 09 — AUTHORITY COVERAGE

> §18: **새 법령 truth system 을 만들지 않는다.** 기존 7개 모델을 재사용한다.
> 이 문서는 "그 시스템이 지금 무엇을 덮고 있는가"를 실측하고, P2 후보가 근거를 댈 수 있는지 판정한다.

---

## 1. Authority 스택 실측 (운영 2026-09-06)

| 모델 | 건수 | 상태 |
|---|---:|---|
| `AuthoritySource` | **1** | 출처 1곳 |
| `AuthorityDocument` | **8** | §2 목록 |
| `AuthorityVersion` | 8 | 문서당 1버전 |
| `AuthorityChangeEvent` | 8 | 초기 등록분 |
| `AuthorityReviewTask` | **0** | 검토 큐 비어 있음 |
| `AuthorityVerificationEvent` | **0** | 검증 이벤트 0 |
| `ContentAuthorityLink` | **209** | §3 |
| `Law` (별도 레거시) | 15 | `effective_date` **0/15** |

## 2. 적재된 공식 문서 8종

| id | 문서 | 유형 |
|---:|---|---|
| 1 | 지방자치단체를 당사자로 하는 계약에 관한 법률 | LAW |
| 2 | 〃 시행령 | PRESIDENTIAL_DECREE |
| 3 | 〃 시행규칙 | MINISTERIAL_ORDINANCE |
| 4 | 지방회계법 | LAW |
| 5 | 지방회계법 시행령 | PRESIDENTIAL_DECREE |
| 6 | 지방공무원법 | LAW |
| 7 | 지방공무원 복무규정 | PRESIDENTIAL_DECREE |
| 8 | 지방공무원 보수규정 | PRESIDENTIAL_DECREE |

**덮는 축 = 지방계약 · 지방회계 · 지방공무원(복무·보수). 그게 전부다.**

## 3. 콘텐츠 ↔ 근거 연결 실측 — 여기가 가장 큰 구조적 공백

| content_type | 링크 수 | 대상 모수 | 커버리지 |
|---|---:|---:|---:|
| `AuditCase` | 195 | 257 | **75.9%** |
| `Tool` | 14 | 39 | **35.9%** |
| **`Topic`** | **0** | **114** | **0.0%** |
| `Guide` | 0 | 103 | 0.0% |
| **합계** | **209** | — | — |
| confidence | 전건 `HIGH` | | |

> **Topic 은 Solution Page 의 대표 표면인데 구조화 근거 링크가 0 건이다.**
> 토픽 114건 전부 `law_content` **텍스트**는 갖고 있다(01 §5). 즉 근거가 없는 게 아니라
> **근거가 텍스트로만 있고 구조로는 없다.** 그래서 조문이 개정돼도 어느 토픽이 영향받는지
> 시스템이 알 수 없다 — Freshness Engine 의 `IMPACT` 단계가 Topic 에는 도달하지 못한다.

## 4. Freshness 파이프라인 현재 상태

```
DETECT → VERSION → DIFF → IMPACT → REVIEW → VERIFY      (PUBLISH 단계 없음 — 안전 계약)
  ?        8         ?      Topic 0     0        0
```

| 단계 | 실측 |
|---|---|
| DETECT | `AuthorityFreshnessCheckJob` 이 `config/recurring.yml` **미등록** → 가동 안 함 |
| VERSION | 8건 (초기 적재분) |
| IMPACT | `ContentAuthorityLink` 기준. **Topic 0 → Topic 영향판정 불가** |
| REVIEW | `AuthorityReviewTask` 0 |
| VERIFY | `AuthorityVerificationEvent` 0 |
| 콘텐츠 표시 | `freshness_state` **474건 전부 빈 값** |
| 알림 | P1.55B 구현 완료 · **운영 SMTP 실도달 LIVE_UNPROVEN** |

`weekly_law_sync` 는 등록돼 있고(`0 7 * * 2`) **다음 자연 실행 = 2026-09-09(화) 07:00 KST**.
`laws.effective_date` 0/15 는 그 결과를 관측한 뒤 판단한다(P1.55B §4.3 그대로 이월).

> **판정: AUTHORITY_COVERAGE = 계약·회계·복무 3축만 · Topic 연결 0% · Freshness 미가동.**
> 이건 결함이 아니라 **아직 켜지 않은 상태**다. "CURRENT" 라고 말한 적이 없으므로 거짓말은 없다(01 PC5).

## 5. P2 상위 20 × 근거 확보 가능성

| 상태 | 뜻 | 상위 20 중 |
|---|---|---:|
| **LOADED** | AuthorityDocument 8종으로 조문을 댈 수 있다 | **9** (#1 #2 #3 #4 #7 #10 #12 #15 #16) |
| **EXISTS_NOT_LOADED** | 공식 법령·지침은 실재하나 우리 스택에 없다 | **11** (#5 #6 #8 #9 #11 #13 #14 #17 #18 #19 #20) |
| **UNKNOWN** | 공식 근거 자체가 불명 | 0 |

### 5.1 적재가 필요한 문서 (P2 후보가 실제로 요구하는 것)

| 필요 문서 | 요구한 후보 | 유형 |
|---|---|---|
| 지방자치단체 세출예산 집행기준 | #9 일상경비 · #14 예산과목 · #8 업무추진비 | 지침/훈령 |
| 공무원 여비 규정 (Law 15 에는 있음) | #20 국외출장 | 대통령령 |
| 공무원 수당 등에 관한 규정 (Law 15 에 있음) | #12 초과근무 · #18 명예퇴직 | 대통령령 |
| 소득세법 (Law 15 에 있음) | #6 연말정산 | 법률 |
| 지방보조금법 / 보조금 관리에 관한 법률 | #11 보조금 정산 | 법률 |
| 인지세법 | #13 인지세 | 법률 |
| 공공기관의 정보공개에 관한 법률 | 정보공개(P2 tier) | 법률 |
| 개인정보 보호법 | #19 개인정보 | 법률 |
| 기간제법 / 교육공무직 지침 | #5 기간제 | 법률+지침 |

> **주목**: `Law` 테이블 15건에는 여비규정·수당규정·소득세법·공무원연금법이 **이미 있다.**
> `AuthorityDocument` 8종과 **겹치지 않는다.** 두 스택이 병존하고 있다(P1.55A 판정:
> legacy `Law` 의 공개 직접 소비처 0 · 공개 UI 는 `LawContentFetcher` 실시간 cache 사용).
> **P2 가 할 일은 새 스택을 만드는 게 아니라 이 둘의 관계를 확정하는 것**이다 — 그건 설계 판정이지 코드가 아니다.

## 6. §18 소스 위계 — 그대로 유지

```
공식 소스(법령·시행령·규칙·예규·지침·유권해석·감사결과)   → authority truth
커뮤니티·블로그·카페(`CafeArticle` 모델 존재)             → question/pain signal ONLY
```

`CafeArticle` 은 **법적 사실의 truth source 로 쓰지 않는다.** 03 의 갭 레이더도
`SearchLog`(우리 사이트 질의)만 썼고 외부 커뮤니티를 근거로 쓰지 않았다.

## 7. §19 Audit Case provenance 실측 — ~~결함 1건~~ → **결함 0건 (2026-09-06 R1 철회)**

> **정정.** 이 절의 "미검증 61건이 근거 신뢰도 HIGH 로 표기 = FAIL" 판정은 **틀렸다.**
> `provenance_confidence` 는 출처 신뢰도가 아니라 **분류 판정의 자동적용 게이트**다
> (HIGH=자동적용 / MEDIUM=검토큐 / LOW=무변경 — `audit_case_provenance_classifier.rb` §27).
> `UNVERIFIED + HIGH` = "출처가 없다는 분류를 확신한다" 로, 계약상 정상이며 정직한 표기다.
> 운영에서 분류기 재실행 → 저장값 **MISMATCH 0 · MEDIUM 0**, 뷰 사용처 **0건**.
> 나는 컬럼 의미를 코드로 확인하지 않고 이름에서 추론했다.
> 조치 = **없음**(UNCHANGED 61). 상세 = `12_R1_DATA_INTEGRITY_AND_DISCOVERABILITY.md` §2.

| provenance | 건수 | 비율 |
|---|---:|---:|
| `ACTUAL_AUDIT` | 86 | 33.5% |
| `SILMU_RECONSTRUCTED_CASE` | 110 | 42.8% |
| `UNVERIFIED` | 61 | 23.7% |
| `COURT_OR_TRIBUNAL` | 0 | — |
| `OFFICIAL_INTERPRETATION` | 0 | — |

`verification_status` 축: `LEGAL_REFERENCE_VERIFIED` 163 · `OFFICIAL_SOURCE_VERIFIED` 86 ·
`UNVERIFIED` 6 · `RECONSTRUCTED` 2.

**교차 검증 결과**
```
재구성인데 실제 감사로 표시된 건            0    ← PASS (§19 오분류 없음)
source_type=UNVERIFIED 인데 provenance_confidence=HIGH   61   ← FAIL
is_reconstructed = nil (미판정)                          61   ← 위 61건과 동일 집합
```

> ~~미검증 61건이 "근거 신뢰도 HIGH" 로 표기돼 있다 → §19 위반~~
> **철회.** 위 정정 참조 — 공개 화면은 이 값을 쓰지 않고(`source_type`·`is_reconstructed` 기반),
> 컬럼 의미상 모순도 아니다. **재구성↔실제 오분류 0건은 그대로 유효**하다(PC4 PASS).

## 8. P2 가 Authority 에 대해 하지 않을 것

```
새 truth 모델 신설            §18 금지
법령 본문 생성·요약 확정        §20 금지
법령 변경 자동 확정            안전 계약 (PUBLISH 단계 없음)
freshness 스케줄러 임의 활성화   별도 승인 사안 — 이번 세션 범위 밖
운영에 가짜 소스 장애 주입       §47 위반 (P1.55B 가 이미 거부한 경로)
```
