# TARGET_INFORMATION_ARCHITECTURE — P1.6 Phase B

> 코드 이전에 IA 를 확정한다(§62). CURRENT_UX_AUDIT.md 의 실측이 근거다.

---

## 1. 설계 명제

> **콘텐츠는 충분하다. 답도 이미 331건 있다. 부족한 것은 도달 경로다.**

따라서 P1.6 은 콘텐츠를 만들지 않고, **recall 복구 → 답 노출 → 다음 행동 연결** 순으로 고친다.

---

## 2. Primary navigation: BEFORE → AFTER

### BEFORE (콘텐츠 종류)
```
법령가이드 ▾ | 실무가이드 ▾ | 도구 ▾ | 감사사례 ▾ | 달력 | 더보기 ▾
```

### AFTER (업무 중심)
```
업무찾기 ▾ | 실무도구 ▾ | 법령·변경 ▾ | 신규자 | MY
```

### 매핑 — **삭제 0건**(§14·§51)
| 기존 | 이동 위치 | URL |
|---|---|---|
| 법령가이드 | `업무찾기` 드롭다운 내 "분야별 법령 가이드" + footer | `/topics` 유지 |
| 실무가이드 | `업무찾기` 드롭다운 + `신규자` | `/guides` 유지 |
| 감사사례 | `업무찾기` 드롭다운 "이 업무에서 자주 지적되는 것" + footer | `/audit-cases` 유지 |
| 도구 | `실무도구` (승격) | `/tools` 유지 |
| 업무달력 | `실무도구` 드롭다운 | `/tools/task-calendar` 유지 |
| 자료실 | `실무도구` 드롭다운 + footer | `/guides/resources` 유지 |
| AI 어시스턴트 | `실무도구` 드롭다운 (홈 주인공 아님 §84) | `/ai-assistant` 유지 |
| 시험 대비 | footer | `exam.silmu.kr` 유지 |
| 마이페이지 | `MY` | `/mypage` 유지 |

`법령·변경` = Freshness 를 사용자 언어로 옮긴 진입점.
**"자동 감지/항상 최신" 문구는 쓰지 않는다**(§7 P1_6_FINAL_HANDOFF — 스케줄러 OFF).

### 라우트 변경
**없음.** 새 URL 을 만들지 않고 기존 URL 을 업무 라벨로 재배치한다(§50·§51).
`업무찾기` 는 드롭다운이며 자체 페이지를 갖지 않는다 → SEO 영향 0.

---

## 3. Homepage: BEFORE → AFTER

| 위치 | BEFORE | AFTER |
|---|---|---|
| 1 | HERO: 헤드라인 + 검색 + 인기검색어 + sector 탭 | HERO: **질문형 검색**(주인공) + 예시 질문 |
| 2 | 업무달력 strip | **Task Entry 카드** (런타임 count 게이트) |
| 3 | 최근 본 항목 (숨김) | 최근 본 업무 (기존 localStorage 재사용) |
| 4 | 핵심 실무 도구 | 업무달력 strip |
| 5 | 큐레이션/사례/가이드 | 핵심 실무 도구 (유지) |
| 6 | CTA | 큐레이션/사례/가이드 (유지, 축소) |

- Hero 헤드라인: `공무원 업무, 찾는 데서 해결까지` (§9·§16)
- placeholder: `무엇을 처리하려고 하세요?` (§17)
- **콘텐츠 개수 자랑 제거**(§83) — lede 에서 "가이드 195개, 사례 191건" 삭제
- sector 탭·업무달력·도구 섹션은 **삭제하지 않고 아래로 재배치**

---

## 4. Search: BEFORE → AFTER

### 엔진 (§52·§53 — LLM 아님)
```
BEFORE:  tokens(공백분리 + 동의어) → 전 토큰 AND → 0건이면 pg_search 폴백
AFTER :  tokens → [NEW] stopword 제거 → 전 토큰 AND
                                      → 0건이면 [NEW] 내용어 부분집합 완화
                                      → 0건이면 pg_search 폴백
```
- 신규 파일 없음 원칙: `SearchQueryParser` 확장 + `Topic.search_multiple` 완화 경로 추가
- 동의어는 §18·§54 고가치분만 소량 추가 (연가보상비·1인견적·진단서·정보공개 등)
- **Authority/freshness 를 relevance 에 섞지 않는다**(§55)

