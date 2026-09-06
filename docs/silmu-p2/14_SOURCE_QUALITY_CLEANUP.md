# 14 — 원천 품질 정정 (CPSC-P3D-001 · CPEB-P3C-001)

> 2026-09-06 · branch `fix/silmu-source-quality-cleanup-0906` · commit `f8adc0a` (base `f10ad5c`)
> **SOURCE_CORRECTED · TESTED · PRODUCTION_READY** — 배포 0 · merge 0 · 운영 DB 쓰기 0 · command_center 쓰기 0.

---

## 0. 판정 요약

command_center 가 넘긴 두 blocker 를 법제처 정본과 1:1 재대조했다.
**지목 4개 항목 중 2개는 사실이 아니었고, 지목되지 않은 결함 5종이 실재했다.**

지목이 어긋난 이유는 하나다 — P3D 가 "원문"이라고 부른 것이 실은 **silmu 자신이 쓴
`decree_content`** 였다. 자기 콘텐츠를 자기 콘텐츠의 진리원으로 삼으면 방향이 뒤집힌다.
실제로는 요약문이 옳았고 `decree_content` 쪽이 틀려 있었다.

---

## 1. 정본 (VERIFIED_AT 2026-09-06, law.go.kr 실측)

| SOURCE | EFFECTIVE_DATE | 공포 |
|---|---|---|
| 지방자치단체를 당사자로 하는 계약에 관한 법률 | 시행 2024. 2. 17. | 법률 제19634호, 2023. 8. 16., 타법개정 |
| 같은 법 시행령 | 시행 2026. 6. 3. | 대통령령 제36338호, 2026. 5. 19., 타법개정 |

SOURCE_LOCATOR
- `https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률` (iframe `lsInfoP.do?lsiSeq=253973&efYd=20240217`)
- `https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률시행령`
- 교차검증: 법제처 찾기쉬운 생활법령정보 `easylaw.go.kr` csmSeq=1302·1693 / 전북교육청 지방계약법령집(HWP) §14·§49·§50 원문 일치

### ARTICLE / PARAGRAPH 원문

**법 §14①** — 계약의 **목적, 계약금액, 이행기간, 계약보증금, 위험부담, 지연배상금(遲延賠償金)**, 그 밖에
필요한 사항을 명백히 적은 계약서를 작성하여야 한다. **다만, 대통령령으로 정하는 경우에는 계약서의
작성을 생략할 수 있다.**

**법 §14②** — 천재지변 등 대통령령으로 정하는 경우를 제외하고는 행정안전부장관이 지정하는
정보처리장치를 이용하여 「전자서명법」 제2조제1호에 따른 **전자문서에 의한 계약서를 작성하여야 한다.**

**법 §14③** — 기명·날인하거나 서명(전자서명 포함)함으로써 계약이 확정된다.

**시행령 §49(계약서의 작성)** — 법 제14조제1항에 따라 작성하는 계약서의 **서식과 그 밖에 필요한 사항은
행정안전부령으로 정한다.** ← 기재사항 조문이 아니다.

**시행령 §50①(계약서 작성의 생략 등)** — 법 §14① **단서**에 따른 생략 사유 5개 호:
1. 계약금액이 **5천만원 이하**인 계약 *(계약 종류 불문 단일 기준 — "공사 1억원" 은 부존재)*
2. 경매에 부치는 경우
3. 물품을 매각할 때 매수인이 즉시 대금을 내고 그 물품을 인수하는 경우
4. 국가기관과 계약 또는 다른 지방자치단체와 계약
5. 전기·가스·수도의 공급계약 등 성질상 계약서를 작성할 필요가 없는 경우

**시행령 §50②** — 법 §14②의 "천재지변 등"이란 천재지변·전산장애 또는 그 밖의 부득이한 사유로
정보처리장치를 이용할 수 없는 경우.

