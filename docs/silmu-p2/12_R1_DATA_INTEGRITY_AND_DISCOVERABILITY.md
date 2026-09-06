# 12 — R1: 데이터 정합(P-1·P-2·P-3) + 기존 도구 발견성

> 실행 2026-09-06 11:09~ KST · branch `feature/silmu-p2-general-admin-expansion`
> P1.6 baseline `18fb735` **FROZEN 유지** — 동결 7파일 변경 0 (§5 실증)
> 새 콘텐츠 0 · 새 도구 0 · 검색 알고리즘 변경 0

---

## 0. 먼저: 이 세션이 **감사(01·02·09) 자체를 3건 정정**했다

R1 은 감사가 지목한 결함을 고치러 들어갔는데, **그중 2건은 결함이 아니었다.**
감사에서 내가 컬럼 의미를 코드로 확인하지 않고 추론했거나, dev 기준 인계 문서를 운영 재확인 없이 옮긴 탓이다.

| # | 감사의 주장 | 실측 후 판정 | 근거 |
|---|---|---|---|
| C-1 | 01 §1 "FAQ 도달가능 **455**" | **465** 였다 | 455 는 배열만 센 값. `faq_list` 가 이중 인코딩 2건(FAQ 10건)을 구제하고 있었다 |
| C-2 | 09 §7 "미검증 61건이 confidence HIGH = **FAIL**" | **결함 아님** | §2 |
| C-3 | 02 §2.2 "고아 category 1건" | **운영에 없음** | §3 |

세 정정 모두 01~11 문서에 반영했다(`> 2026-09-06 R1 정정` 주석).

---

## 1. P-1 — FAQ jsonb 정규화 · **9건 실제 회복** ✅

### 1.1 실측된 문제 (운영)

`topics.faqs` (jsonb) 가 3형태로 저장돼 있었다.

| 형태 | 건수 | 상태 |
|---|---:|---|
| `ARRAY_OK` 정상 배열 | 110 | — |
| `STRING_PARSEABLE` jsonb 가 JSON **문자열**(이중 인코딩) | 2 (`estimated-price` 5 · `late-penalty` 5) | `faq_list` 가 구제 중 — 도달은 됨. 잠재 결함 |
| `STRING_BROKEN` Ruby `Hash#inspect` 문자열 (`"k"=>"v"`) | 2 (`bid-announcement` 4 · `bidding` 5) | `JSON.parse` 실패 → `rescue` 가 `[]` → **9건 소실** |

`Topic#faq_list` 의 `rescue` 가 빈 배열을 돌려주는 바람에 화면은 안 죽고 **사라진 사실도 같이 조용했다.**
운영 로그에 `[Topic#faq_list] JSON 파싱 실패 (id=1)` 만 매 요청 남고 있었다.

### 1.2 복구 결과 (운영 실적용)

```
FAQ_AUTHORED    474 → 474   (불변 — 내용을 만들지 않았다)
FAQ_REACHABLE   465 → 474   (+9)
비배열 저장       4 →   0
Topic.updated_at 무변경      (update_column — 편집 이력·freshness 오염 없음)
```

되살아난 9건 (**전부 원문 그대로**, 창작 0):

| 토픽 | 질문 |
|---|---|
| `bid-announcement` | 입찰공고 기간은 최소 며칠인가요? / 재공고 시 공고기간은? / 입찰공고 후 조건을 변경할 수 있나요? / 긴급공고는 어떤 경우에 가능한가요? |
| `bidding` | 일반경쟁입찰과 제한경쟁입찰의 차이는? / 입찰이 유찰되면 어떻게 하나요? / 입찰공고는 최소 며칠 전에 해야 하나요? / 전자입찰은 반드시 나라장터를 사용해야 하나요? / 낙찰률(투찰률)은 어떻게 결정되나요? |

### 1.3 회복이 **사용자에게 도달했는지** 실증

복구 전에는 이 질의에 "바로 답"이 구조적으로 불가능했다(FAQ 가 `[]` 였으므로).

