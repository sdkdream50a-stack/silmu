# §25①1호 의미 오용 — 잔여 정리 (2026-09-06)

BASE_HEAD `29664de` · 배포 0 · seed 실행 0 · main merge 0 · STATUS **REVIEW_REQUIRED** 유지.

---

## 1. 왜 남았나 — 탐지기가 «표기»를 요구했다

앞 라운드(F1·F5)의 탐지기는 이렇게 생겼다.

```ruby
D_HO1_AS_SMALL_AMOUNT = /제25조\s*제1항\s*제1호[^\n]{0,40}\(\s*소액\s*수의계약/
D_HO1_AS_LIMIT        = /제25조\s*제1항\s*제1호[^\n]{0,40}\(\s*수의계약\s*한도/
```

**괄호 안의 라벨**이 있어야 걸린다. 그래서 같은 오용이라도 이렇게 쓰면 전부 빠져나갔다.

```
✓ 추정가격이 한도 이하여야 수의계약 가능 (시행령 제25조 제1항 제1호)
지방계약법 시행령 제25조 제1항 제1호의 물품 수의계약 기준(2,000만원 초과 시 경쟁 원칙)
source: "「…시행령」 제25조 제1항 제1호"        ← 검증기가 «정답» 으로 가르치던 자리
```

이번 탐지기는 문자열이 아니라 **의미 결합**을 본다.
표기(`제25조 제1항 제1호` · `제25조제1항제1호` · `§25①1호` · `25조 1항 1호`)를 정규화해 **호 번호**를 뽑고,

- **D-A** 금액·한도 주장(CLAIM_KIND)에 **가장 가까운** 인용이 제1호면 → 조문 오용
- **D-C** 제1호를 인용했는데 ±100자 안에 긴급 문맥(천재지변·긴급·재난·감염병·여유가 없)이 없으면 → 정당화되지 않은 인용

정본: `§25①1호` = 천재지변·감염병 등 **입찰에 부칠 여유가 없는 경우**.
소액수의 금액 체계는 `§25①5호` (가목 공사 4억/2억/1.6억 · 나목 물품·용역 2천만 · 다~바목 상대방 요건).
`config/contract_decision_rules.yml` (`verified_at: 2026-09-06`, `quote` 포함)가 이 매핑의 정본이다.

---

## 2. 전건 판정

### WRONG_ARTICLE — 12 (사용자 지목 7 + 같은 class 신규 5)

| # | 위치 | 내용 | 정정 |
|---|---|---|---|
| 1 | `app/views/topics/flowcharts/_private_contract_limit.html.erb:63` | 「추정가격이 한도 이하여야 … (제1호)」 | 제5호 + 세부 목 확인 문구 |
| 2 | 같은 파일 `:287` | 「수의계약 사유서 (한도 이하)」 desc | 제5호 + 세부 목 확인 문구 |
| 3 | `app/views/topics/show.html.erb:1207` | 「제1호에 따라 … 물품구매 기준금액(2천만원) 이하」 | 제5호 **나목** |
| 4 | `db/seeds/audit_cases/contract_topic_audit_cases.rb:22` | 「제1호의 물품 수의계약 기준(2,000만원 …)」 | 제5호 **나목** |
| 5 | `app/services/blog_legal_verifier.rb:40` | 물품·용역 2천만 `source` | 제5호 **나목** |
| 6 | 같은 파일 `:48` | 전문공사 2억 `source` | 제5호 **가목** |
| 7 | 같은 파일 `:56` | 종합공사 4억 `source` | 제5호 **가목** |
| **8** | `_private_contract_limit.html.erb:162` | 「수의계약 사유서 작성 — 제1호 명시」 | 제5호 명시 |
| **9** | 같은 파일 `:220` | 「필수 서류 · 수의계약 사유서: 제1호 명시」 | 제5호 명시 |
| **10** | `db/seeds/zz_auditcase_verification_2026_06_18_batch14.rb:11` | attest 근거 주석이 「§25①1호=소액 수의계약」 | 제5호로 정정 + 제1호 정의 명시 |
| **11** | `FULL_VERIFICATION_LOG.md:72` | 공사 금액기준 검증 조문 | 제5호 + 정정 표시 |
| **12** | 같은 파일 `:165` | 「근거: 제1호」(공사 4억/2억/1.6억) | 제5호 **가목** + 정정 표시 |

