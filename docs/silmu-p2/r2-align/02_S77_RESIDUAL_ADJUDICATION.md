# 02 — 잔여 §77 문맥 판정 (SILMU_R2_RESIDUAL_77_ADJUDICATION)

> 2026-09-06 · branch `fix/silmu-r2-legacy-semantic-alignment-0906` · base `1ccf310` (통합 base `93c4fd0`)
> **배포 0 · seed 실행 0 · 운영 쓰기 0 · R2 core 변경 0.**
> "§77을 언급했다"로 고치지 않는다. 공사 문맥의 정당한 인용과 계약유형 일반화를 갈랐다.

---

## 1. 목록을 다시 만들었다 — "24건"을 그대로 믿지 않았다

앞 세션이 남긴 24는 **그때의 계측기가 낸 숫자**다. 계측기를 다시 세우니 대상 정의도 숫자도 바뀌었다.

| 계측기 판본 | 잔여 후보 | 왜 달라졌나 |
|---|---|---|
| 앞 세션 (문장 단위 + 제외목록) | 24 | R2 core·시험문제 등을 **제외목록**으로 뺀 뒤 센 값 |
| 이번 (5축 · 버킷 분리 · TAG 수리 후) | **132 언급 → 판정 대상 85** | 전건을 세고 버킷으로 나눈다. 제외를 숫자에서 감추지 않는다 |

계측기를 만들며 **자기 자신의 결함 세 개**를 먼저 잡았다.

1. `<[^>]+>` 가 줄바꿈을 넘어 매칭돼 Ruby heredoc 마커 `<<~CONTENT` 가 "태그 시작"이 됐다.
   다음 `>` 까지의 본문이 통째로 지워져 **그 구간의 §77 진술이 검사에서 사라졌다.**
   양성 대조가 "표본이 진술로 잘리지 않는다"로 이것을 잡았다.
2. 맨 `예규` 를 두 트랙 표지로 봐서 **기획재정부 회계예규·조달청 예규**(국가계약 계열 오인용)까지
   "옳은 문장"으로 통과시켰다 — 2건.
3. ROOT 를 한 단계 잘못 세어 `docs/` 를 스캔했다. **0 파일을 스캔하고 0건을 냈다.**
   이제 `app/`·`db/seeds/` 존재를 assert 한다.

---

## 2. 판정축 — contains("제77조") 로 판정하지 않는다

```
ARTICLE          §77 / §77①③ … 인용 위치
CONTRACT_TYPE    문장이 스스로 유형을 말하면 그것, 아니면 레코드(토픽/감사사례) 범위
CLAIM_KIND       ground(근거 주장) vs locator(조문 위치 표기)
CLAIM_STRENGTH   absolute(절대·금액무관·언제나) / conditional / citation
POLARITY         적용범위를 한정·부정하는가 · 두 트랙(§7제2호·행안부 예규)을 갈라 적는가
```

**POLARITY 가 없으면 "물품·용역에 §77 은 적용되지 않습니다" 같은 옳은 문장이 결함으로 잡힌다** — 실제로 6건 났다.
**문맥은 ±N자 창으로 정해지지 않는다.** ±600 은 결정 불가를, ±2500 은 어느 파일에서든 "공사"를 주워 온다.
운영 콘텐츠는 레코드 단위로 제공되므로 **슬러그 구간**이 독자의 실제 문맥이다.

판정 규칙(코드로 고정 · `_measure/s77_adjudication_scan.py`):

```
R2 core 경로            → R2_CORE_FROZEN     (§14 동결. 조용히 VALID 에 섞지 않는다)
범위 한정/두 트랙 표지    → VALID
strength = absolute     → OVERGENERALIZATION (§77①단서가 분할을 허용한다. 절대명제는 근거보다 강하다)
kind = locator          → 공사면 VALID, 아니면 AMBIGUOUS (라벨인지 매핑 주장인지 사람이 본다)
그 밖: 공사면 VALID, 아니면 OVERGENERALIZATION
소스 주석               → NO_ACTION_INTERNAL (사용자에게 나가지 않는다)
```

`mixed`·`general` 은 "모르겠다"가 아니라 **"한정하지 않았다"** 이다 — §77 은 공사 전용이므로 그 자체가 과확장이다.

---

## 3. 결과