| 질의 | 복구 후 운영 "바로 답" |
|---|---|
| `입찰공고 기간` | **입찰공고 기간은 최소 며칠인가요?** (`bid-announcement`) |
| `재공고 공고기간` | **재공고 시 공고기간은?** (`bid-announcement`) |

### 1.4 내용 무변경 증명

- 변환은 `eval` 을 쓰지 않는다. 문자열 리터럴 **밖에서만** `=>`→`:`, `nil`→`null` 로 옮기는 스캐너다
- 적용 전 **불변식 검사**: 복원된 모든 question/answer 가 원문 문자열의 부분문자열일 것 — 4/4 통과
- `FAQ_AUTHORED` 474 불변 — 건수가 변했으면 즉시 중단하도록 `raise` 를 걸었다
- 롤백 payload(원문 4건 + sha256) 보존

### 1.5 재발 차단

`bin/rake silmu:faq_integrity` — 운영에서도 돌릴 수 있는 read-only 검사.
`STRING_BROKEN` 이 1건이라도 있으면 **exit 1**. 조용히 삼키는 `rescue` 에 건수 0 강제를 붙였다.

---

## 2. P-2 — provenance "모순" 61건 → **결함 아님. UNCHANGED 61** ✅

### 2.1 감사가 무엇을 잘못 읽었나

감사 09 §7 은 `source_type=UNVERIFIED` 인데 `provenance_confidence=HIGH` 인 61건을
"미검증이 확신 HIGH 로 표기됐다 = FAIL" 로 판정했다. **컬럼 의미를 코드로 확인하지 않고 추론했다.**

정본은 `app/services/audit_case_provenance_classifier.rb` 헤더에 적혀 있다.

```
신뢰도 게이트 (§27):
   HIGH   → 자동 적용
   MEDIUM → 검토 큐 (자동 적용 안 함)
   LOW    → 변경하지 않음
```

즉 `provenance_confidence` 는 **"출처가 얼마나 믿을 만한가"가 아니라 "이 분류 판정을 자동 적용해도 되는가"** 다.
`UNVERIFIED + HIGH` = **"출처가 없다는 분류를 확신한다"** — 정직한 표기다.
분류기 자신이 그 조합에 `reason: "출처 정보 없음 — UNVERIFIED 로 명시"` 를 달아 HIGH 를 부여한다.

### 2.2 증거 기반 재판정 (운영 read-only)

분류기를 **운영에서 다시 돌려** 저장값과 대조했다.

```
오늘 분류기 판정   ACTUAL_AUDIT|HIGH 86 · SILMU_RECONSTRUCTED_CASE|HIGH 110 · UNVERIFIED|HIGH 61
MEDIUM 판정        0건
저장값 ↔ 오늘판정   MISMATCH 0
```

`PROVENANCE_BACKFILL_REPORT.md` 가 우려한 "기관명은 있으나 원문 URL 이 없는 MEDIUM 후보"는
운영에서 **0건**이었다 — 자동 승격된 흔적이 없다.

### 2.3 공개 표시 축 확인

`provenance_confidence` 의 **뷰 사용처 0건**(grep). 공개 배너 `_provenance_banner.html.erb` 는
`AuthorityPresenter#provenance_label/note/tone` 를 쓰고, 그 값은 `source_type`·`is_reconstructed` 에서 나온다.
따라서 사용자에게 "미검증인데 신뢰도 높음"으로 보이는 화면은 **없다.**

### 2.4 판정

```
TOTAL_CONTRADICTIONS  0   (모순으로 보였던 61건은 계약상 정상)
UNCHANGED             61
DOWNGRADED             0
SUPPORTED_UPGRADE      0
UNKNOWN                0
```

**아무것도 바꾸지 않았다.** "모순 0건"을 만들려고 값을 만지지 않았고, 만질 이유도 없었다.
61건의 `is_reconstructed = nil` 도 설계된 값이다 — 백필 보고서가 `false`(실제 사례로 확인)와
`nil`(미판정)을 명시적으로 구분한다.

---

