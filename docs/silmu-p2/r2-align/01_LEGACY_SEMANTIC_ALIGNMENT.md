# 01 — R2 ↔ 레거시 의미 정합 (SILMU_R2_LEGACY_SEMANTIC_ALIGNMENT)

> 2026-09-06 · branch `fix/silmu-r2-legacy-semantic-alignment-0906` · base `93c4fd0`
> **배포 0 · seed 실행 0 · main merge 0 · R2 엔진 변경 0.**
> R2 판단 엔진과 레거시 본문이 **같은 질문에 반대 결론**을 내던 5건을 공식 근거로 판정했다.

---

## 1. 정본 (VERIFIED_AT 2026-09-06 · 이 세션에서 재취득)

측정 산출물 = `_data/sources_verified.json` (법제처 공동활용 API 실측)

| SOURCE | 문서 | EFFECTIVE_DATE | 현행 | LOCATOR |
|---|---|---|---|---|
| 지방계약법 | 법률 | 시행 2024. 2. 17. | 현행 | MST 253973 |
| 지방계약법 시행령 | 대통령령 제36338호 | **시행 2026. 6. 3.** | 현행 | MST 286149 |
| 지방자치단체 입찰 및 계약 집행기준 | **행정안전부 예규 제372호** | **시행 2026. 7. 1.** | 현행 | 행정규칙ID 29508 · 일련번호 2100000281382 |

### ARTICLE / PARAGRAPH / SCOPE / CONTRACT_TYPE

**시행령 §77 (공사의 분할계약 금지)** — SCOPE = **공사 전용**. 표제·본문 모두 "공사".
①단서 1~3호가 분할발주를 **허용**하고, ③은 §77①각 호의 공사에 붙는 회피목적 금지, ④는 보고의무.

**시행령 §7제2호 (추정가격의 산정)** — CONTRACT_TYPE = 전 유형. **금지 조항이 아니다.**
"개별적인 조달 요구가 복수로 이루어지거나 분할되어 이루어지는 계약"은 직전 회계연도 또는
직전 **12개월** 유사계약 총액(가목) / 해당 회계연도 또는 직후 12개월 총액(나목)을 추정가격으로 본다.

**행안부 예규 제1장 제1절 5.라** — CONTRACT_TYPE = **용역·물품**.
> "계약담당자는 용역․물품 계약에 대하여도 단일 사업을 **부당하게** 분할하거나 시기적으로 나누어
> 체결하지 않도록 해야 한다. **다만, 도서 등 간행물 구매 시** 최근 발행된 도서의 구매, 보관 공간의
> 제약 등으로 일괄 구매가 곤란한 **불가피한 사유가 있는 경우에는 분할하여 구매할 수 있다.**"

→ 물품·용역 분할의 근거는 §77 이 아니라 **§7제2호(합산) + 예규 5.라(부당한 분할 금지)** 이고,
   금액과 무관한 절대 금지가 아니며 **명시된 예외가 있다.**

**시행령 §25①5호** — CONTRACT_TYPE = 물품 제조·구매계약 또는 용역계약
| 목 | 대상 | 금액 |
|---|---|---|
| 나목 | 일반 | 2천만원 이하 |
| 다목 | **청년창업기업** | 2천만원 초과 **5천만원** 이하 |
| 라목 | **소기업 · 소상공인** | 2천만원 초과 **1억원** 이하 |
| 마목 | 학술연구·원가계산·건설기술 등 특수 지식·기술·자격 | 2천만원 초과 1억원 이하 |
| 바목 | 여성·장애인·사회적기업·사회적협동조합·자활기업·마을기업 | 2천만원 초과 1억원 이하 (3)~6)은 취약계층 고용비율) |

**부칙 전문 대조** — `유효기간` 조항 6건 전건이 2005·2009년분이고 §25①5호 다목~바목을 가리키는 것은
**없다.** "2026.6.30 만료 → 3천만원 회귀"는 **부존재**. 그날 종료된 것은 보증금·절차 한시특례
(행안부 고시 제2025-72호)이며 별개다 — 저장소의 `guides/resources.html.erb` 가 이미 그렇게 쓰고 있었다.

**시행령 §30①2호** — 1인 견적 2천만원 이하. 단 가목(청년창업·여성·장애인)·나목(사회적기업·
사회적협동조합·자활기업·마을기업)은 **5천만원** 이하. **소기업·소상공인은 이 열거에 없다.**
→ §25 의 "특례"와 §30 의 "특례"는 **대상도 금액도 다르다.**

