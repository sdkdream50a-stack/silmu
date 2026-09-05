# TEST_REPORT — P1.6 §68·§77·§78·§79

> 2026-09-06 실측. BEFORE `e0342a7` → AFTER P1.6 브랜치.

## 1. 스위트

| | BEFORE (P1.55B) | AFTER (P1.6) |
|---|---:|---:|
| runs | 362 | **411** |
| assertions | 2,731 | **2,963** |
| failures | 0 | **0** |
| errors | 0 | **0** |
| skips | 14 | **14** ← 불변 |

- 신규 테스트 **49건**. **기존 테스트 수정 0건. 신규 skip 0건.**
- 신규 파일: `test/helpers/task_entry_helper_test.rb` ·
  `test/integration/task_first_navigation_test.rb` · `test/integration/solution_page_test.rb`
- 확장: `search_query_parser_test` · `topic_search_test` · `chatbot_controller_test`

## 2. §78 요구 회귀 항목 대응

| 요구 | 대응 |
|---|---|
| navigation render | `task_first_navigation_test` — 업무 라벨·진입점 보존(홈/비홈 2축) |
| homepage search | 히어로 placeholder·form action·예시 질문 |
| task cards | `task_entry_helper_test` 4건 + 홈 렌더 |
| search result | `chatbot_controller_test` 바로 답 렌더·미렌더 |
| zero result | 다른 표현 안내 + `/feedback` 경로 |
| freshness current | `solution_page_test` CURRENT 표시 |
| freshness review-required | `stale` 상태에서 문구 대체 |
| weak/no freshness | UNKNOWN 에서 상태를 지어내지 않음 |
| agency scope | HIGH 일 때만 노출 (LOW 는 미노출) |
| metadata leak | `solution_page_test` 내부 용어 6종 부재 + `rake silmu:p1:leak_scan` |
| mobile-safe markup | 실 브라우저 가로스크롤 0px (390/1440 × 5페이지) |

## 3. 뮤테이션 — green 은 증거가 아니다

방어를 하나씩 망가뜨려 **테스트가 실제로 죽는지** 확인했다. 35축 전부 KILLED.

```
M1~M11  검색: stopword·all-stopword가드·조사분리·fallthrough·어간최소길이·연상어동의어
              ·완화경로·단일토큰가드·완화선행·과반임계·매칭수정렬
A1~A8   바로 답: 임계(2종)·항상nil·최대hits·비Hash가드·presenter경계·답변본문·제로결과안내
N1~N10  네비/홈: 업무찾기라벨·신규자·달력·서식·AI진입점·커버리지게이트·업무카드
              ·placeholder·개수자랑·없는예시질문
S1~S6   Solution: 거짓CURRENT하드코딩·agency가드·상태줄·빈박스·깨진step필터·howto섹션
```

### ⭐ 뮤테이션이 **내 테스트 결함 7건**을 적발했다

| 축 | 처음 결과 | 원인 | 조치 |
|---|---|---|---|
| M7 완화 경로 | SURVIVED | 픽스처가 작아 pg_search 폴백이 같은 답을 냄 | `relaxed_match` 프리미티브 직접 단위 테스트 |
| M11 매칭수 정렬 | SURVIVED | 순서 단언이 hit_count 아닌 view_count 우연에 기댐 | view_count 를 역방향(2매칭=5 vs 1매칭=999)으로 건 조합 |
| A2 answer 임계 | SURVIVED | "무관한 FAQ" 토픽이 애초에 검색에 안 걸림 | **검색에는 걸리되** FAQ 만 무관한 토픽으로 재구성 |
| A4 최대 hits | SURVIVED | 게이트가 이미 하나만 남겨 선택 로직이 시험되지 않음 | 둘 다 게이트를 통과하는 3토큰 케이스로 교체 |
| A5 비Hash 가드 | SURVIVED | "죽지 않는다"만 확인 | 배열 원소 + 빈 항목 미출력까지 단언 |
| N-보존 | SURVIVED | 홈 본문 링크가 nav 손실을 가려 줌 | **홈이 아닌 페이지(/privacy)** 에서 검사 |
| N9 개수 자랑 | SURVIVED | 특정 문장만 금지 → 문장 바꾸면 부활 | "히어로 lede 에 숫자 없음" 성질로 교체 |

**SURVIVED=0 은 뮤테이션 설계자가 정한 범위 안에서만 참이다.** 위 7건이 그 증거다.

## 4. 양성 대조 (§79)

| 주장 | 검출기 | 양성 대조 |
|---|---|---|
| 내부 메타데이터 누출 0 | `rake silmu:p1:leak_scan` | **OK** — 알려진 누출 문자열을 실제로 차단. at_risk 115건(경계의 실효 가치) |
| 콘텐츠 자동 변이 0 | Topic/Guide/AuditCase 본문 SHA256 digest | **OK** — 트랜잭션 내 1건 수정 시 digest 변화 검출, 롤백 후 원복 확인 |

두 주장 모두 **"0을 세는 장치가 0 아닌 것도 셀 수 있음"** 을 먼저 증명한 뒤의 0이다.

## 5. 정적 확인

```
config/routes.rb   변경 0   (git diff 에 파일 없음)
db/schema.rb       변경 0
db/migrate/**      변경 0
앱 코드 콘텐츠 쓰기  0        (update_all/update_columns/save/destroy 등 grep 0건)
```

## 6. 실 브라우저 확인 (§80)

headless Chromium 으로 렌더 확인: 홈(데스크탑/모바일) · 검색 결과(바로 답 있음/없음) ·
제로결과 · Solution Page(데스크탑/모바일) · 감사사례.
스크린샷 = `tmp/p16_shots/` (커밋하지 않음).