## 3. P-3 — 고아 category → **운영에 없음. BEFORE 0 · AFTER 0** ✅

| 축 | 운영 실측 |
|---|---|
| `topics.category` 분포 | `contract 57 · budget 22 · duty 12 · salary 12 · travel 6 · subsidy 2 · expense 1 · property 1 · other 1` = 9종 |
| 라우트 허용값 (`topics/:key` constraint) | `contract budget expense salary subsidy property travel duty other` = 같은 9종 |
| 비ASCII category | **0건** |
| `bid-notice-requirements` 토픽 | **운영에 존재하지 않음** |

`P2_HANDOFF §4` 와 감사 02 §2.2 의 "`bid-notice-requirements` 의 `category='입찰'`" 은
**dev DB(92 topics) 기준**이었다. 운영(114 topics)에는 그 토픽 자체가 없다.
감사 문서가 §6(dev ≠ prod)을 스스로 어긴 자리다.

### 3.1 그래서 데이터는 안 고쳤다. 탐지기만 만들었다.

`bin/rake silmu:category_integrity` — 허용값 정본을 **라우트 constraint 에서 직접 읽는다**
(상수를 새로 만들면 정본이 둘이 된다. 못 읽으면 추측하지 않고 exit 1).

**양성대조(실데이터)**: dev DB 에서 실제로 잡힌다.
```
[FAIL] 라우트 밖 category 1건 — 카테고리 내비에서 고아가 된다
  ✗ bid-notice-requirements — category="입찰" (published=true)   exit 1
```
**음성대조**: 운영 9종은 전부 허용값 → 0건.
dev 데이터는 고치지 않았다 — 운영이 아니고, 스테일 스냅샷이다.

---

## 4. R1 — 기존 도구 발견성

### 4.1 감사 05 §4.3 도 정정한다

감사는 "상위 20 중 8건이 도구 미매칭"이라 했다. 실측하니 **#4·#6·#7·#12·#13·#14 는 이미 매칭되고 있었다.**
실제 미매칭 중 **도구가 그 질의를 실제로 푸는 것**만 추렸다.

### 4.2 무엇을 넣었나 (5개 도구 · **8개 낱말**)

| 도구 | 추가 keywords | intent 근거 (구현을 읽고 확인) |
|---|---|---|
| 계약방식 결정 도우미 | `한도, 수의계약한도, 소액수의` | `contract_methods/index.html.erb` 가 물품·용역 2천만/5천만·공사 종합 4억·특례기업 한도를 **실제 판정** |
| 분할계약 판단 체크리스트 | `분할발주, 분리발주` | `split_contract_checker.html.erb` 가 동일목적 분할·기준금액 회피를 판정 |
| 계약보증금 계산기 | `수입인지` | 컨트롤러·뷰가 계약금액 구간별 **인지세 자동계산**(인지세법 근거·1천만 이하 면제) |
| 보조금 정산 체크리스트 | `보조금정산` | 붙여쓰기 질의 19회인데 공백 때문에 미매칭. 도구는 실제 정산 자가점검 |
| 여비계산기 | `국외출장` | `travel_calculator.html.erb` 에 **국외 출장 옵션 실재** |

### 4.3 넣지 **않은** 것 — 근거 있는 배제

| 질의 | 왜 안 넣나 |
|---|---|
| `검수` · `검사·검수` (26회) | 기성검사 체크리스트는 **공사 기성검사**다. 물품 검수가 아니다 |
| `업무추진비`(18) · `일상경비`(36) · `겸직`(15) · `선금`(16) | 그 판정을 하는 도구가 **실제로 없다** |
| `병가` · `특별휴가` · `육아휴직` (31) | 연가일수 계산기는 **연가만** 계산한다 |

도구가 못 푸는 질의에 keyword 를 붙이면 그건 개선이 아니라 stuffing 이다.

### 4.4 BEFORE / AFTER 실측 (질의 단위)

