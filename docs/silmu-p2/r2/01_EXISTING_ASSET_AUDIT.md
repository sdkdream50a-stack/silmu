# 01 — 기존 자산 실측 (Phase A)

> §6: 새 코드를 쓰기 전에 실제 기존 자산부터 조사. §21: 하드코딩 전수 탐색.
> 모든 수치는 **운영 revision `ce62d2e`** 에서 read-only 로 측정했다 (2026-09-06 12:28 KST · 콘텐츠 변이 0).
> 재측정 = `_measure/r2_asset_audit.rb` · `_measure/r2_reachability.rb`

---

## 0. 운영 baseline (R1 이후)

```
PRODUCTION_REVISION   ce62d2ebee5e465bb230cccf9134e2ada9c71d20
/up                   200
Topic 114 (published 114) · Guide 103 · AuditCase 257
FAQ 저작 474 · 도달 474 · LOST 0 · NON_ARRAY 0     ← R1 frozen baseline (§3) 재확인
SearchLog 2,207        ← 2,206 대비 +1. 12:10~12:15 KST 45건은 R1 검증 트래픽이라 수요로 세지 않는다 (§5)
Tool 39
```

## 1. 두 도구의 실제 구조

| | 계약방식 결정 도우미 | 분할계약 판단 체크리스트 |
|---|---|---|
| route | `GET /tools/contract-method` + `POST /contract-methods/determine` | `GET /tools/split-contract-checker` |
| 판정 위치 | `ContractMethodService` (서버) | **뷰 안 JavaScript** (`split_contract_checker.html.erb`) |
| 규칙 원천 | `config/contract_thresholds.yml` | JS 리터럴 |
| 입력 | 계약유형 · 추정가격 · 특례기업 | 계약유형 · 이번 금액 · 이전 계약 · 체크박스 5 |
| 출력 | method / method_detail / basis / note / warnings / tips | 위험등급 4단계 + 권장조치 |
| **테스트** | **0건** | **0건** |
| 기관 범위 표시 | 없음 | 없음 |
| 시행일 표시 | 없음 | 없음 |

> `grep -rn "ContractMethodService" test/` → **0건.** 관측 1·2위 계약 질의를 받는 판단 엔진에
> 테스트가 하나도 없었다. 분할 체크리스트는 뷰 JS라 테스트를 걸 자리 자체가 없었다.

### 같은 규칙의 세 번째 구현

`EstimatedPriceService` 도 `PRIVATE_CONTRACT_THRESHOLDS` · `CONSTRUCTION_THRESHOLDS` 로
같은 §25 판단을 따로 하고 있다. 세 구현이 서로 다른 답을 낸다:

| 상황 | ContractMethodService | EstimatedPriceService | split checker (JS) |
|---|---|---|---|
| 물품 3천만·일반업체 | **"수의계약 / 2인 이상 견적"** | "일반 기업은 입찰" | — |
| 공사 종류 미지정 | (UI가 3종 강제) | `undetermined` ✅ | 4종 select |
| 공사 4억의 의미 | 2인 이상 견적 한도 | 수의계약 한도 | **"1인 수의계약 기준"** ❌ |

`EstimatedPriceService` 는 이미 "종류를 모르면 단정하지 않는다"를 구현하고 테스트까지 갖고 있다
(`test/integration/tool_accuracy_endpoints_test.rb`). R2 는 그 태도를 계약방식 도구로 옮긴 것이다.

## 2. 관련 콘텐츠 (운영 실측)

| slug | 제목 | FAQ | howto | 기준일 | target_agency | effective_at |
|---|---|---:|---:|---|---|---|
| `private-contract-limit` | 수의계약 한도 | 2 | **0** | 2026.04.29 | `{}` | — |
| `split-contract` | 분할계약 금지 | 5 | **0** | 2026.06.04 | `{}` | — |
| `split-contract-prohibition` | 분할발주 금지 | 4 | **0** | 2026.06.04 | `{}` | — |
| `small-amount-contract` | 소액수의 | 2 | **0** | 2026.06.04 | `{}` | — |
| `emergency-contract` | 긴급수의 | 2 | **0** | 2026.04.29 | `{}` | — |
| `quote-collection-guide` | 비교견적서 수집 방법 | 4 | **0** | 2026.04.29 | `{}` | — |

AuditCase 총 257건 중 분할·수의계약 관련 다수 존재(`_data/asset_audit_prod.json`).

> **감사 정정 1** — 10 로드맵의 R2 항목은 `split-contract-prohibition` 에 표제 FAQ 를 추가하라고
> 적었는데, 로컬 dev DB 에는 그 토픽이 **없다.** 운영에는 **있다.** dev 기준으로 봤다면
> "토픽 없음"이라는 틀린 전제로 새 글을 썼을 것이다 — R1 의 P-3 과 같은 함정이다.

## 3. 검색 도달성 실측 (운영 · BEFORE)

| 질의 | Topic | Tool | 바로 답 |
|---|---:|---:|---|
| 수의계약 한도 | 4 | 1 | "한도 금액에 **부가세**가 포함되나요?" ← 곁가지 |
| 3000만원 물품 수의계약 가능한가 | 3 | **0** | — |
| 5000만원 용역 수의계약 가능한가 | 3 | **0** | "**설계용역과 공사를 합산**해서…" ← 다른 질문 |
| 공사를 나눠 계약해도 되나 | **0** | **0** | — |
| 같은 물품을 여러 번 나눠 사도 되나 | **0** | **0** | — |
| 분리발주와 분할발주의 차이 | **0** | **0** | — |
| 처음 계약을 맡았어요 | 4 | 0 | — |

