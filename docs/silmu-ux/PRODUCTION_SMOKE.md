# PRODUCTION_SMOKE — P1.6 배포 후 실사용 흐름 검증

> 2026-09-06 10:19~10:27 KST · 운영 리비전 `18fb735…` · 전부 public URL 실측.
> 검색은 `Turbo-Frame: search-results` 헤더가 있어야 결과가 렌더된다
> (`chatbot#search` 는 turbo_frame 요청이 아니면 301 로 인덱스로 보낸다).

## 1. 5개 업무 질의

| # | 질의 | 검색결과(topic/guide/audit) | 바로 답 | 판정 |
|---|---|---|---|:--:|
| A | 수의계약 한도 | 6 / 5 / 4 | "수의계약 한도 금액에 부가세가 포함되나요?" | PASS |
| B | 병가 며칠 쓰면 진단서 내야 하나요 | 1 / 0 / 1 | "병가에 진단서는 언제부터 제출해야 하나요?" | PASS |
| C | 출장비 얼마 지급하나 | 6 / 0 / 5 | "자가용으로 출장 시 여비는 어떻게 받나요?" | PASS |
| D | 정보공개 답변은 며칠 | 1 / 0 / 1 | "정보공개 청구를 하면 며칠 안에 결정되나요?" | PASS |
| E | 처음 계약을 맡았어요 | 6 / 0 / 0 | NONE | PASS |

### A — "억지 답" 아님을 콘텐츠로 확인
`private-contract-limit` 의 FAQ 는 **2개뿐**이고 둘 다 한도 자체를 표제로 답하지 않는다.
올라온 FAQ 는 질의의 두 토큰(수의계약·한도)이 **낱말 경계로 완전일치**하는 온토픽 항목이며,
답변 본문에 구체 금액 예시(부가세 별도 4,500만원)가 있다. 다른 질문의 답을 끌어온 것이 아니다.
표제 한도 금액을 직접 답하는 FAQ 가 없는 것은 **콘텐츠 공백**이며 편집 backlog 다.

### D — 인계 문서의 "콘텐츠 0" 은 development DB 기준이었다 (정정)
P1.6 구현 세션은 "정보공개 = 전 자산 0건 → honest zero 로 측정"이라고 기록했다.
그것은 **development DB(Topic 92건)** 실측이다. 운영 DB 는 Topic 114건이고
`information-disclosure` 토픽이 **FAQ 4건과 함께 실재**한다(정보공개법 §11·§9·§14 근거 포함).
따라서 운영에서 답이 나오는 것은 회귀가 아니라 **콘텐츠가 있어서**다.
답은 `Topic.answer_for` 가 기존 FAQ 원문을 그대로 고른 것이고 생성이 아니다(DB 대조 확인).

## 2. 정밀도 가드 (이번 수리의 대상)

| 질의 | 검색결과 유지 | 바로 답 | 판정 |
|---|:--:|---|:--:|
| 차비 지급 기준 | topic 2 · audit 1 | **NONE** (숙박비 FAQ 승격 없음) | PASS |
| 차비 얼마 | topic 2 · audit 2 | **NONE** (주차비 부분일치 승격 없음) | PASS |
| 지급 기준 | topic 6 · audit 5 | **NONE** (일반토큰 과반 승격 없음) | PASS |

검색 결과는 셋 다 그대로 나오고 틀린 "바로 답"만 사라졌다 — 정책이 의도한 형태.

## 3. Solution Page 첫 화면

| 요소 | `contract-execution` | `private-contract-limit` |
|---|:--:|:--:|
| 제목/업무(h1) | OK | OK |
| 적용 대상 | OK | OK |
| 현재 기준 상태 | OK | OK |
| 바로 답/요약 | OK | OK |
| 지금 해야 할 일 | OK (6단계) | — (이 토픽은 `howto_steps` 없음, 운영 10/114) |
| 근거/authority | OK | OK |

`지금 해야 할 일` 은 조건부 렌더이며 단계가 없으면 **지어내지 않는다**. 결함 아님.

**Freshness UI**: `shared/_solution_status` 는 `AuthorityPresenter#freshness_label` /
`#freshness_status` / `#freshness_attention?` 결과만 출력한다. 뷰가 CURRENT 를 자체 추론하는
분기는 없다 — 파셜 주석대로 "문구를 지어내지 않는다".

## 4. 모바일 390px (headless Chromium · is_mobile)

| 페이지 | 문서 가로overflow | h1 | nav 링크 | 검색 입력 | 바로 답 | img alt 누락 |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| HOME | **0px** | 1 | 52 | 사용가능 | – | 0 |
| SEARCH | **0px** | 1 | 52 | 사용가능 | **표시됨** | 0 |
| SOLUTION | **0px** | 1 | 52 | – | – | 0 |
| TOPICS | **0px** | 1 | 52 | – | – | 0 |

뷰포트 밖으로 나가는 요소가 있는 두 페이지는 전수 조사했다 — 전부
`overflow-x: auto` 탭 스크롤러 안(설계된 가로 스크롤) 또는 `overflow-hidden` 장식 레이어다.
**페이지 자체가 가로로 밀리는 요소는 0개.**

## 5. SEO 회귀

배포 전/후 동일 11개 URL 지문 대조 → **diff 0줄**.
HTTP · canonical · title · description 길이 전부 동일. redirect/404 신규 발생 0.

JSON-LD 파싱: `contract-execution` 7블록 · `private-contract-limit` 6블록 · `/` 3블록 —
**parse_error 0**. 기존 known issue(무명 HowTo step)는 실데이터 **0건**으로 이번 배포에서 악화 없음.
sitemap.xml · robots.txt 200.

## 6. 내부 메타데이터 누출

home · search · topic HTML 을 민감 패턴 5축(authority 내부상태 · 랭킹/디버그 점수 ·
검증 내부필드 · 예외/스택 · 자격증명)으로 스캔 → **0건**.
탐지기 **양성 대조** 통과(주입 문자열을 실제로 검출).

`data-search-rank` 는 검색결과 화면에 16개 있으나 값이 **순번(1,2,3…)** 이고 CTR 클릭 계측용이다.
내부 점수·랭킹 근거를 노출하지 않으므로 **LOW 유지**.

## 7. 콘텐츠 변이

배포 전/후 운영 DB 지문 대조.

```
TOPIC n=114 sha=e6eb1fb9acd09821978a9a43   (동일)
GUIDE n=103 sha=ab73eabb44d387d0a088ec49   (동일)
AUDIT n=257 sha=e29060d17e94f4d33a42b56e   (동일)
TOPIC_FAQ  sha=6d6fb1d6b011756e2b78b207 entries=455  (동일)
```

CONTENT_MUTATION = **0**. 지문 비교기 양성 대조 통과(1행만 바꿔도 검출).

## 8. 스케줄러

`config/` 는 `2d05bae..18fb735` 에서 **변경 0** → 스케줄러 설정이 바뀔 수 없다.
배포된 `config/recurring.yml` 실측: `AuthorityFreshnessCheckJob` **부재**,
`LegalComplianceJob` 2곳 모두 **주석 처리**. 등록된 recurring 11건은 전부 선재 SEO/뉴스레터 작업.
Authority/Freshness 스케줄러 = **OFF 유지**.
