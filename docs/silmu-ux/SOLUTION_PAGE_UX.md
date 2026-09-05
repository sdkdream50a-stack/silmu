# SOLUTION_PAGE_UX — P1.6 Phase E

> §27~§30·§37~§40. 전 콘텐츠 마이그레이션 없이 **대표 페이지에서 증명**한다(§65).

## 1. 적용 범위

`topics#show` (대표: `private-contract` · `travel-expense` · `sick-leave`).
Guide/AuditCase 는 이번에 건드리지 않았다 — §41 인계문서가 "홈·네비·검색 안정화 후"를 권했고
`topics/show.html.erb`(2,086줄)·`audit_cases/show.html.erb` 는 충돌 위험 **높음**으로 분류돼 있다.

## 2. First viewport (§28)

```
업무 제목                     ← @topic.name
바로 답                       ← @topic.summary (기존 quick-answer 블록)
근거: 지방계약법·시행령        ← 기존 legal-citation chip
[적용 대상] [현행성] [시행일]  ← 신설 shared/_solution_status  ★
핵심 수치                     ← 기존 quick_stats
지금 해야 할 일 1·2·3…         ← 신설 (howto_steps 원문)      ★
```

실측(`/topics/private-contract`): 스크롤 전에 제목·바로 답·근거·**현재 기준 확인 2026.06.09 검토**·
한도 3종(4억/2억/2,000만원)이 보이고, 바로 아래 "지금 해야 할 일" 4단계가 온다.

## 3. Progressive disclosure (§30)

```
Level 1 결론   summary + quick_stats        (첫 화면)
Level 2 절차   지금 해야 할 일 / 업무 흐름    (첫 화면 직하)
Level 3 근거   법령 3단 비교 · 공식 근거 · 검증 배지 (탭·하단)
```
법령 전문을 첫 화면에 쏟지 않는다(§83).

## 4. 빈 섹션을 만들지 않는다 (§29)

- `howto_steps` 없는 토픽 → **섹션 자체 미생성** (dev 기준 23/92 만 보유)
- `show_agency_scope?` false → 적용 대상 칩 미생성
- 이름 없는 step → 해당 항목 제외 (번호만 달린 빈 줄 금지)

## 5. Contextual tools / evidence (§37~§40)

기존 자산을 그대로 쓴다 — 새로 만들지 않았다.
- 토픽별 도구 연결: 기존 `shared/_tool_next_actions` · `TOOL_DEFINITIONS`
- 감사사례 맥락 연결: 기존 `related_audit_cases`
- 공식 근거: 기존 `shared/_authority_source` · `_legal_references`
- 검색 결과의 "바로 답" 카드에서 `자세히 보기` → 해당 토픽 (막다른 길 없음, §40)

## 6. 경계 (§6·§27)

`_solution_status` 는 **AuthorityPresenter 만** 읽는다.
`AuthorityVersion` · `AuthorityChangeEvent` · `ContentAuthorityLink` 직접 접근 0건.
구현 중 `topic.agency_labels`(모델에 없는 메서드)를 부르는 경계 위반을 한 번 저질렀고,
그 분기를 **실제로 렌더하는 테스트**를 추가해 고정했다(뮤테이션 A3 로 사멸 확인).