---

## 2. 판정

| # | 항목 | VERDICT | 근거 |
|---|---|---|---|
| A | `regulation_verifier`: "분할계약 금지 = 시행령 §77" | **LEGACY_WRONG** | §77 표제·본문 = 공사. 물품·용역 근거는 §7제2호 + 예규 5.라 |
| B | `goods-3`: "물품 분할계약은 금액과 무관하게 금지" | **LEGACY_WRONG** | 예규 5.라는 "**부당한**" 분할 금지 + 도서 등 명시 예외. 절대명제가 아니다 |
| C | subtopics: "분할계약 절대 금지" | **LEGACY_WRONG** | §77①1~3호·예규 5.나/5.라 단서·§28 이 허용 경로를 둔다 |
| D | "특례기업 5천만원" | **BOTH_CONTEXTUAL** | §30①2호(1인 견적)에서는 **정본**, §25①5호(수의계약 한도)에서는 **틀렸다**(청년창업만 5천만) |
| E | subtopics 1억원 특례 열거 | **LEGACY_WRONG (불일치·불완전)** | 금액 1억 ✅ · 계약유형(물품·용역) ✅ · **대상에서 라목 명시 대상 "소상공인" 누락**, 청년창업 5천만 계층이 "등"에 쓸려 들어감 |

**R2_WRONG = 0.** R2 의 §77=공사 / 물품·용역 미확인 축 REVIEW_REQUIRED / §28 범위 제한 /
RuleSet fail-closed 는 전부 정본과 일치한다. threshold·weight 변경 0.

### D 의 문맥 분리 (같은 문자열, 다른 조문)

| 문맥 | 정본 여부 | 처리 |
|---|---|---|
| `private-contract-limit` · `small-amount-contract` (§25 한도) | ❌ 틀림 | 청년창업 5천만 / 소기업 등 1억 두 계층으로 정정 |
| `single-quote` · `private-contract-amount` (§30 견적) | ✅ 정본 | **무수정 — 회귀로 보존을 고정** |

---

## 3. BEFORE → AFTER

| # | 파일 | BEFORE | AFTER |
|---|---|---|---|
| A | `app/services/regulation_verifier.rb` | `- 분할계약 금지: 시행령 제77조` | `- 공사의 분할계약 금지: 시행령 제77조 (…공사 한정)` + `- 물품·용역의 분할 조달: 시행령 제7조제2호 … + 행안부 예규 … 5.라` |
| A' | 〃 (금액 체크리스트) | 나목·다목만 | 나·다·라·바목 4계층 + §30 특례가 §25 특례와 다르다는 경고 |
| B | `app/views/guides/contract_flow.html.erb` | "분할계약은 금액과 무관하게 금지됩니다" | §7제2호 합산 + 예규 5.라(부당한 분할) + 도서 예외 + "§77은 물품·용역에 적용되지 않습니다" |
| C | `db/seeds/subtopics.rb` | "분할계약 절대 금지! / 1건의 계약을 2개 이상으로 분할하면 지적 대상" | "부당한 분할계약 금지 / … 나눴다는 사실만으로 위법이 되지는 않습니다 — §77①각 호·예규 5.라 단서" |
| D | `quick_stats.rb` · `quick_stats_sprint3.rb` · `topic_fold_summary_…_batch2.rb` | "특례기업 5,000만원" (§25 한도) | "청년창업 5,000만원·소기업 등 1억원" |
| D' | `app/views/contract_reasons/index.html.erb` | "한시적 특례 … ~2026.6.30 시행, 만료 후 종전 3천만원으로 회귀" | "§25①5호 다목~바목의 **상시 제도**이며 부칙에 유효기간 조항이 없다. 2026.6.30 종료된 것은 보증금·절차 한시특례(고시 제2025-72호)로 별개" |
| E | 9파일 16곳 | "소기업·여성·장애인…" | "소기업·**소상공인**·여성·장애인…" |
| E' | `db/seeds/subtopics.rb` | "2천만원 (특례 1억)" · "특례: … 등 1억" | "2천만원 (청년창업 5천만·소기업 등 1억)" · "특례: 청년창업 5천만 · …" |

---

## 4. 대조 (positive / negative control)

회귀 = `test/models/contract_split_semantic_alignment_test.rb` (12 runs · 309 assertions)

