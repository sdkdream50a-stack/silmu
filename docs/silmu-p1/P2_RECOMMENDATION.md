# P2_RECOMMENDATION — 다음 단계 권고

> P1 이 만든 것: **근거를 보이게 하는 기반.** P2 가 할 것: 그 기반 위에서 답을 기관별로 정확하게 만드는 것.

---

## 우선순위

| 순위 | 항목 | 근거 | 비용 |
|---|---|---|---|
| **1** | 운영 backfill 실행 + 결과 검증 | P1 은 dev 에서만 적용됨. 운영 257건 중 66건은 dev 에 없다 | 낮음 |
| **2** | `LegalComplianceJob` 안전화 (dry-run + 승인 게이트) | 현재 AI 가 발행 콘텐츠를 무단 수정. 검증은 계속 멈춰 있다 | 중간 |
| **3** | 기준값 2종 갱신 (`contract_thresholds` 5개월 · `legal_standards` 7개월) | 도구 결과가 그대로 기안으로 들어간다 | 중간 |
| **4** | AI 근거 주입 배선 | 코드가 이미 있는데 도달 불가 — 최고 ROI | 낮음 |
| **5** | 나머지 26개 도구 기준 등록 | 면책만 있고 근거가 없다 | 중간 |
| **6** | MEDIUM 검토 큐 UI | 현재 CSV. `Admin::TopicReviewsController` 재사용 | 낮음 |
| **7** | `AGENCY_RULE_MODEL` 상속 구현 (COMMON_RULE + OVERRIDE) | 일반행정 확장의 전제 | 큼 |
| **8** | 조문 단위 딥링크 | 지금은 법령 단위 | 중간 |
| 9 | P0 SEO 잔여 (중복 title 6 · `/tools/quote-review` 레이아웃 이탈 · 감사사례 `Legislation` JSON-LD · 도구 스키마) | `docs/silmu-audit/SEO_AUDIT.md` | 낮음 |

**P3(일반행정 콘텐츠 확장)은 7번 이후다.** 기관 차원 없이 일반행정 콘텐츠를 만들면 P0 TR-06 을 549건에서 1,000건으로 늘릴 뿐이다.

---

## 4번 상세 — AI 배선 (검증된 사실 기반)

### 확인된 것
| 구성요소 | 상태 |
|---|---|
| `ai_chat_controller.js` → `perform("ask", { topic_slug })` | ✅ 정상 |
| `AiAssistantChannel#ask` → `data["topic_slug"]` | ✅ 정상 (파라미터명 일치) |
| 컨텍스트 조립 (`law_content`+`decree_content`+`rule_content`+`commentary`+`practical_tips`) | ✅ 정상 |
| `/ai-assistant` 뷰 → `data-ai-chat-topic-slug-value="<%= @topic&.slug %>"` | ✅ 정상 |
| `AiAssistantController#index` → `Topic.find_by(slug: params[:topic_slug])` | ✅ 정상 |
| **`topic_slug` 를 넘기는 링크** | ❌ **사이트에 0개** |
| 토픽 페이지의 `ai-chat` 위젯 임베드 | ❌ 없음 |
| 질문 → 토픽 retrieval | ❌ 없음 |

즉 **버그가 아니라 진입점 부재**다. 그래서 이번 세션에서 코드를 바꾸지 않았다(§30).

### 최소 변경안 (P2)
```erb
<%# app/views/topics/show.html.erb — 사이드바 %>
<%= link_to "이 토픽 근거로 AI에게 묻기",
            ai_assistant_path(topic_slug: @topic.slug),
            class: "..." %>
```
이 한 줄로 **이미 구현된 grounding 이 살아난다.**

### 함께 필요한 안전장치 (§31)
답변에 근거 상태를 표시한다.
```
✅ 실무.kr 「수의계약」 토픽 근거로 답변했습니다 (법령 기준일 2026-05-20)  [토픽 보기]
⚠️ 특정 토픽 근거 없이 일반 지식으로 답변했습니다. 반드시 공식 원문을 확인하세요.
```
`AiAssistantService#answer` 가 `topic_context` 유무를 이미 알고 있으므로 응답 payload 에 `grounded: boolean` 과 `topic_slug` 를 추가하면 된다. **retrieval(벡터 검색)은 필요 없다** — 진입점만 있으면 된다.

retrieval 은 그 다음 단계이며, `pg_trgm` 이 이미 설치되어 있어 벡터 DB 없이 시작할 수 있다.

---

## 2번 상세 — LegalComplianceJob

`FRESHNESS_JOB_REPORT.md` §3 의 8단계를 따른다. **1번(dry-run 기본값 true)과 3번(파싱 실패가 AI 를 호출하지 않게)만 해도 위험의 대부분이 사라진다.**

---

## 하지 말 것

- 기관 차원(7번) 없이 일반행정 콘텐츠 대량 생성
- `recurring.yml` 주석만 해제 (2번의 안전화 없이)
- 도구 기준값을 확인 없이 갱신
- MEDIUM/LOW confidence 자동 적용
- 조문 딥링크를 추측으로 생성 (§15 는 P2 에서도 유효)
