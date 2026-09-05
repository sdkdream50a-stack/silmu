# CANARY_RUN_2 — 두 번째 동일 주기 (무변경 대조)

> §20 — **먼저 first run 에서 실제 version 생성이 있었음을 positive control 로 기록한 뒤** 0을 검증한다.

## 1. Positive control 선행 (RUN 1)

```
versions created = 8
change events    = 8
```
검출기가 실제로 무언가를 만들어낸다는 것이 먼저 증명되었다.
이것이 없으면 아래의 0은 "변화가 없었다"인지 "검출기가 죽었다"인지 구분할 수 없다.

## 2. RUN 2 실행

같은 공식자료(법제처 8문서)를 다시 수집. 소스 주기(24h)를 우회하기 위해 `document_ids` 를 명시했다.

```
시작 00:40:02 → 종료 00:40:18   (16초)
[AuthorityFreshness] {"checked":8,"unchanged":8,"changed":0,"failed":0,"tasks_created":0,"skipped_failing":0}

  versions 8 -> 8   (신규 0)
  events   8 -> 8   (신규 0)
  tasks    0 -> 0   (신규 0)
```

## 3. §20 검증

| 항목 | 기대 | 실제 |
|---|---:|---:|
| new versions | 0 | **0** ✅ |
| new change events | 0 | **0** ✅ |
| new review tasks | 0 | **0** ✅ |
| fetch failures | 0 | **0** ✅ |
| unchanged 판정 | 8 | **8** ✅ |

**0-claim gate 통과** — RUN 1 의 8건 생성이 선행 기록되어 있으므로 이 0은 유의미하다.

## 4. §27 콘텐츠 무변경 (운영)

```
POSITIVE CONTROL — 스냅샷이 변경을 잡는가:  OK 검출됨
freshness run: {"checked":8,"unchanged":8,"changed":0,"failed":0,"tasks_created":0}
  Topic:     본문 무변경 OK
  Guide:     본문 무변경 OK
  AuditCase: 본문 무변경 OK
  전체 판정: NO_AUTO_PUBLISH OK
```

비교 대상 컬럼
```
Topic     : name, summary, law_content, decree_content, rule_content, commentary, practical_tips, published
Guide     : title, summary, description, sections, published
AuditCase : title, issue, detail, lesson, action_taken, legal_basis, published
```
전 행을 SHA256 으로 지문화해 실행 전후를 비교했다(표본이 아니라 **전수**).

스냅샷이 실제 변경을 감지한다는 것을 먼저 확인했으므로(POSITIVE CONTROL) "무변경"은 유의미하다.

## 5. 중복 실행 안전성

RUN 1 · RUN 2 · 무변경 검증까지 **같은 문서를 3회** 수집했다.
```
versions 8 (증가 없음) · events 8 (증가 없음)
```
중복 version/event 가 생성되지 않는다(§22 duplicate run prevention).

## 6. 판정

```
RUN_2 = SUCCESS
  unchanged 8/8 · 신규 version 0 · 신규 event 0 · 신규 task 0
  콘텐츠 본문 변경 0 (positive control 선행)
```