**시행령 §35③(공사입찰·현장설명 미실시)** — 10억 미만 7일 / 10억~50억 15일 /
**50억~고시금액 30일** / 고시금액 이상 40일
**시행령 §35④** — 재공고·예산 조기집행·긴급 등 5일
**시행령 §35⑤(규격·기술입찰, 협상에 의한 계약, 경쟁적 대화)** — **1억 미만 10일** / 1억~10억 20일 / 10억 이상 40일

---

## 2. CPSC-P3D-001 — 계약서 작성

STATUS **RESOLVED (부분 기각)**

| # | 지목 내용 | 판정 | 근거 |
|---|---|---|---|
| A | "지연배상금"은 §49 "지체상금"의 오기 | **기각** | 법 §14① 정본 용어 = 지연배상금(遲延賠償金). 지체상금은 국가계약법(시행령 §74) 용어 |
| B | §49의 "위험부담" 누락 | **인용** | 요약문에 위험부담이 빠져 있었다 |
| C | "전자문서 원칙"에 근거 없음 | **기각** | 법 §14② 그 자체. 예외는 시행령 §50②가 정의 |
| D | §50 계약서 생략 조건 누락 | **인용** | 5개 호 중 2개만 서술 + 부존재 기준 포함 |

### 지목되지 않았으나 실재한 결함 (ROOT_CAUSES)

1. **법 §14② 오기재** — "다만, 대통령령으로 정하는 경우에는 계약서 작성을 생략할 수 있다"로 적혀
   있었다. 생략 위임은 §14① **단서**이고 §14②는 전자문서 조항이다.
2. **시행령 §49 오귀속** — 기재사항 8개 목록을 §49 아래 두었다. §49는 서식 위임 조항이며,
   기재사항은 법 §14①이 직접 정한다.
3. **"공사 1억원" 부존재 기준** — §50①1은 계약 종류를 구분하지 않는 5천만원 단일 기준이다.
   같은 오류가 4곳(`decree_content`·`qa_content`·`faqs`·`subtopics`)에 있었다.
4. **§50① 2개 호 누락** — 3호(물품매각 즉시대금)·4호(국가기관·다른 지자체).
5. **verification_source 가 위 오귀속을 인증** — "§49(기재: …지체상금)·§50(생략: 물품/용역 5천만·공사
   1억 이하)"를 `law.go.kr 1:1 대조`로 기록하고 있었다. 메타데이터가 원문보다 좁고 틀렸다.

### BEFORE / AFTER (대표)

| 위치 | BEFORE | AFTER | WHY |
|---|---|---|---|
| `topic_contract_execution.rb` law | `② 다만, …계약서 작성을 **생략**할 수 있다.` | `② …전자문서에 의한 계약서를 작성하여야 한다.` + `①` 단서로 생략 이동 | 법 §14②·§14① 단서 |
| 〃 decree §49 | `계약서에 기재해야 할 사항: 1.목적 … 6.지체상금` | `계약서의 서식…행정안전부령으로 정한다` + 기재사항은 법 §14① 이라는 주기 | 시행령 §49 |
| 〃 decree §50 | `5천만원 이하(물품·용역) / 1억원 이하(공사) / 공급계약 / 경매` | §50① 5개 호 전부 + §50② | 시행령 §50 |
| 〃 qa/faqs/`subtopics.rb` | `공사는 1억원 이하` | `5천만원 이하이면 공사·물품·용역 구분 없이` | 시행령 §50①1 |
| `zz_topic_verification_…rb` | `§49(기재:…지체상금)·§50(…공사 1억)` | `§14①(기재…지연배상금)…§49(서식 위임)·§50①(5개 호)` | 위 전부 |
| `topic_fold_summary_…rb` | `계약보증금·지연배상금을 필수 기재` | `계약보증금·**위험부담**·지연배상금을 필수 기재` | 법 §14① (지목 B) |

**정정하지 않은 것** — 요약문의 `지연배상금`과 `전자문서로 작성하는 것이 원칙`은 정본상 옳다.
과잉정정을 막기 위해 회귀 뮤테이션(M10·M11)으로 고정했다.

### TOOL_CANDIDATE_14_2

STATUS **NO_CHANGE_REQUIRED**