- **양성** — 7개 탐지기 전부가 BEFORE 문구에서 검출된다. "특례 상한=5천만" 판정기는 3가지 표기에서 양성.
- **음성 ①** — 정정문에서 전건 미검출.
- **음성 ②** — **공사 문맥의 정당한 §77 인용 3종**을 잡지 않는다.
- **음성 ③** — **§30(1인 견적)의 "특례기업 5천만원"이 보존됐는지**를 단언한다(과잉정정 방지).
- **음성 ④** — **§77③으로 한정된** "회피 목적 분할은 위법" 진술을 절대금지 단정으로 세지 않는다.
- **음성 ⑤** — **실제로 2026.6.30 종료된** 보증금·절차 한시특례 서술을 결함으로 세지 않는다.

> ④⑤는 탐지기를 처음 넓게 썼을 때 **실제로 오검출했다.** 범위를 넓히면 음성을 다시 재야 한다.
> D 판정기도 처음엔 `5,000만원`만 잡고 `5천만원`을 놓쳐 운영 실측을 2건으로 **과소보고**했다 —
> 양성 표본을 3가지 표기로 넓힌 뒤에야 11건이 나왔다.

뮤테이션 = `_measure/mutation_align.sh` — **KILLED 13 · SURVIVED 0 · NOT_APPLIED 0**
(각 뮤턴트는 치환 건수를 먼저 세고 0건이면 `NOT_APPLIED` 로 보고한다. 미적용은 생존처럼 보인다.)

---

## 5. 엔진 ↔ 콘텐츠 의미 충돌

문자열 동일성이 아니라 **결론**을 비교한다.

| 질문 | 엔진 | 정정 후 콘텐츠 | 충돌 |
|---|---|---|---|
| 물품 500만+500만, 동일목적·기간내 분할 | `REVIEW_NEEDED` (§7제2호 · §77 미인용) | "부당한" 분할 금지 + 합산 + 예외 | 0 |
| 소기업 8천만원 물품 | `POSSIBLE` (§25①5호라목) | 소기업·소상공인 1억 계층 명시 | 0 |
| 청년창업기업 8천만원 물품 | `COMPETITIVE_PROCEDURE_REQUIRED` (다목 5천만 초과) | 청년창업 5천만 계층 명시 | 0 |

**정정 대상 범위의 `ENGINE=REVIEW_REQUIRED ↔ CONTENT=ABSOLUTE_PROHIBITION` 충돌 = 0.**

---

## 6. 운영 실측 (READ-ONLY · 쓰기 0)

`_measure/prod_divergence_probe.rb` → `_data/prod_divergence.json`
(revision `ce62d2e` · probe 는 `update`/`save`/`delete` 를 호출하지 않는다)

| 패턴 | 운영 적발 | 판정 |
|---|---|---|
| `D_special_cap_5000` | 11 | §25 문맥 4건만 결함. 나머지 7건은 §30 문맥 = 정본 |
| `E_missing_micro` | 8 | 전건 결함 |
| `E_unqualified_1eok` | 1 | 결함 |
| `C_absolute_headline` / `C_any_split_flagged` | 1 / 1 | 결함 |
| `B` / `D_sunset` | 0 / 0 | 뷰·코드에만 있음 → 배포로 해소 |

정정 시드 = `db/seeds/topic_legacy_semantic_alignment_2026_09_06.rb` (멱등 · **미실행**)
운영 DRY-RUN(`save!` 제거판, 쓰기 0) 결과 **14개 필드가 바뀔 예정**이고,
§30 문맥(`single-quote` · `private-contract-amount` 의 quick_stats/summary)은 **바뀌지 않는다**.

> 시드 작성 중 발견: **`fold_summary` 컬럼은 존재하지 않는다** — fold 요약은 `summary` 에 들어 있다.
> 처음엔 `respond_to?(:fold_summary)` 로 분기해 그 정정이 **조용히 아무 일도 하지 않았다.**

---

## 7. 잔여 — 이번 세션에서 **고치지 않은** 것 (STATUS 를 좌우한다)

`_measure/residual_s77_scan.py` → `_data/residual_s77.json`
판정축 = **같은 문장 안에 공사 한정 표지가 있는가** (±200자 창으로 재면 파일 어딘가의 "공사"가
걸려 전건 통과한다 — 실제로 0 이 나왔다. ROOT 를 한 단계 잘못 세어 0 파일을 스캔한 적도 있다).

**잔여 24건 / 12파일** — §77 을 범위 표시 없이 일반 분할금지 조문으로 드는 진술.