8~12 는 이번에 새로 나온 같은 semantic class 다 (STOP RULE §11 — 동일 class 는 포함).
**10 번이 이 오류 계열의 출처**다. batch14 의 attest 근거 주석이 조문 제목을 잘못 적고 있었고,
그 주석을 근거로 만들어진 `legal_basis`·`verification_source` 가 운영에 적재됐다.

### 세부 목을 붙인 근거

`제25조제1항제5호` 의 목은 **계약유형과 상대방 요건**이 함께 정한다. 그래서 기본은 제5호 + 「세부 목은 계약유형·상대방 요건에 따라 확인」이다.
**계약유형만으로 결정되는 축**(공사=가목 · 물품·용역 일반=나목)에만 목을 붙였고, 근거는 다음이다.

```
D25-1-5-가-general  종합공사 4억     source_locator 제25조제1항제5호가목  verified_at 2026-09-06
D25-1-5-가-special  전문공사 2억     제25조제1항제5호가목
D25-1-5-나          물품·용역 2천만  제25조제1항제5호나목
```

새 금액을 만들지 않았고, 상대방 요건에 따라 갈리는 다·라·마·바목은 **한 곳도 지정하지 않았다**.

### VALID_EMERGENCY_CONTEXT — 11 (수정 0 · 음성 대조)

`topics.rb:1067`·`:1194` · `fix_law_references_2026_03.rb:102` · `topic_bid_failure.rb:185` ·
`topic_fence_installation.rb:64` · `topic_quick_stats_backfill_…batch6.rb:31` · `guides.rb:267` ·
`_private_contract_justification.html.erb:29` · `contract_decision_rules.yml:322` ·
`blog_legal_verifier.rb`(EXPRESSION_CHECKS) · `zz_…batch14.rb`(정정 후 제1호 정의)

파일별 baseline 을 테스트가 잠근다. 총량만 세면 «한 곳이 줄고 다른 곳이 늘어도» 통과하기 때문이다.

### CONTEXT_AMBIGUOUS — 2 (수정 0)

| 위치 | 이유 |
|---|---|
| `db/seeds/audit_cases/topic_goods_selection_committee.rb:11` | 라벨이 「수의계약 사유」이고, 6,800만원 사무용 가구 건이 **어느 호였는지 사례에 없다.** batch14 도 이 레코드를 legal_basis 부정확으로 attest 제외했다. 임의로 호를 지정하지 않는다 |
| `db/seeds/budget_execution_part1.rb:194` | 품의서 기재 예시의 「법령상 사유」 예. 제1호도 실재하는 사유다 |

### 제외 — 관측 스냅샷 (수정 0)

`docs/silmu-p2/r2-align/_data/s77_inventory_{before,after}.json`(`scanned_at` 스캔 스냅샷) ·
`docs/silmu-audit/data/badges.json`(**크롤 원자료** — 현재 운영이 아직 옛 문구이므로 이 파일은 «정확»하다).
이걸 고치면 스냅샷이 운영에 대해 거짓말을 하게 된다. 배포·시드 후 재크롤로 자연히 갱신된다.

`db/seeds/topic_deploy_blocker_fix_2026_09_06.rb` 는 **치환표**라 정정 전 문자열을 반드시 보유한다.
제외 근거(탐지기에 실제로 걸릴 것 · 정정 후 문자열도 보유할 것)를 테스트가 직접 확인한다.

---

## 3. 검증기(정답 원천)를 고칠 때 함께 옮겨야 했던 것

`blog_legal_verifier.rb:142` 의 컨텍스트 게이트가 **조문 문자열로 룰을 고르고 있었다.**

```ruby
if rule[:source].to_s.include?("제25조 제1항 제1호")   # ← §25 금액 룰만 적용하려는 의도
```

`source` 만 제5호로 바꾸고 이 줄을 두고 오면 게이트가 **조용히 죽는다**
(보증금 면제 문맥을 수의계약 한도 오류로 오검출). 뮤턴트 M8 이 이 축이다.

---

## 4. 운영 반영 경로 (§8)

| 경로 | 대상 |
|---|---|
| **DEPLOY_ONLY** | `_private_contract_limit.html.erb`(4곳) · `topics/show.html.erb` · `blog_legal_verifier.rb` |
| **SEED_REQUIRED** | `contract_topic_audit_cases.rb:22` → AuditCase `software-dev-misclassified-as-goods` (`find_or_create_by!` 라 원천만 고치면 운영 row 는 그대로다 — F3 과 같은 축) |
| 데이터 영향 없음 | `zz_…batch14.rb`(주석) · `FULL_VERIFICATION_LOG.md` |

