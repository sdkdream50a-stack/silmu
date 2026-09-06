# 02 — GENERAL ADMINISTRATION TAXONOMY

> §8 원칙: **taxonomy 이름을 먼저 고정하고 콘텐츠를 끼워 넣지 않는다.**
> 먼저 운영에 실제로 있는 콘텐츠를 분류하고, 그 다음에 빈칸을 본다.
> 측정 = 2026-09-06 10:43~10:52 KST · 운영 `18fb735`

---

## 1. 내부 taxonomy 는 이미 3층으로 갈라져 있다

| 층 | 값 | 성격 |
|---|---|---|
| `topic.category` | contract · budget · salary · duty · travel · subsidy · expense · property · other | 영문 9종 |
| `guide.category` | 계약 · 예산 · 복무 · 인사 · 민원 | 한글 5종 |
| `audit_case.category` | 수의계약 · 입찰 · 계약체결 · 계약이행 · 대금지급 · 하도급 · 검수/검사 · 예산 · 회계 · 기타 | 한글 10종 |
| 업무 라벨 (`TaskEntryHelper`) | 계약·조달 / 예산·회계 / 복무 / 보수·수당 / 여비·출장 / 보조금 / 재산·물품 / 감사·청렴 / 처음 맡은 업무 | 9종, 위 3층 위에 씌운 뷰 |

**P2 는 이 3층을 통합·개명하지 않는다.** URL·SEO 자산이 걸려 있고, `TaskEntryHelper` 가 이미
런타임 count 로 매핑을 흡수하고 있다. P2 가 하는 일은 **§8 15분류를 관측 격자로 얹어 빈칸을 세는 것**이다.

## 2. §8 15분류 × 운영 실측

`✓`=전용 자산 있음 · `△`=부수적 언급만(다른 업무의 부산물) · `✗`=없음

| # | §8 분류 | Topic | Guide | AuditCase | Tool | Template | 판정 | 근거 |
|---:|---|---:|---:|---:|---:|---:|---|---|
| 1 | 인사 | 0 전용 | 2 | 0 | 6 (인사 domain) | 0 | △ | 임용·전보·평정 토픽 없음. `salary` 가 인사로 오독됨 |
| 2 | 복무 | 12 | 13 (+series 10) | 0 | 2 | 0 | ✓ | duty |
| 3 | 보수·수당 | 12 | 2 | 0 | 6 | 0 | ✓ | salary |
| 4 | 예산·회계 | 23 | 44 (+series 20) | 79 | 6 | 3 | ✓ | budget+expense |
| 5 | 계약·조달 | 57 | 43 (+series 30) | 116 | 19 | 20 | ✓ | contract. **최대 자산** |
| 6 | 재산·물품 | **1 전용** (+4 부수) | 1 | 14 | 0 | 0 | △ | `public-property-management` 1건뿐 → 업무카드 **숨김**(§4) |
| 7 | 보조금·위탁 | 2 | series 10 | 0 | 1 | 0 | ✓(얇음) | subsidy. 위탁은 0 |
| 8 | 민원 | **0** | **1** | 3 | 0 | 0 | △ | `civil-complaint-guide` 1편 |
| 9 | 정보공개 | **1** (FAQ 4) | 0 | 3 | 0 | 0 | △ | `information-disclosure`. **운영에 실재**(§6) |
| 10 | 개인정보·기록물 | **0** | **0** | **0~1** | 0 | 0 | ✗ | 프로브 hit `contract-termination` 은 "계약 파기" **오탐** |
| 11 | 감사·청렴 | 0 전용 | 0 | 257 (전체) | 3 | 0 | ✓(사례만) | 청렴·이해충돌 전용 토픽 0. hit `contract-execution` 은 오탐 |
| 12 | 행정절차·법무 | **0** | **0** | 0 | 1 (법정기간) | 0 | ✗ | 행정심판 hit 는 정보공개 FAQ 안 언급 |
| 13 | 시설·안전 | **0 전용** | **0** | 4 | 0 | 1 (안전점검 체크리스트) | ✗ | `fence-installation` 은 계약 토픽 |
| 14 | 문서·보고·위원회 | 0 전용 (6 부수) | 1 | 35 | 2 (공문서 AI·달력) | 5 (기안문) | △ | 위원회는 **물품선정위원회** 맥락으로만 존재 |
| 15 | 디지털 행정 | **0** | **0** | 1 | 1 (표준어 검사기) | 0 | ✗ | |

### 2.1 오탐 명시 (§30)

프로브가 잡았지만 **해당 업무의 콘텐츠가 아닌 것**을 그대로 카운트하지 않았다.

| 프로브 hit | 실제 정체 | 처리 |
|---|---|---|
| 개인정보 "파기" → `contract-termination` | 계약 파기 | 제외 |
| 감사·청렴 "청렴" → `contract-execution` | 청렴계약 서약(계약 절차) | 제외 |
| 행정절차 "행정심판" → `information-disclosure` | 정보공개 불복 FAQ 1줄 | 제외 |
| 시설·안전 "산업안전" → `fence-installation` | 울타리 설치 **공사계약** | 제외 |