가설("§14②는 전자문서 조항이 아니라 계약서 작성 생략 위임 조항일 것")은 **성립하지 않는다.**
§14②는 전자문서 조항이 맞다. 따라서 §14②를 전자계약 근거로 인용한 자산
(`topic_quick_stats_backfill_2026_06_03_batch5/6/7.rb`의 `지방계약법 제14조제2항(천재지변 등 예외)`,
`topic_e_bidding.rb`)은 **정확하며 고치지 않았다.** 오히려 §14②를 "생략 조항"으로 적은
`topic_contract_execution.rb` 쪽이 틀렸고 그것을 고쳤다.

집행기준의 "추정가격 2천만원 초과 전자계약 의무"는 `rule_content`(집행기준 절)에 그대로 두어
법 §14② 계약서 작성 원칙과 섞지 않았다.

---

## 3. CPEB-P3C-001 — 입찰공고 기간

STATUS **RESOLVED** · VERDICT **BOTH_CONTEXTUAL**

두 진술은 **서로 다른 공고유형**이라 모순이 아니었다. 다만 **양쪽 다 자기 조문 기준으로 틀려 있었고**,
적용범위 표시가 없어 모순처럼 읽혔다.

| | TABLE_SCOPE | HOWTO_SCOPE |
|---|---|---|
| 조문 | 시행령 **§35③** | 시행령 **§35⑤** |
| 적용 | 공사입찰 + 현장설명 **미실시** | 규격·기술입찰, 협상에 의한 계약, 경쟁적 대화 |
| 금액축 | 10억 / 50억 / 고시금액 | 1억 / 10억 |
| 기존 오류 | `50억 이상 40일` — §35③3(50억~고시금액 **30일**)과 4호를 하나로 뭉갬 | `추정가격 1억 이상 시 10일` — §35⑤1은 1억 **미만**이 10일 (역전) |
| 시행시점 차이 | 없음(§35 전문개정 2010. 7. 26. 이후 해당 항 개정 없음) | 없음 |

**왜 남아 있었나** — 2026-06-15 `topic_content_fix_2026_06_15_bid_period_v2.rb` 가 30일 구간을
복원했지만 `decree_content`·`practical_tips` 만 고쳤다. `summary`·`howto_steps`·`quick_stats`·
`regulation_verifier` 4곳은 옛 값 그대로였다. 부분 정정의 잔재다.

`regulation_verifier.rb` 는 특히 위험했다 — 검증 게이트가 **틀린 기준을 정답으로 강제**하고 있어,
정정된 콘텐츠를 오류로 지적하게 되어 있었다.

---

## 4. 회귀 · 뮤테이션

```
TESTS       508 runs · 3336 assertions · 0 failures · 0 errors · 14 skips
            (baseline 497/3138/0F/0E/14S — 신규 11 runs 전부 이번 회귀)
RUBOCOP     변경 11파일 0 offenses (리포 잔여 143건은 18개 선재 파일 · 교집합 0)
MUTATION    20/20 KILLED · NOT_APPLIED 0
```

첫 라운드는 **16/20** 이었다. 생존 4건이 실제 결함을 가리켰다:
- M15·M17 — `50억 이상`과 `40일` 사이에 jsonb 라벨·괄호가 끼는 표기를 탐지기가 못 봤다
- M9 — 요약문의 위험부담 누락을 다른 파일에서만 단언하고 있었다
- M20 — `§50①3` 삭제를 "낱말 포함" 검사가 못 봤다(같은 표현이 `qa_content` 에 남아 있어서)

탐지기를 넓히자 §53 **계약보증금 면제**의 "공사 추정가격 1억원 이하"를 오검출했다 —
같은 문자열, 다른 조문이다. 문맥 조건(`계약서|생략|§50` 요구, `면제` 배제)을 넣고
**그 음성 대조도 회귀로 고정**했다.

양성 대조는 정정 전 원문을 그대로 표본으로 쓴다 — 문맥을 떼어내면 문맥 조건이 헛돌기 때문이다.