| 질의 | BEFORE | AFTER | 발견된 도구 |
|---|---:|---:|---|
| 수의계약 한도 | 0 | **1** | 계약방식 결정 도우미 |
| 수의계약한도 | 0 | **1** | 계약방식 결정 도우미 |
| 소액수의 | 0 | **1** | 계약방식 결정 도우미 |
| 분할발주 | 0 | **1** | 분할계약 판단 체크리스트 |
| 분리 발주 | 0 | **1** | 분할계약 판단 체크리스트 |
| 수입인지 | 0 | **1** | 계약보증금 계산기 |
| 보조금정산 | 0 | **1** | 보조금 정산 체크리스트 |
| 국외출장 / 국외 | 0 | **1** | 여비계산기 |
| 검사·검수 · 검수 | 0 | 0 | **TOOL_MISSING — 의도적 미해소** |

**해소 8개 질의 · 손실 0.**

> 최초 보고서에 "7개 낱말"이라 적었으나 실제는 **8개**다(한도·수의계약한도·소액수의 3 + 분할발주·분리발주 2
> + 수입인지 1 + 보조금정산 1 + 국외출장 1). 독립검증이 diff 실물과 대조해 잡았다.

### 4.5 음성대조 (§8) — precision 이 떨어지지 않았는가

| 질의 | BEFORE | AFTER |
|---|---:|---:|
| 병가 · 병가 진단서 · 지급 기준 · 육아휴직 · 겸직 · 특별휴가 · 정보공개 처리기한 · 민원 처리기한 · 기록물 이관 · 처음 계약 맡은 신규자 | 0 | **0** |
| 계약 (넓은 질의) | 4 | **4** |
| 출장비 | 1 | **1** |
| 이월 · 전용 · 인지세 · 연말정산 · 설계변경 · 초과근무 · 수도광열비 · 집행률 | 각 1 | 각 **1** |
| **음성대조 도구노출 합계** | **5** | **5** |

`한도` 단독 질의는 **한도를 실제로 산출하는 2개**(계약방식 결정 도우미 · 예비비 한도 계산기)에만 붙는다.

### 4.6 §10 분류 — 목표는 도구 개수가 아니라 도달률

**테마 단위 (35개)**

| 분류 | BEFORE | AFTER |
|---|---:|---:|
| TOOL_DISCOVERABLE | 11 | **13** |
| TOOL_EXISTS_NOT_DISCOVERABLE | 2 | **0** |
| TOOL_MISSING | 22 | 22 |

**질의 단위**: EXISTS_NOT_DISCOVERABLE 8 → **0**.

TOOL_MISSING 22개는 keyword 로 해소되지 않는다 — **다음 Phase 의 실제 제작 대상**이다.
상위: 기간제(38) · 일상경비(36) · 휴가(31) · 검사검수(26) · 업무추진비(18) · 선금(16) · 겸직(15).

### 4.7 ⚠️ 아직 운영에 반영되지 않았다

`tools_registry` 는 **코드**다. keywords 변경은 **배포 전까지 운영 검색에 나타나지 않는다.**
이번 세션은 배포하지 않았다(§16 범위 밖). P-1 FAQ 복구만 데이터 정정으로 즉시 반영됐다.

---

## 5. P1.6 회귀 — 침범 0 · 정밀도 유지

### 5.1 동결 파일 (vs `f7fb1be`)

```
app/services/search_query_parser.rb                 UNCHANGED
app/models/topic.rb                                 UNCHANGED
app/views/shared/_solution_status.html.erb          UNCHANGED
app/views/layouts/_nav_v2.html.erb                  UNCHANGED
app/views/home/index.html.erb                       UNCHANGED
test/models/topic_search_test.rb                    UNCHANGED
test/services/search_query_parser_test.rb           UNCHANGED
```
`SEARCH_CODE_TOUCHED = NO` → 654-query 지문 재측정 불필요.

### 5.2 Answer-First 정밀도 가드 3종 — **복구 후 운영에서 재실행**

FAQ 9건이 후보 풀에 새로 들어왔으므로 오승격 위험을 실제로 봐야 한다.

