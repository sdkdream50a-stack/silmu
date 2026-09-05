# LAW_CONTENT_FETCHER_DECISION — 선재 파서 결함 처분

> §12·§13·§14 — 영향이 public legal/freshness metadata 에 연결되면 **P0 Trust Critical** 로 취급한다.

---

## 1. 결함

`app/services/law_content_fetcher.rb#parse_law_meta`
```ruby
item = xml.at_css("법령")   # ← 실제 응답 노드는 <law>
return nil unless item      #    항상 nil → static_law_meta 폴백
```

법제처 검색 API 실제 응답(2026-09-06 실측):
```xml
<LawSearch><totalCnt>1</totalCnt>
  <law id="1">
    <법령일련번호>286149</법령일련번호>
    <시행일자>20260603</시행일자>
    <소관부처명>행정안전부</소관부처명>
    <법령구분명>대통령령</법령구분명>
  </law></LawSearch>
```
항목 노드는 `<law>`(영문)이고 **자식 태그만 한글**이다. `at_css("법령")` 은 매칭하지 못한다.

## 2. 사용자 영향 추적 (§12)

전수 grep 결과 소비처 4곳:

| 소비처 | 성격 | 사용자 영향 |
|---|---|---|
| `app/views/topics/_law_reference_links.html.erb:23` | **공개 UI** | `(YYYY.MM.DD 시행)` 표기가 **렌더되지 않음** |
| `app/jobs/law_sync_job.rb:45` | `laws` 테이블 동기화 | `effective_date`·`law_type`·`ministry` 가 비어서 저장됨 |
| `app/jobs/law_change_notification_job.rb` | 법령 개정 알림 | 시행일 없이 동작 |
| `app/services/blog_legal_verifier.rb:233` | 외부 API(blog_autopilot) | MST 없이 동작 |

### 운영 실측 증거
```
laws 테이블 15행 · effective_date 보유 0 · law_type 공란 · ministry 공란
law_id 컬럼에 '법령명'이 들어감 (폴백 산출물)
https://silmu.kr/topics/private-contract → "시행)" 문자열 0건
```
→ **공개 법령 메타데이터에 직접 연결된다. P0 Trust Critical 로 분류.**

## 3. §13 안전 수정 3조건

| 조건 | 판정 | 근거 |
|---|:--:|---|
| parser correction isolated | ✅ | `parse_law_meta` 단일 메서드. 셀렉터 1줄 + 필드 추출 방식 |
| fixture test exists | ✅ | `test/services/law_content_fetcher_test.rb` 신규 6 tests (실제 응답 픽스처) |
| render output difference understood | ✅ | 아래 4번 |

→ **DECISION: FIXED**

## 4. 렌더 차이

`_law_reference_links.html.erb` 는 **이미 분기를 갖고 있다.**
```erb
<% if ref[:effective_display].present? %>
  <span …>(<%= ref[:effective_display] %>)</span>
<% end %>
```
- **수정 전**: `effective_display` 가 항상 nil → 괄호 표기 자체가 없음
- **수정 후**: `(2026.06.03 시행)` 이 법령 링크 옆에 표시됨

즉 **템플릿 변경 없이** 원래 의도된 표기가 살아난다. 레이아웃 변화 없음(inline span 1개 추가).

## 5. 수정 내용

```ruby
item = xml.at_xpath("//law")
return nil unless item

pick = ->(tag) { item.at_xpath("./#{tag}")&.text&.strip.presence }
mst  = pick.call("법령일련번호")
name = pick.call("법령명한글") || fallback_name
eff  = pick.call("시행일자")
min  = pick.call("소관부처명")
type = pick.call("법령구분명")
```
`.presence` 를 추가해 빈 문자열이 `""` 로 저장되지 않게 했다.

## 6. Positive / Negative Control (§14)

**라이브 실증** (수정 후)
```
fetch_law_meta("지방자치단체를 당사자로 하는 계약에 관한 법률 시행령")
  mst               = "286149"
  law_type          = "대통령령"
  ministry          = "행정안전부"
  effective_date    = "20260603"
  effective_display = "2026.06.03 시행"
  url               = "https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=286149"   ← MST 기반 상세 URL
```
수정 전에는 `effective_display = nil`, `url` 은 법령명 기반 폴백이었다.

**픽스처 테스트 6종**
| 테스트 | 성격 |
|---|---|
| `<law>` 노드에서 시행일·부처·구분·MST 추출 | POSITIVE |
| 구 셀렉터 `at_css("법령")` 이 매칭 못 함을 고정 | REGRESSION (픽스처 전제 보호) |
| 검색 결과 0건 → nil | NEGATIVE |
| 응답 없음 → nil | NEGATIVE |
| 시행일자 형식 이상 → `effective_display` 만들지 않음 | AMBIGUOUS |
| 법령명 공란 → 폴백 이름 사용 | 경계 |

## 7. 검증

```
bin/rails test        345 runs · 2,651 assertions · 0F · 0E · 14 skips  (P1.5 339 대비 +6)
bin/rubocop           2 files, no offenses
```

## 8. 배포 후 확인할 것

운영 배포 뒤 다음이 실제로 바뀌었는지 확인한다.
1. `https://silmu.kr/topics/private-contract` 에 `(YYYY.MM.DD 시행)` 표기 등장
2. `LawSyncJob` 재실행 후 `laws.effective_date` 가 채워지는지
   — ⚠️ 이 잡은 `laws` 테이블에 **쓴다**. 게시 콘텐츠는 아니지만 자동 실행 전 별도 확인이 필요하다.
   이번 Phase 에서는 **실행하지 않는다.**
