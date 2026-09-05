# DIFF_ENGINE_SPEC — 변경 비교 규격

## 1. 단계 (§20)

| Level | 대상 | 상태 |
|:--:|---|---|
| 1 | document hash | ✅ |
| 2 | metadata (개정일·시행일·제목·문서번호) | ✅ |
| 3 | 조문/section | ✅ |
| 4 | paragraph | 설계만 |

처음부터 완벽한 semantic diff 를 목표로 하지 않는다.

## 2. 비교 대상 메타데이터

| 필드 | 표시명 |
|---|---|
| `title` | 법령명 |
| `korean_type` | 법령구분 |
| `agency` | 소관부처 |
| `promulgated_on` | 공포일자 |
| `revision_number` | 공포번호 |
| `revision_kind` | 제개정구분 |
| `effective_on` | 시행일자 |
| `status_code` | 현행연혁 |

## 3. change_type 분류 우선순위

```
현행연혁 → "연혁"        →  REPEALED
시행일자 변경            →  EFFECTIVE_DATE_CHANGED
기타 메타데이터 변경       →  METADATA_CHANGED
메타 동일 + 해시만 변경    →  CONTENT_CHANGED
이전 버전 없음           →  NEW_DOCUMENT (개정 아님, 기준선)
```

시행일 변경을 별도 타입으로 뽑은 이유: §9 — 언제부터 적용되는지가 실무 판단을 바꾼다.

## 4. Level 3 — 조문 단위

`제N조` / `제N조의M` 헤더로 본문을 쪼개 비교한다.
```ruby
machine_diff["sections"] # => { "modified" => ["제25조"], "added" => [], "removed" => [] }
```
이 결과가 Impact 분류의 DIRECT/INDIRECT 를 가른다:
- 콘텐츠가 근거로 삼는 조문이 `modified` 에 있으면 → **DIRECT**
- 같은 법령의 다른 조문이 바뀌었으면 → **INDIRECT**

## 5. 정규화 (§21)

**하는 것**
```
NFC 유니코드 정규화       (한글 자모 분리 표기 통일)
CRLF/CR → LF
NBSP → 일반 공백
연속 공백 축약
줄 앞뒤 공백 제거
3줄 이상 빈 줄 축약
HTML: script/style/nav/header/footer/iframe/noscript 제거, 태그 제거, 엔티티 복원
```

**하지 않는 것**
```
조문 번호 변경     제25조 → 25조   ❌
금액 표기 변경     2,000만원 → 20000000  ❌
단서 제거         "다만 ~ 경우 제외"  ❌
문장 재배열·요약                    ❌
```

회귀 테스트가 `제25조` `2,000만원` `제30조` `제1항` 이 정규화 후에도 보존되는지 확인한다.

## 6. 오탐 방지 실증

```ruby
# 같은 내용에 \r\n · 공백 추가 · 빈 줄 추가
detector.check(document)  # => unchanged (변경 이벤트 0)
```
회귀 테스트 `정규화 — 공백·줄바꿈 차이는 개정으로 오인되지 않는다`.

## 7. 현재 비교 대상 (구조화 소스)

법령 전문을 매번 받지 않고 **canonical payload**(메타데이터 조합)를 비교한다.
```
법령명 / 법령ID / 법령구분 / 소관부처 / 공포일자 / 공포번호 / 제개정구분 / 시행일자 / 현행연혁
```
개정이 있으면 공포번호·공포일자·시행일자 중 하나는 반드시 바뀌므로 이 조합으로 **개정 여부**는 확실히 잡힌다.

한계: **조문 본문 자체의 미세 변경**은 전문을 받아야 잡힌다.
→ Level 3 조문 diff 는 구현되어 있으나, 현재 canary 는 전문을 수집하지 않는다.
`LawApiService#fetch_law(mst)` 로 전문을 받아 `normalized_content` 에 넣으면 그대로 동작한다(P2).

## 8. Level 4 (설계만)

문단 단위 diff. 조문 안에서 어느 항·호가 바뀌었는지까지 보여주려면 필요하다.
현 구조에서 `split_articles` 를 항/호 단위로 한 번 더 쪼개면 되지만,
**법령 원문 전문 수집이 선행**되어야 의미가 있으므로 P2 로 미룬다.
