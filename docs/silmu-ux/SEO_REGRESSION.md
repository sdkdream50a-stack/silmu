# SEO_REGRESSION — P1.6 §50·§51·§68

> BEFORE `e0342a7` → AFTER P1.6. 2026-09-06 실측.

## 1. URL 변경 = 0

```
config/routes.rb   변경 없음 (git diff 에 파일 자체가 없음)
db/schema.rb       변경 없음
db/migrate/**      변경 없음
```
`업무찾기`·`실무도구`·`신규자` 는 **라벨 재배치**이며 새 라우트를 만들지 않았다.
`업무찾기` 는 드롭다운이라 자체 페이지가 없다.

## 2. mass redirect = 0 (§51)

`/topics` · `/guides` · `/audit-cases` 인덱스를 삭제·리다이렉트하지 않았다.
전부 200 을 유지하며 nav 2차 표면 + footer 에서 계속 도달 가능하다.

## 3. 라이브 응답 대조

| 경로 | 코드 | canonical | title | description |
|---|---:|:--:|:--:|:--:|
| `/` | 200 | ✅ | ✅ | ✅ |
| `/topics` | 200 | ✅ | ✅ | ✅ |
| `/topics/private-contract` | 200 | ✅ | ✅ | ✅ |
| `/guides` | 200 | ✅ | ✅ | ✅ |
| `/audit-cases` | 200 | ✅ | ✅ | ✅ |
| `/tools` | 200 | ✅ | ✅ | ✅ |
| `/silmu-search` | 200 | ✅ | ✅ | ✅ |

`/sitemap.xml` 200 · `/robots.txt` 200 · `/feed.rss` 200 · `/llms.txt` 200

## 4. 구조화 데이터

토픽 페이지의 Article / FAQPage / HowTo / BreadcrumbList JSON-LD 를 **건드리지 않았다.**

### 부수 발견 (수정 안 함)
기존 HowTo JSON-LD 가 `howto_steps` 의 malformed 원소를 걸러내지 않고 그대로 내보낸다
(이름 없는 step 이 구조화 데이터에 들어갈 수 있다). **P1.6 이전부터 있던 별개 결함**이라
§3(외과적 변경)에 따라 보고만 한다. 화면 렌더 쪽은 P1.6 에서 걸러낸다.

## 5. 회귀 고정

`test/integration/task_first_navigation_test.rb`
- 기존 URL 6종이 200 인지
- 기존 진입점 9종이 **홈이 아닌 페이지에서도** 도달 가능한지
  (홈에서만 검사하면 본문 링크가 nav 손실을 가려 준다 — 뮤테이션으로 실측해 고쳤다)