| | BEFORE (1ccf310) | AFTER |
|---|---|---|
| §77 언급 총계 | 132 | 128 |
| `R2_CORE_FROZEN` (§14 동결) | 47 | 47 |
| `NO_ACTION_INTERNAL` (소스 주석) | 12 | 11 |
| **`VALID_CONSTRUCTION_SCOPE`** | 48 | **67** |
| **`LEGACY_OVERGENERALIZATION`** | **18** | **0** |
| **`CONTEXT_AMBIGUOUS`** | **7** | **3** |
| 사람 판정으로 뒤집은 행 | 29 | 30 |

BEFORE 는 정정 전 트리(`git archive 1ccf310`)를 **같은(수리된) 계측기**로 다시 잰 값이다.
같은 도구로 재지 않으면 개선폭이 도구 변경분과 섞인다.

### MODIFIED — 진술 26건 / 12파일 (그중 1건은 소스 주석)

| 파일 | 건 | 무엇이 틀렸나 |
|---|---|---|
| `db/seeds/topic_split_contract.rb` | 8 | 사무용품·용역 사례에 §77. `§77 (추정가격 산정)` 은 **§7 표제** |
| `db/seeds/topic_estimated_amount.rb` | 5 | 물품·용역 한도 회피 분할을 §77 위반으로 단정 |
| `db/seeds/topic_faqs_backfill_…batch4.rb` | 2 | 범위 없는 §77 · `§77제2항`(공사 계획단계 검토)을 "전체 사업비 기준" 근거로 오인용 |
| `app/views/topics/flowcharts/_split_contract_prohibition.html.erb` | 2 | 계약유형 무관 플로차트 전제 |
| `db/seeds/audit_cases/contract_method_violations.rb` | 1 | 「용역·공사·물품 구매라도」라 써 놓고 §77 |
| `db/seeds/audit_cases/topic_audit_cases_batch_01.rb` | 1 | **조문 원문에 없는 인용문**(국가계약법 문체) |
| `app/views/legal_compliance_mailer/monthly_deep_check.html.erb` | 1 | 조문 매핑 라벨 |
| `app/views/guides/audit_frequent_issues.html.erb` | 1 | 감사 빈출 지적의 근거 조문 |
| `config/tool_trust.yml` | 1 | R2 가 두 트랙으로 만든 뒤에도 §77 단독 |
| `db/seeds/topic_quick_stats_backfill_…batch7.rb` | 2 | quick_stats note + 파생 주석 |
| `zz_guide_verification_…batch5.rb` · `zz_topic_verification_…batch4.rb` | 2 | 내부 권위 기록(다음 세션이 근거로 읽는다) |

정정 문구는 **항목별로 따로 썼다**(§6). 일괄 템플릿으로 덮지 않았다 —
공사 사례(`사례 2 청사 화장실 리모델링`)는 §77 이 맞고 표제만 틀렸으므로 표제만 고쳤다.

### UNMODIFIED_VALID — 67건

R2 도구의 공사 트랙 UI(15) · 시험문제 은행(3) · 펜스 설치 토픽(3) · 국가/지방 조문 대비표(3) ·
`topic_split_contract` 사례 2 · `AuditCase split-contract-to-avoid-bidding`(총 공사금액 3억 4,700만원 · 전문공사) 등.
**이 버킷이 음성 대조 역할을 한다** — 회귀가 "공사 문맥의 정당한 인용 3종"을 잡지 않음을 단언한다.

### CONTEXT_AMBIGUOUS — 3건 (수정하지 않음 · §7)

전부 `AuditCase private-contract-split-over-limit` 한 레코드다.

```
legal_basis  '… 시행령 제77조 (계약 분할 금지), 행안부 예규 제2023-24호 제5장 제2절'
issue        '실내환경 개선사업(총사업비 1억 5천만원) … 수의계약 한도액(5천만원) 초과'
checkpoints  '계약 분할 금지 조항(시행령 제77조) 위반 여부 계약 체결 전 자체 점검'
```

**필요한 추가 근거** — ① 실내환경 개선(LED 교체·환기 설비·도색)이 공사인지 물품·용역 혼합인지
② 사건이 적은 "수의계약 한도 5천만원"이 어느 조문 기준인지(공사 한도는 4억/2억/1.6억이라 맞지 않는다)
③ 행안부 예규 제2023-24호의 제5장 제2절이 실재하는지(현행 예규의 분할계약 금지는 제1장 제1절 5).

같은 레코드의 **창작 인용문**은 계약유형과 무관하게 사실이 아니므로 그것만 정정했다.
AMBIGUOUS 를 억지로 0 으로 만들지 않는다.

---

## 4. 대조 (§9)

