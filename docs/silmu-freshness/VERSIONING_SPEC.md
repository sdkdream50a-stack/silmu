# VERSIONING_SPEC — 버전·시행일 규격

## 1. Snapshot First (§19)

```
FETCH → NORMALIZE → HASH → COMPARE → STORE VERSION
```
변경이 없으면 아무것도 만들지 않는다. 있으면 **새 버전을 추가**한다(덮어쓰지 않는다).

## 2. 불변성이 왜 필요한가

버전을 덮어쓰면 "2026-06-15 에 우리가 무엇을 보고 검증했는가"에 답할 수 없다.
그러면 `AuthorityVerificationEvent.authority_version_id` 가 가리키는 대상이 사후에 바뀌어 **현행화 이력 전체가 무의미해진다.**

강제:
```ruby
version.update!(effective_at: ...)  # => AuthorityVersion::ImmutableError
version.destroy                     # => AuthorityVersion::ImmutableError
document.destroy                    # => 연관 삭제만 허용
```

## 3. 날짜 4종 (§9)

| 필드 | 의미 |
|---|---|
| `promulgated_at` | 공포일 — 관보에 실린 날 |
| `published_at` | 게시일 |
| `effective_at` | **시행일 — 현행성 판정의 기준** |
| `expires_at` | 실효일 |

### 공포 ≠ 시행
```
2026-09-01 공포 / 2026-10-01 시행  →  9월에는 기존 기준이 현행이다
```
그래서 엔진은 두 질문을 분리해 답한다.
- **개정되었는가?** → `AuthorityChangeEvent` 존재
- **지금 시행 중인가?** → `AuthorityVersion#in_effect?`

실측 예 (2026-09-06 수집):
```
지방공무원 보수규정  공포 2026-07-30 → 시행 2026-08-01  → in_effect? true
```

### 시행일 미상
`effective_at` 이 nil 이면 `in_effect? == false`, 라벨은 `"시행일 미상"`.
**모르는 것을 현행이라고 말하지 않는다.**

## 4. 문서 수준 조회

```ruby
document.effective_version(on = Date.current)  # 오늘 기준 실제 시행 중인 버전
document.pending_versions(on)                  # 공포됐으나 아직 시행 전
document.pending_change?                       # 시행 예정 개정이 있는가
```
회귀 테스트: 과거·미래 버전이 함께 있을 때 `effective_version` 이 **미래 버전을 고르지 않는다.**

## 5. 해시

```ruby
content_hash = SHA256(normalized_content)
```
정규화 이후에 계산한다. 그래야 공백·줄바꿈 변화가 개정으로 오인되지 않는다.

## 6. 부칙·경과조치 (§10)

이번 단계에서 부칙을 AI 로 해석하지 않는다. 확장 자리만 만들어 두었다.
```
authority_documents.has_transitional_provision   (nullable — 미판정 ≠ 없음)
authority_documents.transition_review_required
```
`false` 로 기본값을 주지 않은 이유: "부칙이 없다"와 "아직 확인하지 않았다"는 다른 사실이다.

## 7. 날짜 파싱

법제처 포맷은 `YYYYMMDD`.
```ruby
"20260603" → Date.new(2026, 6, 3)
"not-a-date" → nil   # 예외를 던지지 않는다. 파싱 실패가 수집 실패가 되면 안 된다
```
