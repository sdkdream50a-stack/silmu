# 10 — CONTENT REVENUE 인계 (문서상 identity 만)

> §25: `command_center` **무수정**. OSMU · 파생 콘텐츠 생성 **금지**. Naver/Shorts 파생 **금지**.
> 이 문서는 **식별자와 인터페이스만** 남긴다. 실제 생성은 하지 않았고, 하지 않을 것을 명시한다.

---

## 1. 이번에 만든 자산의 identity

| asset_id | 종류 | 표면 | 성격 |
|---|---|---|---|
| `silmu.rules.contract_decision` | **CanonicalSourceAsset** | `config/contract_decision_rules.yml` | 조문 원문에서 파생된 규칙집. 모든 판정의 단일 출처 |
| `silmu.tool.contract_method` | **DecisionWizard** | `/tools/contract-method` | 수의계약 가능성 + 견적요건 판정 |
| `silmu.tool.split_contract_checker` | **DecisionWizard** | `/tools/split-contract-checker` | 분할발주 위험 판정 |
| `silmu.topic.private_contract_limit` | **FunctionalAsset**(예정) | `topics/private-contract-limit` | 05 문서 사양. **미반영** |
| `silmu.topic.split_contract_prohibition` | **FunctionalAsset**(예정) | `topics/split-contract-prohibition` | 〃 |

`DerivativeAsset` — **0건.** 만들지 않았다.

## 2. 인터페이스 (읽기 전용)

향후 소비자가 쓸 수 있는 접점. 이번 세션에 소비자를 만들지 않았다.

```
ContractDecision::RuleSet.current
  .sources                → 출처별 title · effective_from · verified_at · url
  .citation(key, locator) → 표시용 근거 1건

ContractDecision::PrivateContractEvaluator.call(...).to_h
ContractDecision::SplitProcurementEvaluator.call(...).to_h
  → state · headline · matched_rule · legal_basis · unresolved_factors · next_actions

POST /contract-methods/determine
POST /tools/split-contract-checker/evaluate
```

`legal_basis` 가 `effective_from` 을 갖고 있어, 조문이 개정되면 **어느 판정이 낡았는지**
소비자가 스스로 알 수 있다. 이게 이 자산이 파생물보다 오래 사는 이유다.

## 3. 하지 않은 것 — 명시

| 항목 | 상태 |
|---|---|
| `command_center` 수정 | **0** |
| OSMU 파이프라인 연결 | **하지 않음** |
| Naver 블로그 파생 원고 | **0** |
| Shorts / 영상 파생 | **0** |
| 자동 발행 | AUTO_PUBLISH = OFF |
| 외부 채널 송출 | 0 |

## 4. Experience Provenance (§26)

이번 산출물에 포함된 실무 문장의 출처:

| 유형 | 사용 | 예 |
|---|---|---|
| `OFFICIAL_CASE` | ✅ | 조문 인용 전건 (법제처 API 원문) |
| `FIRST_PARTY_DATA` | ✅ | 운영 실측 수치 (도달성·콘텐츠 총량·SearchLog) |
| `PROFESSIONAL_EXPERIENCE` | ❌ | 사용하지 않음 |
| `AI_GENERATED_EXPERIENCE` | ❌ | **금지 — 0건** |

"실무에서는 보통 …" 류의 경험 서술을 만들지 않았다. 화면의 모든 단정은 조문 인용을 동반한다.