전부 **저장소 실제 텍스트**다. 합성 문장은 쓰지 않았다.
이미 고친 결함의 양성 대조는 **정정 전 커밋의 blob** 에서 읽는다 —
"지금 남아 있는 결함"으로만 대조를 세우면 다 고친 순간 대조가 사라져 탐지기가 죽어도 0 이 나온다.

| | 표본 | 기대 | 결과 |
|---|---|---|---|
| P1 | `topic_estimated_amount.rb` 물품·용역 §77 일반화 (blob `1ccf310`) | 검출 | OVERGENERALIZATION ✅ |
| P2 | `topic_split_contract.rb` "§77 (공사의 분할계약 금지)" | 미검출 | VALID ✅ |
| P3 | `subtopics.rb` "분할계약 절대 금지!" (blob `93c4fd0`) | 강도 absolute | absolute ✅ |
| P4 | `split_contract_checker.html.erb` §77③ 회피목적 진술 | 강도 conditional | conditional ✅ |
| P5 | `contract_flow.html.erb` "§77은 물품·용역에 적용되지 않습니다" | 미검출 | VALID ✅ |

회귀 = `test/models/contract_s77_scope_test.rb` (12 runs · 119 assertions)
음성 대조 4종: 공사 한정 인용 · 범위 부정/두 트랙 · **국가계약 계열 예규는 두 트랙 표지가 아님** ·
판정 불가 3건의 개수·앵커 폭(≥20자)·실재 고정.

---

## 5. 뮤테이션 (§10) — `_measure/mutation_s77.sh`

**KILLED 14 · SURVIVED 0 · NOT_APPLIED 0** (각 뮤턴트는 치환 건수를 먼저 세고 0건이면 NOT_APPLIED)

| | 뮤턴트 | 결과 |
|---|---|---|
| M1 | 공사 표지를 범위 인정에서 제거 | KILLED |
| M2 | 범위 검사를 무조건 통과로 | KILLED |
| M3 | 용역 사례의 §77 근거 복원 | KILLED |
| M4 | "분할계약 절대 금지" 복원 | KILLED |
| M5 | **예외 목록에 넓은 앵커 추가** | KILLED |
| M6 | 예규 근거(도서 등 예외) 제거 | KILLED |
| M7 | §77 표제에서 "공사" 제거 | KILLED |
| M8 | TWO_TRACK 을 맨 "예규"로 완화 | KILLED |
| M9 | 조문 원문에 없는 인용문 복원 | KILLED |
| M10 | tool_trust 를 §77 단독으로 복원 | KILLED |
| M11~M13 | D/E 정정 복원(§12) | KILLED |
| M14 | "한시적 특례"만 지우고 회귀 주장 유지 | KILLED |

> M5·M13 은 **처음에 생존했다.**
> M5 는 테스트의 개수 단언만 무력화하는 형태여서 다른 단언이 잡아 "생존처럼" 보였다 —
> 진짜 위험은 예외 목록 자체가 넓어지는 것이라 그쪽을 찌르게 바꿨고, 테스트도 앵커 폭을 단언하게 고쳤다.
> M13 은 `한시적 특례` 라는 말만 지우면 같은 거짓 주장이 통과했다 —
> "3천만원으로 회귀" 자체를 잡는 두 번째 탐지기를 만들고 M14 로 고정했다.

---

## 6. 의미 정합 (§11)

| 질문 | 엔진 | 콘텐츠 | 충돌 |
|---|---|---|---|
| 물품 1,800만+1,800만+1,500만 동일목적·기간내 | `HIGH_SPLIT_RISK` · **§7제2호 인용 · §77 미인용** | 범위 없는 §77 진술 0건 | 0 |
| 공사 단일공사·전체 확정 | `HIGH_SPLIT_RISK` · **§77 인용** | `제77조 (공사의 분할계약 금지)` | 0 (양립) |

`ENGINE=REVIEW_REQUIRED ↔ CONTENT=ABSOLUTE_PROHIBITION` 조합 **0**.
현재 트리의 `claim_strength=absolute` 진술 = **0건**.

---

## 7. 운영 실측 (§16 · READ-ONLY · 쓰기 0)

`_measure/prod_s77_probe.rb` → `_data/prod_s77.json` (revision `ce62d2e`)

```
§77 언급 29 · 범위 미표시 14
  → 정정 대상 11 · VALID 2(fence-installation · split-contract-to-avoid-bidding) · AMBIGUOUS 1
```