정정 시드는 **새로 만들지 않고 기존 `topic_deploy_blocker_fix_2026_09_06.rb` 에 G1 치환쌍을 추가**했다
(N-a 시드 증식 지적을 늘리지 않기 위해). 실행 경로·멱등·UPDATE 전용 계약은 그대로다.

### 운영 READ-ONLY probe (revision `ce62d2e` · 쓰기 0)

```
AuditCase:private-contract-split-over-limit    WILL_UPDATE  issue/detail/legal_basis/lesson/checkpoints
AuditCase:quote-collection-same-vendor-double  WILL_UPDATE  legal_basis
AuditCase:software-dev-misclassified-as-goods  WILL_UPDATE  detail          ← 이번에 늘어난 1건
Topic:private-contract-limit                   WILL_UPDATE  law_content

ROWS_TO_UPDATE = 4   (직전 라운드 3 → +1)
FIELDS         = 8   (직전 라운드 7 → +1)
CREATED        = 0
VERIFICATION_SOURCE_SYNCED = 1  (변동 없음)
```

`ROWS_TO_UPDATE` 가 3→4 로 바뀐 **정확한 이유**: G1(`software-dev-misclassified-as-goods#detail`) 1건.
이 레코드의 `verification_source` 는 파생값이지만 **stale 이 아니고**, `legal_basis` 를 건드리지 않으므로
재생성 대상이 아니다(실측 `stale=false`). 그래서 `VERIFICATION_SOURCE_SYNCED` 는 1로 유지된다.

---

## 5. 🔴 계측 하네스 자체의 결함 (이번에 발견 · 수리)

**첫 뮤테이션 실행은 11/11 KILLED 였는데, 그 숫자가 거짓이었다.**

뮤테이션 스크립트는 `cp` 로 백업하고 `mv` 로 복원한다. `mv` 는 백업의 mtime 을 되돌려 놓는다.
그리고 이번 뮤턴트 중 하나(`제25조 제1항 제5호` → `제1호`)는 **바이트 수가 완전히 같다.**
`(mtime, size)` 로 키를 잡는 컴파일 캐시 입장에서 복원 전후가 **같은 파일**이다 —
그래서 복원한 뒤에도 **뮤턴트 바이트코드가 계속 실행됐다.**

```
baseline(clean file)   : ISSUES=0
mutated                : ISSUES=1
restored (mv only)     : ISSUES=1   ← 파일에는 제5호가 있는데 결과는 뮤턴트다
restored (mv + touch)  : ISSUES=0
```

그 뒤의 모든 뮤턴트는 **이미 빨간 베이스라인** 위에서 돌아 전부 «KILLED» 로 보였다.
`touch` + 복원 후 베이스라인 확인을 넣고 다시 재니 **M9(과잉정정)가 실제로는 SURVIVED** 였다 —
내 음성 대조가 파일이 아니라 테스트 안의 리터럴만 보고 있었기 때문이다. 그 구멍을 메운 뒤 11/11.

`_measure/` 의 뮤테이션 스크립트 4종에 전부 `touch` + `BASELINE_RED` 확인을 넣었고,
정적 가드(`뮤테이션 하네스는 복원 시 mtime 도 되돌린다`)로 조용히 빠지지 않게 잠갔다.

---

## 6. 회귀 (§9)

| 항목 | 결과 |
|---|---|
| residual targeted (`article25_semantic_residual` + `deploy_blocker_fix_seed` + `contract_split_semantic_alignment` + `contract_s77_scope` + `blog_legal_verifier`) | **73 runs · 771 assertions · 0F** |
| source-quality (`contract_bid_source_accuracy_test`) | 11 runs · 198 assertions · 0F |
| R2 targeted (`contract_decision/*` + flow) | 102 runs · 336 assertions · 0F |
| **full suite** | **671 runs · 4,422 assertions · 0F · 0E · 14 skips** (BEFORE 654 / 4,236) |
| residual mutation (`mutation_article25_residual.sh`) | **KILLED 11 · SURVIVED 0 · NOT_APPLIED 0 · BASELINE_RED 0** |
| deploy-blocker mutation | KILLED 8 · SURVIVED 0 · NOT_APPLIED 0 · BASELINE_RED 0 |
| alignment mutation | KILLED 24 · SURVIVED 0 · NOT_APPLIED 0 · BASELINE_RED 0 |
| s77 mutation | KILLED 14 · SURVIVED 0 · NOT_APPLIED 0 · BASELINE_RED 0 |
| R2 mutation | KILLED 27 · SURVIVED 0 · NOT_APPLIED 0 |
| RuboCop (변경·신규 .rb 7파일) | **no offenses** |
| **R2_CORE_MODIFIED** | **0** (`config/contract_decision_rules.yml` · `app/services/contract_decision/**` · `contract_method_service.rb` diff 없음) |
| CPSC-P3D-001 / CPEB-P3C-001 | RESOLVED / BOTH_CONTEXTUAL 유지 |