| 질의 | 운영 "바로 답" | 판정 |
|---|---|---|
| `차비 지급 기준` | 없음 | **PASS** (숙박비 오승격 없음) |
| `차비 얼마` | 없음 | **PASS** (차비⊂주차비 없음) |
| `지급 기준` | 없음 | **PASS** (고유 토큰 0 → 정직한 nil) |

### 5.3 task case 5종 (운영, 복구 후)

| 질의 | 토픽 | 바로 답 |
|---|---:|---|
| 수의계약 한도 | 6 | 수의계약 한도 금액에 부가세가 포함되나요? |
| 병가 진단서 | 1 | 병가에 진단서는 언제부터 제출해야 하나요? |
| 출장비 | 6 | 자가용으로 출장 시 여비는 어떻게 받나요? |
| 정보공개 처리기한 | 1 | — (03 문서의 NO_DIRECT_ANSWER 그대로) |
| 처음 계약 맡은 신규자 | 0 | — (WEAK_CONTENT 그대로) |

---

## 6. 테스트

```
targeted   67 runs · 130 assertions · 0F · 0E · 0 skips
full       497 runs · 3,138 assertions · 0F · 0E · 14 skips
           (P1.6 기준선 430/3,008/14 skips → 신규 67 runs·130 assertions. skip 14 그대로)
RuboCop    6 files inspected, no offenses
```

### 6.1 뮤테이션 대조 — green 은 증거가 아니다

| # | 무력화한 방어 | 죽은 테스트 | 판정 |
|---|---|---:|---|
| M1 | `bad_shape` 모양 검사 제거 | 6 failures | **KILLED** |
| M2 | `inspect_to_json` 의 `in_string` 추적 제거 | 2 failures (문자열 안 `=>` 보존 포함) | **KILLED** |
| M3 | keywords 추가분 되돌림 | 10 failures | **KILLED** |
| M4 | `classify` 를 항상 `array_ok` 로 | 3 failures | **KILLED** |

| M5 | `in_source?` 를 날문자열 `include?` 로 되돌림 | 2 failures | **KILLED** |
| M6 | Array 원소 검사 제거 | 3 failures | **KILLED** |
| M7 | `분할발주/분리발주` keywords 되돌림 | 4 failures | **KILLED** |
| M8 | category 탐지 쿼리를 `Topic.none` 으로 | 2 failures | **KILLED** |

`8/8 KILLED · SURVIVED 0`. (M5~M8 은 §9 독립검증 지적을 수리한 뒤 그 수리를 지키는 방어로 추가한 것들이다.)

> ⚠️ M2 는 **1차 시도에서 치환이 안 먹어 "SURVIVED" 로 보였다.**
> `grep -c MUTANT` = 0 으로 **뮤턴트가 안 박힌 것**을 확인하고 재적용했더니 KILLED 였다.
> 적용되지 않은 뮤테이션은 생존처럼 보인다 — 뮤테이션마다 "실제로 박혔는가"를 먼저 대조해야 한다.

### 6.2 양성/음성 대조 요약

| 검사기 | 양성 (잡아야 함) | 음성 (잡으면 안 됨) |
|---|---|---|
| FAQ payload | 깨진 payload 9종 전건 거부 | Array·정상 JSON·inspect 문자열 통과 |
| FAQ 저장형태 | 심어둔 STRING_BROKEN·STRING_PARSEABLE 검출 | 정상 배열·빈 FAQ 는 결함 아님 |
| category | dev 실데이터 `입찰` 1건 검출 + exit 1 | 허용값 9종 통과 |
| 도구 발견성 | 8개 질의 도구 발견 | 무관 질의 12개 도구 0건 · 넓은 질의 개수 불변 |

---

## 6.3 독립 검증 (gemini critic) — **CONDITIONAL_GO · 지적 7건 전건 수리**

kimi 자기검증을 금지하고, codex-critic 이 같은 openai 쿼터로 unavailable 이므로 gemini 를 검증 레인으로 썼다.
**지적 7건을 내가 하나씩 재현해 전건 확인한 뒤 고쳤다.**