> **`Topic#audit_cases` 는 같은 이름의 컬럼을 `has_many` 연관이 가린다.**
> `public_send` 로 읽으면 AuditCase 레코드 목록이 오고(다른 곳에서 이미 세는 것), **정작 컬럼 본문은
> 한 번도 안 읽힌다.** 쓰기까지 갔다면 연관을 Hash 로 덮어써 `AssociationTypeMismatch` 가 난다 —
> 실제로 DRY-RUN 이 그 예외로 멈췄다. 컬럼은 `read_attribute`/`write_attribute` 로만 다룬다.
> 이 수리 전 probe 는 44/15 를 보고했다(연관을 통해 AuditCase 를 이중 계수).

### 🔴 시드 원천 ↔ 운영 콘텐츠가 갈라져 있다 (이번에 발견)

운영에는 과거 어느 시점의 **§77 → §7 일괄 치환** 흔적이 있다.

```
시드 원천   "- 근거: 시행령 제77조, 기획재정부 회계예규"
운영        "- 근거: 시행령 제7조, 기획재정부 회계예규"
시드 원천   "**관련근거:** 시행령 제77조 (추정가격 산정)"      ← 공사 사례
운영        "**관련근거:** 시행령 제7조 (추정가격 산정)"        ← 일괄 치환이 맞던 인용을 틀리게 만들었다
```

시드 원천만 고치면 운영은 그대로 남는다. 정정 시드가 **운영 변종을 함께 매핑**한다.
정정 시드 = `db/seeds/topic_s77_scope_fix_2026_09_06.rb` (멱등 · **미실행**).
`save!` 를 제거한 DRY-RUN 판본으로 잰 결과 **13개 필드가 바뀔 예정**이고,
판정이 "수정 불필요"인 3건(fence-installation · AuditCase#141 · AuditCase#134 issue)은 **바뀌지 않는다**.

---

## 8. 회귀 (§17)

| 항목 | 결과 |
|---|---|
| residual targeted (`contract_s77_scope_test`) | 12 runs · 119 assertions · 0F |
| legacy semantic alignment (`contract_split_semantic_alignment_test`) | 12 runs · 329 assertions · 0F |
| source-quality (`contract_bid_source_accuracy_test`) | 11 runs · 198 assertions · 0F |
| R2 targeted (`contract_decision/*` + flow) | 102 runs · 336 assertions · 0F |
| **full suite** | **634 runs · 4,120 assertions · 0F · 0E · 14 skips** (BEFORE 622 / 3,981) |
| R2 mutation (`mutation_r2.sh`) | KILLED 27 · SURVIVED 0 · NOT_APPLIED 0 |
| alignment mutation (`mutation_align.sh`) | KILLED 13 · SURVIVED 0 · NOT_APPLIED 0 |
| residual mutation (`mutation_s77.sh`) | KILLED 14 · SURVIVED 0 · NOT_APPLIED 0 |
| RuboCop (변경·신규 .rb 25파일) | 25 files inspected, **no offenses** |
| **R2_CORE_MODIFIED** | **0** (`git diff` 빈 결과) |
| §15 out-of-scope 4건 | diff 에 `50억`·`제53조`·`지체상금`·`33일` **0줄** |

P1.6 · R1 자산은 full suite 에 포함돼 있고 이번 diff 가 건드린 파일에 없다.

---

## 9. STATUS

```
RESIDUAL_CANDIDATES_BEFORE        132 언급 (판정 대상 85 · R2 core 47 동결)
VALID_CONSTRUCTION_SCOPE          67   (수정 0)
LEGACY_OVERGENERALIZATION         0    (진술 26건 정정 · 12파일)
CONTEXT_AMBIGUOUS                 3    (수정 0 · 추가 근거 기록)
NO_ACTION_INTERNAL                11   (소스 주석)

SEMANTIC_DIVERGENCES_AFTER        0
사용자-facing absolute 진술        0
CPSC_P3D_001                      RESOLVED (회귀 유지)
CPEB_P3C_001                      RESOLVED / BOTH_CONTEXTUAL (회귀 유지)
R2_CORE_MODIFIED                  0
PRODUCTION_WRITE                  0
DEPLOYED                          NO
SEED_EXECUTED                     NO (DRY-RUN 만)

STATUS = PRODUCTION_READY 후보
```

§18 그대로다 — divergence 0, 사용자-facing absolute contradiction 0.
`CONTEXT_AMBIGUOUS` 3건은 divergence 와 **구분해서** 남긴다. 억지로 0 으로 만들면 그게 조작이다.

**NEXT_EXACT_TASK** — 이 HEAD 를 대상으로 호스트와 다른 벤더의 독립검증 1회.
그 뒤에만 seed 실행·배포 승인.