### 뮤턴트

```
M1  탐지기를 다시 «괄호 의존» 으로 되돌림              KILLED
M2  view :63 오기 재도입                               KILLED
M3  view :287 오기 재도입                              KILLED
M3b view :162·:220 오기 재도입                         KILLED
M4  topics/show :1207 오기 재도입                      KILLED
M5  감사사례 원천 오기 재도입                          KILLED
M5b G1 치환쌍 제거 (원천만 고치고 운영 미전파)         KILLED
M6  verifier 물품·용역 제1호 재도입                    KILLED
M7  verifier 공사 2건 제1호 재도입                     KILLED
M8  조문만 옮기고 컨텍스트 게이트 문자열 미이관        KILLED
M9  정당한 긴급 §25①1호까지 제5호로 오정정 (과잉정정)  KILLED
```

---

## 7. STATUS

```
BASE_HEAD                    29664de
CANDIDATES_BEFORE            사용자 지목 7 + 같은 class 신규 5 = 12
WRONG_ARTICLE                12  (전건 정정)
VALID_EMERGENCY_CONTEXT      11  (수정 0)
CONTEXT_AMBIGUOUS            2   (수정 0 · 판정 목록으로 고정)
SEMANTIC_RESIDUAL_AFTER      D-A 0 · D-C 는 판정된 3건뿐(다른 class 1 + ambiguous 2)
VERIFIER_FIXED               3 source + 1 컨텍스트 게이트
PRODUCTION_PATH              DEPLOY_ONLY 3파일 · SEED_REQUIRED 1레코드
PRODUCTION_DRY_RUN           ROWS_TO_UPDATE 4 · CREATED 0 · FIELDS 8 · VS_SYNCED 1 · 쓰기 0
R2_CORE_MODIFIED             0
DEPLOY                       NO
SEED_EXECUTED                NO
STATUS                       REVIEW_REQUIRED
```

---

## 8. 이번 scope 밖 — FINDING 만 기록 (STOP RULE §11)

| # | 위치 | 내용 | 성격 |
|---|---|---|---|
| **R-1** | `public/forms/수의계약사유서.html:136` | 「**제25조 제1항 제4호**에 따른 물품구매 수의계약 **기준금액(2,200만원)** 이하」 | 사용자 노출 공개 양식. 조문(제4호=특정인의 기술)도 틀리고 **2,200만원은 «한도» 로서는 어느 조문에도 없는 숫자**다(repo 안의 2,200만원은 전부 개별 사례의 계약금액이고, `contract_decision_rules.yml` 의 물품 한도는 2천만원이다). 다른 class 라 이번에 손대지 않았다 — **다음 라운드 BLOCKING_CANDIDATE 1순위** |
| R-2 | `app/views/guides/resources.html.erb:476` | 「특허권·저작권 등에 의하여 ○○만이 제조·공급 … **제25조제1항제1호**에 따라」 | 제1호를 «특정인의 기술» 사유로 인용(실제 §25①4호). 금액 주장이 아니라 다른 class |
| R-3 | `db/seeds/audit_cases/contract_topic_audit_cases.rb:15,34` | 원천은 「**소프트웨어산업 진흥법**」(폐지·전부개정), 운영 row 는 이미 「소프트웨어 진흥법」 | **원천 ↔ 운영 역방향 divergence**. 지금 시드를 다시 돌리면 운영이 옛 법령명으로 되돌아가지 않는지 확인 필요(현 시드는 UPDATE 치환쌍만 적용하므로 영향 없음) |
| R-4 | `db/seeds/topic_deploy_blocker_fix_…` 외 정정 시드 4종 | 실행 순서·중복 치환 통합 검토 미완 (직전 라운드 N-a 이월) | NONBLOCKING |
| R-5 | 과거 라운드 뮤테이션 점수 | §5 의 캐시 함정을 통과했는지 재확인 필요. 이번에 4종 전부 하네스 수리 후 재측정했고 전부 SURVIVED 0 이었다 | 이번 재측정으로 해소 |