### 결과 화면 (§20·§21)
```
BEFORE:  실무 도구(n) / 법령 가이드(n) / 감사사례(n) / 실무 가이드(n) / 서식(n)
AFTER :  ① 바로 답      ← topics.faqs 매칭 (331건 자산) · 없으면 렌더 안 함
         ② 업무 페이지  ← topic/guide
         ③ 관련 도구
         ④ 관련 서식
         ⑤ 감사사례
         ⑥ 법적 근거    ← AuthorityPresenter 경유
```
**"바로 답"은 기존 FAQ 원문만 쓴다. 요약·생성 금지(§21·§64).**
매칭 FAQ 가 없으면 카드를 그리지 않는다 — 빈 박스 금지(§29).

### Zero result (§41·§42)
```
BEFORE:  "검색 결과가 없습니다" + 추천 키워드 칩
AFTER :  + 비슷한 업무(완화 매칭 결과) + 다른 표현 제안 + 질문 남기기(/feedback)
         + SearchLog.zero_result 기록 (이미 존재 — 재사용)
```

---

## 5. Solution Page (§27~§30)

전 콘텐츠 마이그레이션 없음. **대표 페이지에만** 새 first viewport 를 적용해 증명한다(§65).

### First viewport (스크롤 전)
```
업무/질문 제목
적용 대상        ← authority.agency_labels (show_agency_scope? 일 때만)
현재 기준 상태   ← authority.freshness_label
바로 답 3~5줄    ← summary / faqs[0].answer
지금 해야 할 일  ← howto_steps (없으면 섹션 자체를 안 그림)
```

### Progressive disclosure (§30)
```
Level 1 결론   = 바로 답
Level 2 절차   = 지금 해야 할 일 / 업무 흐름
Level 3 근거   = 법령 전문 · 공식 근거 (접힘)
```

### 대표 페이지 선정 (자산 보유 기준)
`private-contract-limit` · `sick-leave` · `travel-expense` — 셋 다 faqs 보유,
task test A/B/C 와 직결.

---

## 6. Freshness UX (§31~§35)

| 상태 | 표시 | 소스 |
|---|---|---|
| CURRENT | `● 현재 기준 확인 · YYYY.MM.DD` | `authority.freshness_label` + `verified_on` |
| CHANGE_DETECTED / REVIEW_REQUIRED | `⚠ 최신 개정사항 검토 중` | `freshness_attention?` |
| UNKNOWN / STALE / SOURCE_UNAVAILABLE | `최근 검증 정보 없음` | `show_verification?` false → 배지 없음 |

**규칙**
- `show_*?` 가 false 면 그리지 않는다 — 거짓 CURRENT 금지(§32)
- view 에서 판정하지 않는다 — presenter 값만 읽는다(§6)
- `AuthorityVersion`·`AuthorityChangeEvent`·`ContentAuthorityLink` 직접 접근 0건(§27)
- diff·change_type·impact_class·version 은 공개 UI 에 안 나온다(admin 전용)
- 색상 클래스는 **리터럴** (Tailwind JIT)

---

## 7. 하지 않는 것

```
새 라우트 · 기존 URL 변경 · mass redirect · 기존 섹션 삭제
AI 답변 생성 · 콘텐츠 body 수정 · 대량 동의어 생성
Authority/Freshness business logic 수정 · 스케줄러 활성화 · 푸터 문구 강화
Question Radar 본체 · analytics dashboard · SNS 기능 · 챗봇 팝업
```

---

## 8. 구현 순서 (§60 고정)

```
1. Header/navigation
2. Hero/search
3. Task entry
4. Search result UX      ← 엔진 recall 복구가 여기 선행
5. Solution page first viewport
6. Contextual tools/evidence
7. Mobile polish
8. MY/recent (기존 자산 재사용 범위 내)
```