### 2.2 ~~매핑 정정 후보 1건 (선재)~~ → **철회 (운영에 없음)**

> **2026-09-06 R1 정정.** 아래는 **dev DB 기준**이었다. 운영(114 topics)에는 `bid-notice-requirements`
> 토픽 자체가 없고, `category` 9종이 전부 라우트 허용값이며 비ASCII category 는 **0건**이다.
> `P2_HANDOFF §4` 를 운영 재확인 없이 옮긴 자리 — 이 문서가 스스로 §6(dev ≠ prod)을 어겼다.
> 데이터는 고치지 않고 재발 탐지기(`bin/rake silmu:category_integrity`)만 만들었다.
> 상세 = `12_R1_DATA_INTEGRITY_AND_DISCOVERABILITY.md` §3.


`bid-notice-requirements` 의 `category="입찰"` — 라우트 제약(topic.category 는 영문) 밖이라
카테고리 내비에서 고아가 된다. P1.6 이 "콘텐츠 무변경" 원칙 때문에 미수정으로 넘긴 항목이며
**데이터 정정 1행**이면 끝난다. P2 도 코드가 아니라 데이터로 처리한다.

## 3. 업무 카드 노출 게이트 실측 (`TaskEntryHelper`)

`MIN_COVERAGE = 3` · 홈 화면에 카드가 뜨는지는 **런타임 count** 가 결정한다.

| key | 라벨 | count | 노출 |
|---|---|---:|---|
| audit | 감사·청렴 | 257 | ✅ |
| contract | 계약·조달 | 246 | ✅ |
| budget | 예산·회계 | 166 | ✅ |
| newcomer | 처음 맡은 업무 | 80 | ✅ |
| duty | 복무 | 35 | ✅ |
| travel | 여비·출장 | 16 | ✅ |
| salary | 보수·수당 | 14 | ✅ |
| subsidy | 보조금 | 12 | ✅ |
| **property** | **재산·물품** | **1** | **❌ 숨김 (3 미달)** |

**재산·물품은 토픽 2건만 더 있으면 카드가 저절로 켜진다.** UI 작업 0.
이 성질은 회귀 테스트(`콘텐츠가 생기면 업무가 자동으로 나타난다`)로 이미 고정돼 있다.

§8 15분류 중 **정보공개·개인정보·기록물·민원·행정절차·시설안전·문서보고위원회·디지털행정 8종은
업무 카드 자체가 정의돼 있지 않다.** 카드를 먼저 만들지 않는다(§P2_HANDOFF "카드는 콘텐츠의 결과지 원인이 아니다").

## 4. 기관 범위(Agency Scope) 실측 — §9

| 대상 | 공통(미지정) | LOCAL | EDUCATION | NATIONAL | 판정 |
|---|---:|---:|---:|---:|---|
| Topic `jurisdiction` | **99 (86.8%)** | 9 | 6 | 0 | 사실상 미분류 |
| Topic `target_agency` | **99 비어 있음** | LOCAL_GOVERNMENT 9 | PUBLIC_SCHOOL 6 | 0 | |
| Guide `jurisdiction` | **103 (100%)** | 0 | 0 | 0 | **전건 미분류** |
| AuditCase `jurisdiction` | 47 | 122 | 86 | 2 | **양호** |
| Topic `sector` | common 99 | local_gov 9 | edu 6 | — | |
| AuditCase `sector` | common 169 | — | edu 88 | — | |

§9 가 요구한 7종 스코프(CENTRAL_GOVERNMENT · LOCAL_GOVERNMENT · EDUCATION_OFFICE ·
EDUCATION_SUPPORT_OFFICE · PUBLIC_SCHOOL · PRIVATE_SCHOOL · PUBLIC_INSTITUTION) 중
운영 데이터에 **실제로 쓰인 값은 2종**(LOCAL_GOVERNMENT · PUBLIC_SCHOOL)뿐이다.

> **판정**: 기관별 override 구조는 스키마·모델에 **존재하지만 데이터가 87% 비어 있다.**
> 이건 "공통 업무라 비운 것"과 "분류를 안 한 것"이 구분되지 않는 상태다 —
> P2 에서 새 필드를 만들 이유는 없고, **판정 규칙(빈 값 = COMMON 인가 UNCLASSIFIED 인가)을
> 먼저 정하는 것**이 선행이다. 이건 04 문서의 provenance 축과 같은 문제다.

## 5. P2 taxonomy 결론

```
개명·통합              하지 않는다 (URL·SEO·회귀 자산)
새 category 값 추가     하지 않는다 (게이트가 런타임 count 라 불필요)
관측 격자로만 사용       §8 15분류 = 빈칸 세는 자
업무 카드 신설          콘텐츠가 MIN_COVERAGE 를 넘긴 뒤에만
```

빈칸 8종 중 **어디를 먼저 채울지는 taxonomy 가 아니라 03·04 의 실측 우선순위가 정한다.**