| 파일 | 건 | 성격 |
|---|---|---|
| `db/seeds/topic_quick_stats_backfill_…batch7.rb` | 5 | quick_stats note (일부는 공사 요건 인용) |
| `db/seeds/topic_estimated_amount.rb` | 4 | 물품·용역 한도 회피 분할을 §77 위반으로 단정 |
| `db/seeds/topic_split_contract.rb` | 3 | 토픽 전체. `§77 (추정가격 산정)` 은 **§7 오기** |
| `app/views/topics/flowcharts/_split_contract_prohibition.html.erb` | 2 | 계약유형 무관 플로차트 |
| `db/seeds/topic_faqs_backfill_…batch4.rb` | 2 | `§77제2항`을 "전체 사업비 기준" 근거로 오인용 |
| `db/seeds/audit_cases/contract_method_violations.rb` | 2 | "§77조는 분할계약을 명시적으로 금지" |
| `zz_*_verification_*.rb` 3종 | 3 | 내부 검증 메타데이터 (사용자 비노출) |
| `app/views/legal_compliance_mailer/monthly_deep_check.html.erb` | 1 | A 와 같은 모양의 조문 매핑 |
| `config/tool_trust.yml` | 1 | `split-contract-checker.laws` 가 §77 만 — R2 가 §7제2호 트랙을 추가한 뒤 미갱신 |
| `db/seeds/audit_cases/…edu_rest_14….rb` | 1 | 게이트 주석 |

**왜 안 고쳤나** — 과제가 지정한 5건과 별개 판정이 필요한 집합이다(일부는 공사 사안이라 §77 인용이
정본이다). 항목별 조문 판정 없이 일괄 치환하면 맞는 인용을 틀리게 만든다.

### 함께 관측했으나 손대지 않은 것 (지목 범위 밖)

- `db/seeds/subtopics.rb` — "시행령 제25조 제1항 **제1호** (수의계약 한도)" → 정본은 **제5호**
- `db/seeds/subtopics.rb` — "시행령 제30조 **제2항** / 2인 이상 견적 대상" → §30②는 지정정보처리장치 조항
- `app/views/topics/flowcharts/_private_contract_limit.html.erb` — "제25조제1항(**제9호 등**)" → 정본은 제5호 라목~바목
- `db/seeds/audit_cases/topic_audit_cases_batch_01.rb` — §77 인용문이 **조문 원문에 없는 문장**("각 중앙관서의 장 또는 계약담당공무원은 수의계약의 한도금액을 초과…")
- **R2 규칙집의 근거 출처에 행안부 예규가 없다** — 04 문서가 물품·용역 4축을 "근거 미확인"이라 쓴 것은
  법·시행령·시행규칙만 적재했기 때문이다. 예규 5.라가 그중 "한도·경쟁 회피 효과" 축에 근거를 준다.
  판정 결과(REVIEW_REQUIRED)는 보수적이라 틀리지 않았지만 **이유 진술은 좁다.** R2 재설계 대상으로 보고만 한다.

---

## 8. 회귀

| 항목 | 결과 |
|---|---|
| R2 targeted (`test/services/contract_decision/` + `test/integration/contract_decision_flow_test.rb`) | 통과 (full 에 포함) |
| **full suite** | **622 runs · 3,981 assertions · 0F · 0E · 14 skips** (BEFORE 610 / 3,672 / 0F) |
| 신규 정합 회귀 | 12 runs · 309 assertions · 0F |
| 뮤테이션 | KILLED 13 · SURVIVED 0 · NOT_APPLIED 0 |
| RuboCop (변경 .rb 10파일) | 10 files inspected, **no offenses** |
| R2 core 변경 | **0** — `app/services/contract_decision/**` · `config/contract_decision_rules.yml` · `contract_thresholds.yml` 무변경 |

---

## 9. STATUS

```
KNOWN_SEMANTIC_DIVERGENCES_AFTER (지목 5건)      0
NEWLY_MEASURED_RESIDUAL (§77 과확장)             24 / 12파일
DEPLOYED                                         NO
SEED_EXECUTED                                    NO (DRY-RUN 만)

STATUS = REVIEW_REQUIRED
```

§11 규칙 그대로다 — 발산이 0 이 아니면 PRODUCTION_READY 로 부르지 않는다.
지목 5건은 닫혔지만, 그 5건을 판정하다가 **같은 계열의 잔여 24건을 처음으로 계량했다.**
5건만 보고 "정합 완료"라고 부르면 측정한 것과 다른 것을 보고하는 것이 된다.
