# TOOL_TRUST_REPORT — 도구 신뢰 레이어

> P0 실측: 도구 37개 중 면책 문구 7개(19%) · 기준연도 표기 5개(14%) · 검증 배지 0개.
> 그런데 계산 결과는 그대로 기안으로 들어간다. 기준값이 낡으면 **도구가 감사 지적을 생산한다.**

---

## 1. 접근 — 37개를 손으로 고치지 않는다 (§18)

`shared/_tool_next_actions.html.erb` 가 **도구 37개 전부에서 render** 되고 있었다(grep 결과 정확히 37파일).
이 파셜 최상단에 `shared/_tool_trust` 를 1줄 추가해 전 도구에 신뢰 레이어를 붙였다.

```erb
<%# 도구 신뢰 레이어는 next_actions 유무와 무관하게 항상 표시한다 %>
<%= render 'shared/tool_trust', tool_key: local_assigns[:tool_key] %>
```
기존 `if next_actions.any?` 가드 **바깥**에 두었다 — 다음 행동 카드가 없는 도구도 면책은 보여야 한다.

---

## 2. 표시 내용

| 항목 | 출처 | 없으면 |
|---|---|---|
| 적용 기준 | `config/tool_trust.yml` `basis` | 표시 안 함 |
| 기준일 | `config/contract_thresholds.yml` 헤더 / `config/legal_standards.yml` `version` 을 **직접 읽음** | 표시 안 함 |
| 계산 근거 | `laws:` → `LegalReferenceResolver` → 링크 | 표시 안 함 |
| 주의사항 | `defaults.disclaimer` | **항상 표시** |

### 기준일을 손으로 적지 않는 이유
손으로 적으면 그 값이 또 낡는다. 설정 파일에서 직접 읽으므로 **기준값 파일이 낡으면 화면이 스스로 낡았다고 말한다.**
회귀 테스트가 이를 강제한다 — `"기준일은 설정 파일에서 직접 읽는다 (손으로 적지 않는다)"`.

### 면책 문구 (§19)
> 계산 결과는 실무 참고용입니다. 소속 기관의 최신 지침·예규와 개별 상황에 따라 달라질 수 있으니, 기안 전 표시된 공식 근거를 확인하세요.

한 문장이다. 장문 경고로 도구 UX 를 해치지 않는다.

---

## 3. 현재 등록 현황

| 지표 | 값 |
|---|---:|
| 면책 문구 노출 도구 | **37 / 37** (공통 파셜) |
| 적용기준·기준일·근거를 갖춘 도구 | **11 / 37** |
| 근거 미등록 (면책만) | 26 / 37 |

등록된 11개: `contract-method` `contract-guarantee` `estimated-price` `predetermined-price` `split-contract-checker` `contract-legality-check` `contract-documents` `contract-reason` `qualification-evaluation` `budget-estimator` `travel-calculator`

**26개를 채우지 않은 이유:** 기준을 모르는 도구에 근거를 만들지 않는다. 등록되지 않으면 면책만 나가고, 없는 근거를 지어내지 않는다.
회귀 테스트 `"등록되지 않은 도구는 근거를 지어내지 않는다"` 가 이를 강제한다.

### 실물 확인
```
/tools/contract-method →
  적용 기준  지방계약법령 계약방법 결정 기준
  계약 기준값 기준일  2026-03-28
  계산 근거  [지방자치단체를 당사자로 하는 계약에 관한 법률 제9조] [… 시행령 제25조, 제30조]  ← 링크
  ⓘ 계산 결과는 실무 참고용입니다 …

/tools/pdf →
  ⓘ 계산 결과는 실무 참고용입니다 …   ← 근거 없는 도구는 면책만
```

---

## 4. 드러난 위험 (P2 이관)

기준값 파일이 **이미 낡았다.**

| 파일 | 기준일 | 경과 (2026-09-05 기준) |
|---|---|---|
| `config/contract_thresholds.yml` | 2026-03-28 | **5개월** |
| `config/legal_standards.yml` | 2026-02-04 | **7개월** |

이번 작업으로 이 사실이 **화면에 드러나게** 되었다. 값 자체를 갱신하는 것은 법령 확인이 필요한 별개 작업이다(P2).

## 5. 남은 일
- 나머지 26개 도구의 기준 등록 (도구별 실제 근거 확인 필요 — 추측 금지)
- 기준값 2종 갱신 (현행 법령 대조)
- 도구별 `SoftwareApplication` / `HowTo` JSON-LD (P0 SEO_AUDIT 권고, 이번 범위 밖)