| 심각도 | 지적 | 내가 재현한 결과 | 조치 |
|---|---|---|---|
| **HIGH** | `preserves_source?` 가 이스케이프·개행에서 오작동 — 정상 복원을 `content_drift` 로 오판해 건너뛴다 | **재현됨**. `\"`·`\n` 포함 시 `false` | `in_source?` 신설 — 값을 JSON 이스케이프 표현으로도 대조 |
| **HIGH** | 마이그레이션에 트랜잭션이 없어 중간 실패 시 **부분 적용**이 남는다 | 코드상 확인 | 쓰기를 `Topic.transaction` 으로 묶음 |
| **MEDIUM** | 저작건수 불변식이 **동어반복** — 같은 파서로 재서 파서가 항목을 흘리면 안 보인다 | 논리 확인 | `independent_authored_count`(원문 `"question"` 출현 수, 파서 무관)로 교체 + 도달수 감소 가드 추가 |
| **MEDIUM** | 보고서 "7개 낱말" ↔ diff 실물 **8개** | **재현됨** | 보고서·커밋 정정 |
| **MEDIUM** | `분할발주` 추가로 **`발주` 단독 질의**가 새로 매칭(0→1) · 테스트 미포함 | **재현됨** | 매칭이 substring AND 인 한 회피 불가 → **받아들이되 BASELINE 테스트로 고정**하고 사유 명시 |
| **LOW** | Array 입력은 원소 검사를 건너뛰어 `[1,2,3]` 도 통과 | **재현됨** | `call`·`classify` 가 배열 원소도 검사 · `:array_malformed` 신설 · lint exit 1 대상 편입 |
| **LOW** | category 테스트가 **동어반복**(로컬 배열만 검사) | 코드상 확인 | 라우트 정본 + ActiveRecord 쿼리를 실제로 태우는 양성·음성 3케이스로 교체 |

**감사 3건 정정에 대한 critic 재검증**: C-1·C-2·C-3 **전부 타당**하다고 독립 확인됐다.

> 지적 중 HIGH 2건은 **운영 데이터를 해치지는 않았다** — 운영 payload 4건에 이스케이프·개행이 없어
> 4/4 정상 적용됐고, 실패가 없어 부분 적용도 발생하지 않았다. 그러나 **가드가 틀린 채로 남아 있었다면**
> 다음 payload에서 조용히 건너뛰거나 절반만 적용됐을 것이다.

## 7. 변이 회계 (§13)

| 대상 | EXPECTED | ACTUAL |
|---|---|---|
| P-1 FAQ 구조 정정 (운영) | 4 토픽 `faqs` | **4** (`bid-announcement`·`bidding`·`estimated-price`·`late-penalty`) |
| P-2 provenance 정정 | 증거에 따름 | **0** (결함 아님) |
| P-3 category 정정 | 증거에 따름 | **0** (운영 무결) |
| R1 tool keywords (repo) | 5 도구 | **5** |
| Topic/Guide/AuditCase **본문** | 0 | **0** |
| `Topic.updated_at` | 0 | **0** (`update_column`) |
| Guide / AuditCase / SearchLog | 0 | **0** (건수·max(updated_at) 불변) |
| Authority/Freshness 코어 | 0 | **0** (모델·잡·recurring.yml 무변경) |
| Freshness scheduler | OFF | **OFF** |
| **UNEXPECTED_MUTATION** | 0 | **0** |

---

## 8. 남은 것

1. **배포** — keywords·lint·테스트는 배포 전까지 운영에 없다. 별도 승인 사안
2. `bin/rake silmu:faq_integrity` 를 CI·배포 후 체크에 붙일지 판단
3. TOOL_MISSING 22 테마 — 07 문서의 Functional Asset 후보로 이어진다
4. dev DB 는 스테일(92 topics)이라 STRING_BROKEN 을 재현하지 못한다.
   그래서 변환기는 **운영 payload 4건을 읽기 전용으로 떠서** 오프라인 검증했고,
   테스트는 깨진 payload 를 직접 심어 검사한다