---

## 5. command_center 인계 (DB 수정 없음)

P3C/P3D runner 가 source fingerprint 변경을 감지해 **스스로 재평가**하도록 아래만 남긴다.
command_center DB 는 손대지 않았다 (`COMMAND_CENTER_WRITE = 0`).

```yaml
changed_source:
  - silmu.topics#25 (slug: contract-execution)   # law_content · decree_content · summary
                                                 # · qa_content · faqs · practical_tips · verification_source
  - silmu.topics#24 (slug: bid-announcement)      # summary · howto_steps · quick_stats
  - silmu.topics    (slug: bidding)               # howto_steps
locator:
  repo: /Users/seong/project/silmu
  branch: fix/silmu-source-quality-cleanup-0906
  commit: f8adc0a
  base:   f10ad5c
  files:
    - db/seeds/topic_contract_execution.rb
    - db/seeds/topic_fold_summary_2026_06_05_batch2.rb
    - db/seeds/zz_topic_verification_2026_06_09_batch2.rb
    - db/seeds/subtopics.rb
    - db/seeds/howto_steps.rb
    - db/seeds/quick_stats_sprint3.rb
    - db/seeds/topic_howto_backfill_2026_06_15_batch2.rb
    - db/seeds/topic_source_quality_fix_2026_09_06.rb   # 운영 반영용(멱등)
    - app/services/regulation_verifier.rb
    - app/services/contract_document_service.rb
    - app/views/guides/contract_flow.html.erb
verified_at: 2026-09-06
revision:
  statute: "법률 제19634호 (시행 2024-02-17)"
  decree:  "대통령령 제36338호 (시행 2026-06-03)"
blockers:
  CPSC-P3D-001:
    status: RESOLVED_PARTIALLY_REJECTED
    upheld:   [위험부담 누락, §50 생략조건 누락]
    rejected: [지연배상금→지체상금 오기 주장, 전자문서 원칙 무근거 주장]
    note: "P3D 가 원문으로 삼은 것은 silmu 의 decree_content 였다. 정본은 요약문 쪽이 옳다."
  CPEB-P3C-001:
    status: RESOLVED
    verdict: BOTH_CONTEXTUAL
    note: "§35③ vs §35⑤ — 다른 공고유형. 모순 아님. 단 양쪽 다 자기 기준으로 오류가 있어 정정."
```

⚠️ **운영(silmu.kr) 콘텐츠는 아직 옛 값이다.** 위 정정은 원천(git)에만 반영됐다.
운영 반영은 아래를 실행해야 하며, 이 세션은 실행하지 않았다.

```bash
kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_source_quality_fix_2026_09_06.rb})"'
```

---

## 6. 이번 정정 범위 밖에서 발견된 것 (수정하지 않음 · 보고만)

전수 재작성 금지 원칙에 따라 손대지 않았다. 판단이 필요한 항목이다.

1. **`app/models/exam_curriculum/subject2.rb` · `app/models/exam_keyword_details.rb`** —
   `50억 이상 40일` 잔존. 시험 콘텐츠는 문항 정답과 결속돼 있어 함께 고치면 정답이 어긋날 수 있다.
   별도 판정 필요.
2. **`app/views/guides/contract_flow.html.erb` (construction-3 docs)** —
   `공사 추정가격 1억원 이하 면제 가능`(계약보증금 면제). §50 사안이 아니라 §53 사안이라
   이번 범위 밖이나, 최근 이력(`6035512` 계약보증금 면제 5천만원=상시 §53 재정정)과 어긋날
   가능성이 있어 확인이 필요하다.
3. **`contract_flow.html.erb` / `contract_document_service.rb` 의 구어체 "지체상금"** —
   조문 인용이 아니라 통칭이라 두었다. 지방계약 문맥의 법정 용어는 지연배상금이다.
4. **`db/seeds/construction_contract_part1.rb`** — 현장설명 기간 `50억 이상 33일`(§15③④).
   §35 와 다른 조문이라 이번 대조 대상이 아니었다.
