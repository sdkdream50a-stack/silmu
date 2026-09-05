# QUESTION_RADAR_DESIGN — 공무원 질문 레이더 설계

> **이번 세션 구현 없음. 설계만.** (§21 자동화 금지 원칙)
> 목표: 수천 개의 실제 표현을 **Canonical Question**으로 군집화해, 콘텐츠를 추측이 아니라 수요로 만든다.

---

## 1. 이미 보유한 원자재

| 원천 | 현재 상태 | 비고 |
|---|---|---|
| `cafe_articles` | **50,000행** (title·board·view_count·comment_count·written_at) | 최대 자산. `pg_trgm` GIN 인덱스 보유 |
| `search_logs` | 10행 | 계측 사실상 미가동 ⚠️ |
| `topic_feedbacks` | 0행 | 미가동 ⚠️ |
| `topic_events` | 2행 | 미가동 ⚠️ |
| `content_requests` | 부정 피드백 자동 backlog (관리자 화면 존재) | 배선은 있음 |
| AI 어시스턴트 질문 | 저장 구조 없음 | 신규 필요 |

> 🔴 **가장 값싼 신호(내부 검색어·피드백)가 사실상 수집되지 않고 있다.** 외부 크롤링을 설계하기 전에 **자기 로그부터 켜는 것이 옳다.** search_logs 10행은 계측 결손이다.

---

## 2. 소스 계층

| 계층 | 소스 | 수집 방식 | 신뢰 등급 |
|---|---|---|---|
| S1 내부 | `search_logs`, `topic_feedbacks`, `topic_events`, AI 질문, `content_requests` | 자체 로그 | 최우선 (의도가 확실) |
| S2 공식 FAQ | 행안부·인사혁신처·조달청·감사원·교육부·17개 시도교육청·지자체·공공기관 공개자료 | 공개 페이지 | Tier 1·2 (답의 근거로도 사용 가능) |
| S3 검색 | 네이버 연관검색어·자동완성, GSC 쿼리 | API/도구 | 수요 신호 |
| S4 커뮤니티 | 공개 접근 가능한 공무원 실무 커뮤니티 (`cafe_articles` 50,000행 포함) | 기존 수집 | **Tier 4 — 질문 발굴용, 정답 근거 금지** |

`SOURCE_HIERARCHY.md` SH-4를 그대로 적용한다: S4는 `QUESTION` 노드에만 연결되고 `EVIDENCE`에는 절대 연결되지 않는다.

---

## 3. 파이프라인

```
 RAW_QUERY (원문 표현)
     │  정규화: 조사·오탈자·띄어쓰기·동의어(standard_terms 13,208행 재사용)
     ▼
 NORMALIZED_QUERY
     │  군집: 표층 유사도(pg_trgm) → 도메인 사전 → 필요 시 임베딩
     ▼
 CANONICAL_QUESTION  ── maps_to ──►  TASK  ── has ──►  SOLUTION_PAGE
     │
     └─ demand_signal { volume, trend, agency_mix, season, unanswered_ratio }
```

### 군집 예시
```
병가 진단서 / 병가 6일 / 병가 며칠부터 진단서 / 병가 증빙 / 병가진단서 7일
        ↓
CANONICAL: "공무원 병가는 며칠부터 진단서가 필요한가?"
        ↓
TASK: 02.복무.병가.증빙     AGENCY 차원: 국가/지방/교육 규정 상이 → override 필요
```

**`standard_terms` 13,208행이 동의어 사전으로 이미 존재한다** (`synonyms` jsonb + GIN 인덱스). 새 사전을 만들지 않는다.

---

## 4. 산출 지표

| 지표 | 정의 | 용도 |
|---|---|---|
| `demand_volume` | 정규화 질의 빈도 | 우선순위 |
| `coverage` | 해당 TASK의 Solution Page 존재 여부 | 갭 발견 |
| `answer_quality` | 근거 Tier·검증 신선도 | 개선 대상 |
| `agency_mix` | 어떤 기관에서 오는 질문인가 | 확장 판단 |
| `unanswered_ratio` | 답 없이 이탈한 비율 | P3 콘텐츠 큐 |

**콘텐츠 생성은 `coverage=0 AND demand_volume≥임계`일 때만 트리거한다.**
임계값은 실측 전까지 `UNSET`이다 — 표본이 없으면 `INSUFFICIENT_DATA`로 두고 추측하지 않는다.

---

## 5. 안전 규칙

1. **Tier 4는 답의 근거가 될 수 없다.** 커뮤니티에서 발견한 질문의 답은 반드시 Tier 1·2로 다시 세운다.
2. 대규모 스크래핑 금지 (§21). S2는 공개 FAQ의 공식 경로만, 예의 있는 주기로.
3. 개인정보·기관 식별 정보는 정규화 단계에서 제거한다.
4. 자동 발행 금지 — 레이더는 **큐를 만들 뿐** 글을 쓰지 않는다.

---

## 6. 착수 순서 (P4, P0 종료 후)

| 단계 | 작업 | 비용 |
|---|---|---|
| Q1 | **내부 계측 복구** — `search_logs`·`topic_events`·`topic_feedbacks` 기록 배선 점검 | 낮음 · 최우선 |
| Q2 | AI 어시스턴트 질문 익명 저장 | 낮음 |
| Q3 | `cafe_articles` 50,000행 → 정규화·군집 배치 (오프라인) | 중간 |
| Q4 | Canonical Question ↔ TASK 매핑 테이블 | 중간 |
| Q5 | 갭 리포트를 `content_requests`에 자동 적재 (기존 화면 재사용) | 낮음 |
| Q6 | S2 공식 FAQ 수집 | 중간 |
