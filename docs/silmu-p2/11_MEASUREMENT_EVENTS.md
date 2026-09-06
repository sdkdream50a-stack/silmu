# 11 — MEASUREMENT EVENT CANDIDATES

> §29. P2 이후 성과를 측정할 수 있도록 **최소 이벤트 후보**를 설계한다.
> **새 analytics system 을 만들지 않는다** — 기존 계측을 먼저 센다.

---

## 1. 이미 있는 계측 (실측)

| 계측기 | 구현 | 상태 |
|---|---|---|
| `SearchLog` | 질의 + 5종 결과 카운트 + `zero_result` + `ip_hash` | ✅ **가동 중** (2,161건) |
| `SearchLog#clicked_at` / `clicked_result_type` / `clicked_result_rank` | `chatbot#click` (첫 클릭만) | ✅ 가동 중 (575건) |
| GA4 | `G-DGH1M308BH` (exam 은 `G-D3SL77M9GE`) | ✅ 배포됨 |
| `content_migration_view` GA4 이벤트 | `AnalyticsHelper#roi_content_migration_tag` | ✅ 특정 슬러그 한정 |
| `AnalyticsSnapshot` | `page_path` × `label` × `metrics(jsonb)` | ✅ 모델 존재 |
| `Topic/Guide/AuditCase#view_count` | 컬럼 | ✅ 존재 |

> **§29 가 요구한 8개 이벤트 중 3개는 이미 있다.** 새로 만들 것은 5개다.

## 2. §29 이벤트 × 현재 상태

| §29 이벤트 | 현재 | 원천 | 판정 |
|---|---|---|---|
| `search_submitted` | ✅ **있음** | `SearchLog.create` (모든 질의) | 재사용 |
| `zero_result` | ✅ **있음** | `SearchLog.zero_result` | 재사용 |
| `answer_shown` | ❌ 없음 | `Topic.answer_for` 반환 여부 | **신규 — 컬럼 1개** |
| `answer_clicked` | ⚠️ 부분 | `clicked_result_type` 에 값 추가하면 됨 | 재사용(값 확장) |
| `solution_action` | ❌ 없음 | Solution Page 의 "지금 해야 할 일" 상호작용 | **신규** |
| `tool_clicked` | ⚠️ 부분 | `clicked_result_type="tool"` 로 이미 구분 가능 | 재사용 |
| `source_clicked` | ❌ 없음 | 공식 근거 링크 클릭 | **신규** |
| `related_task_clicked` | ⚠️ 부분 | `@related_topics` 클릭 — GA4 로만 | 재사용/보강 |

## 3. 신규 최소 3건 (더 만들지 않는다)

### E1 `answer_shown` — 가장 중요
```
왜      03 §3 의 핵심 지표가 "211 질의 중 바로 답 20건(9.5%)"인데
        이건 **이번 세션이 손으로 재현해서 얻은 값**이다. 운영은 그 수치를 계속 모른다
어떻게   SearchLog 에 boolean 1개 (answer_shown) + string 1개 (answer_topic_slug)
        additive 컬럼만. 기존 로깅 경로에 값 2개 추가
측정     answer_shown 율 = P2 콘텐츠 작업의 직접 성과 지표
```

### E2 `answer_clicked` 값 확장
```
왜      "바로 답이 떴다"와 "그게 답이었다"는 다르다. 지금은 917건(42.4%)이
        결과를 보고도 아무것도 안 눌렀다 — 그게 답이 아니었다는 뜻
어떻게   기존 clicked_result_type 에 "answer" 값 추가. 스키마 변경 0
측정     answer_shown → answer_clicked 전환율
```

### E3 `source_clicked`
```
왜      North Star 3층 중 EVIDENCE 층이 실제로 쓰이는지 아무 근거가 없다
어떻게   기존 클릭 계측과 같은 경로. clicked_result_type="source"
측정     근거 링크가 장식인지 자산인지 판별
```

## 4. 만들지 않는 것

| 후보 | 왜 안 만드나 |
|---|---|
| `solution_action` | "지금 해야 할 일"이 10/114 토픽에만 있다. 계측 대상이 거의 없는데 계측기부터 만드는 건 순서가 거꾸로다 → **R3 이후 재판단** |
| 새 analytics 테이블 | `SearchLog` + `AnalyticsSnapshot` + GA4 로 충분. §29 명시 |
| 세션·퍼널 추적 | 개인정보 축 확대. `ip_hash` 이상은 필요 없다 |
| 콘텐츠 개수 대시보드 | §83 — 개수를 성과 지표로 쓰지 않는다 |

## 5. P2 성과 판정 기준 (측정 가능한 형태로 미리 적어 둔다)

R1~R5 를 착수하면 **무엇이 좋아져야 성공인가**를 지금 고정한다.
나중에 정하면 결과에 맞춰 기준을 옮기게 된다.

| 조치 | 성공 판정 | 측정 방법 |
|---|---|---|
| R1 도구 발견성 | 지목 8질의 전건에서 `tool_count ≥ 1` **AND** 무관 질의에 도구가 새로 붙지 않음 | `_measure/gap_radar.rb` 재실행 · before/after 대조 |
| R2 수의계약·분할발주 | 해당 질의군에서 `answer_shown = true` · 654-query 지문 불변 | 동 + 지문 재측정 |
| R3 DO 층 | HowTo 보유 토픽 10 → 25 · 해당 토픽 `NO_ACTION_STEPS` 소멸 | `coverage_audit.rb` 재실행 |
| R4 신규자 트랙 | `/start` 렌더 트랙 1 → 4 · 빈 트랙 0 | 08 §7 방법 |
| R5 신규 토픽 | "일상경비"·"수도광열비" 가 `NO_CONTENT` → 최소 `NO_TOOL` 이상 | `gap_radar.rb` 재실행 |
| **공통** | **CONTENT_MUTATION 은 의도한 것만** — 의도 밖 변이 0 | `positive_control.rb` PC6 |

> 위 6줄이 곧 **재측정 스크립트가 이미 존재한다는 뜻**이다.
> `_measure/` 6종은 P2 구현 전후를 같은 방법으로 잴 수 있게 남겨 둔 것이다.