양성대조(같은 프로브가 답을 잡는가): `병가 진단서` → 답 반환 ✅ · `여비계산` → 도구 1 ✅.

> ⚠️ 이 표는 **두 번째** 측정이다. 첫 측정은 `Topic.answer_for(q)` 를 1인자로 불렀는데
> 실제 시그니처는 `answer_for(query, topics)` 라 `rescue nil` 에 삼켜져 **전 질의 "답 없음"**
> 이라는 거짓 음성이 나왔다. 양성대조가 없었으면 그대로 보고했을 것이다.

## 4. 하드코딩 전수 (§21)

`_data/hardcoded_audit.json` — 103건.

| 파일 | 건수 | 분류 |
|---|---:|---|
| `config/contract_thresholds.yml` | 38 | §25·§30 금액 = **SOURCE_VERIFIED**(§5에서 조문 대조) / 낙찰하한율 = **LEGACY_UNVERIFIED** |
| `app/services/estimated_price_service.rb` | 23 | 원가계산 비율 = **LEGACY_UNVERIFIED** (R2 범위 밖) |
| `config/contract_decision_rules.yml` | 19 | **SOURCE_VERIFIED** (전건 조문 인용 보유) |
| `app/views/contract_methods/index.html.erb` | 12 | **DISPLAY_ONLY** (참고표) |
| `app/services/contract_method_service.rb` | 7 | 특례 임계 = **SOURCE_VERIFIED**(§30 대조) |
| `app/controllers/chatbot_controller.rb` | 4 | **DERIVED** (별도 계산 경로) |
| `app/views/tools/split_contract_checker.html.erb` | **0** | R2 에서 서버로 이동 (이전엔 최다 보유) |

R2 가 **실제로 수리한** 것은 §5 의 결함 목록뿐이다. 낙찰하한율(89.745% 등)·원가계산 비율은
근거를 확인하지 않았고 R2 판정 경로에도 쓰이지 않으므로 **LEGACY_UNVERIFIED 로 분류만** 하고
손대지 않았다(§21 후단 · §3 외과적 변경).

## 5. 확정 결함 (조문 대조 결과)

근거 = `_data/decree_articles_raw.json` · `_data/decree_7_28_raw.json` (법제처 API 원문).

| # | 결함 | 조문 | 심각도 |
|---|---|---|---|
| **D-1** | 물품·용역 2천만 초과에서 상대방 자격을 묻지 않고 **"수의계약"** 이라고 단정. 같은 응답의 `special_condition` 은 "일반 업체는 2천만원 초과 시 경쟁입찰 대상"이라고 **반대로** 적혀 있었다 | §25①5호나목 | **CRITICAL** |
| **D-2** | `cooperative: 협동조합` 을 특례 상대방으로 제시. 조문이 가리키는 것은 **사회적협동조합**(협동조합기본법 §2제3호)이다 — 자격 없는 상대방과의 수의계약을 가능하다고 안내 | §25①5호바목 4) | **CRITICAL** |
| **D-3** | **청년창업기업**(다목·5천만 상한)·**소기업/소상공인**(라목·1억 상한)이 선택지에 없음 | §25①5호다·라목 | HIGH |
| **D-4** | 사회적기업·사회적협동조합·자활기업·마을기업의 **취약계층 고용비율** 단서 미표시 | §25①5호바목 단서 · §30①2호나목 | HIGH |
| **D-5** | 판단 보류 상태 없음. 상대방 미상도 확정 결론을 냄 | — | HIGH |
| **D-6** | §25 는 8개 호인데 도구는 **5호(금액)만** 구현. 긴급·경쟁불가 등은 표현 불가 | §25①1~4·6~8호 | MEDIUM |
| **D-7** | 적용 기관 범위 비표시. 지방계약법 전용인데 국가기관·공공기관 이용자에게 그대로 답함 | — | HIGH |
| **D-8** | 분할 체크리스트가 **물품·용역** 분할의 근거로 **§77**(공사 분할계약 금지)을 인용 | §77 표제·본문 | **CRITICAL** |
| **D-9** | 합산 기간 **"최근 3개월"** — 조문은 **12개월/회계연도** | §7제2호 가·나목 | **CRITICAL** |
| **D-10** | 위험도 = `체크 3개 이상`/`2개 이상` — 공식 근거 없는 임의 점수 | (근거 없음) | HIGH |
| **D-11** | 적법한 분리(§77①1~3호) 경로 없음. 법령상 분리발주까지 위험으로 표시 | §77①1~3호 | HIGH |
| **D-12** | §77② 계획단계 검토의무 · §77④ 보고의무 미안내 | §77②·④ | MEDIUM |
| **D-13** | "낮음" 결과가 "**수의계약 가능**"이라고 단정 | — | HIGH |
| **D-14** | 공사 4억/2억/1.6억을 **"1인 수의계약 기준"** 이라 표기. 1인 견적은 §30 소관(2천만/특례 5천만) | §25①5호가목 vs §30①2호 | HIGH |
| **D-15** | 두 도구 모두 **테스트 0건** | — | HIGH |

> **§7제2호가 이 감사의 핵심 발견이다.** 물품·용역 분할은 "금지"가 아니라 **추정가격 합산 산정**으로
> 규율된다. 도구는 금지 조항(§77)을 잘못 인용하면서 정작 실제로 적용되는 합산 규칙을 놓쳤고,
> 그 결과 합산 기간을 조문에 없는 3개월로 잡았다. 구조를 잘못 알면 임의 기준이 생긴다.

> **§28 「분할수의계약」** 은 §25①6호가목·§26·§27 한정 **허용** 규정이다. 금지 조항과 혼동하지 않도록
> 규칙집에 별도로 적어 두었다.
