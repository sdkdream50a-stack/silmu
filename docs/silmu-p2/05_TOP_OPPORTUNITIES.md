# 05 — TOP 20 OPPORTUNITIES

> 04 점수표 상위 20건. §27 요구 필드 전건 기재.
> `CURRENT_COVERAGE` 는 **2026-09-06 운영 실측**이지 추정이 아니다.
> `AUTHORITY_AVAILABLE` 은 "법령이 존재하는가"이고 "우리가 적재·확인했는가"는 09 문서가 본다.

범례 — `AUTHORITY_AVAILABLE`: `LOADED`(AuthorityDocument 8종에 있음) / `EXISTS_NOT_LOADED`(공식 법령은 있으나 미적재) ·
`FRESHNESS_RISK`: 매년 금액·요율이 바뀌는가 · `WIZARD_CANDIDATE`: 17 판정

---

## 1. P0 — 즉시 자산화 가치 큼 (SCORE ≥ 26)

### #1 수의계약 한도 금액 — SCORE 27
```
QUESTION/TASK        "물품 3천만원인데 수의계약 되나?" / "수의계약 한도 얼마?"
CATEGORY             계약·조달
AGENCY_SCOPE         전 기관 공통 (지방계약법 §30 · 국가계약법 §26 분기)
CURRENT_COVERAGE     Topic 6 · Guide 5 · AuditCase 4 · Tool 0 · Template 0 · HowTo 0
                     관련 토픽 private-contract-limit / private-contract / small-amount-contract
                     "바로 답" 8질의 중 3건만 뜨고, 그 답이 "한도에 부가세가 포함되나요?"다
GAP_TYPE             NO_DIRECT_ANSWER (5) · NO_TOOL (2) · NO_ACTION_STEPS (1)
USER_IMPACT          관측 37회 — 전체 2위 질의군
AUDIT_RISK           높음 — AuditCase 4건 매칭, 수의계약 감사사례 29건 보유
AUTHORITY_AVAILABLE  LOADED (지방계약법 시행령 · 시행규칙 적재됨)
FRESHNESS_RISK       높음 — 한도 금액은 시행령 개정 대상
FUNCTIONAL_ASSET     DECISION_WIZARD + LOOKUP
WIZARD_CANDIDATE     YES
PRIORITY             P0
RATIONALE            **답은 이미 코드 안에 있다.** ChatbotController#calculate_contract_method 가
                     물품·용역 2천만/5천만, 공사 2천만/4억 분기를 이미 계산한다.
                     그런데 "수의계약 한도" 질의에 도구가 **0건 매칭**됐다 —
                     도구 검색이 title/desc/keywords 토큰 AND 인데 "한도"라는 낱말이
                     계약방식 결정 도우미의 어디에도 없기 때문이다.
                     → **콘텐츠 생산이 아니라 라우팅·표제 문제.** 가장 싼 승리.
```

### #2 분할발주·분할계약 가능여부 — SCORE 27
```
QUESTION/TASK        "예산 회계가 달라도 분할발주하면 수의계약 되나?"
CATEGORY             계약·조달
AGENCY_SCOPE         전 기관 공통
CURRENT_COVERAGE     Topic 6 · Guide 5 · AuditCase 4 · Tool 0(*) · HowTo 0
                     split-contract-prohibition 토픽 존재. **"바로 답" 6질의 전건 nil**
GAP_TYPE             NO_DIRECT_ANSWER (5) · NO_CONTENT (1)
USER_IMPACT          관측 25회. 같은 문장이 서로 다른 표현으로 13회 반복 —
                     사용자가 답을 못 찾아 계속 바꿔 물었다는 신호
AUDIT_RISK           매우 높음 — 분할계약은 감사 최빈출 지적
AUTHORITY_AVAILABLE  LOADED
FRESHNESS_RISK       중간
FUNCTIONAL_ASSET     DECISION_WIZARD (기존 `분할계약 판단 체크리스트` 도구 존재)
WIZARD_CANDIDATE     YES
RATIONALE            (*) `split_contract_checker` 도구가 **이미 있는데** 질의에 매칭되지 않았다.
                     #1 과 같은 병(도구 발견성). 다른 점은 여기는 FAQ 조차 표제 질문에 답하지 않는다는 것.
                     "회계연도·예산과목이 다르면 분할이 아닌가"가 실무 핵심 질문인데 그 축이 없다.
```

### #3 검사·검수(검사원 지정) — SCORE 26
```
QUESTION/TASK        "검사원은 누가 지정하나" / "인터넷쇼핑몰 구매도 검수조서 필요한가"
CATEGORY             계약·조달
AGENCY_SCOPE         전 기관 공통
CURRENT_COVERAGE     Topic 1 · Guide 2 · AuditCase 5 · Template 3 · HowTo 6
                     inspection / construction-completion. 8질의 중 바로답 1건
GAP_TYPE             NO_CONTENT (3) · NO_DIRECT_ANSWER (4) · NO_TOOL (1)
USER_IMPACT          관측 26회
AUDIT_RISK           매우 높음 — AuditCase 5건 매칭, 검수/검사 카테고리 6건 보유
AUTHORITY_AVAILABLE  LOADED (지방계약법 시행령 검사·검수 조항)
FRESHNESS_RISK       낮음
FUNCTIONAL_ASSET     CHECKLIST + TEMPLATE (검사검수조서 서식 이미 3종 존재)
WIZARD_CANDIDATE     YES — "이 계약은 검사가 필요한가 / 누가 / 언제까지"
RATIONALE            서식은 있고(검수조서 3종) 절차 설명이 없다. DO 층 공백의 전형.
                     "감독원 / 검사원 / 검측"이 각각 다른 질의로 잡히는데 토픽은 1건뿐.
```

### #4 예산 이월·전용 — SCORE 26
```
QUESTION/TASK        "이월 되나" / "전용·이용·이체 차이" / "집행률"
CATEGORY             예산·회계
AGENCY_SCOPE         전 기관 공통 (지방재정법)
CURRENT_COVERAGE     Topic 2 · Guide 2 · AuditCase 5 · **Tool 1(이월·전용 적법성 판단기)** · Template 1
                     3질의 중 2건 COVERED — **상위 20 중 가장 잘 갖춰진 항목**
GAP_TYPE             WEAK_CONTENT (1: "집행률") · COVERED (2)
USER_IMPACT          관측 21회
AUDIT_RISK           높음 — AuditCase 5건
AUTHORITY_AVAILABLE  LOADED (지방회계법·지방재정법 계열)
FRESHNESS_RISK       중간
FUNCTIONAL_ASSET     CALCULATOR (예산 집행률 계산기 존재) + 기존 판단기 강화
WIZARD_CANDIDATE     YES (이미 구현체 있음 — 검증·연결만)
RATIONALE            **P0 인데 신규 제작이 거의 없다.** 도구·토픽·감사사례가 다 있고
                     "집행률" 질의만 토픽 0 이다. 비용 대비 완성도를 가장 빨리 올릴 수 있는 자리.
```

## 2. P1 — 높은 가치 (23 ≤ SCORE ≤ 25)

### #5 기간제·임기제 인사 — SCORE 25
```
CATEGORY 인사 · AGENCY_SCOPE 학교·교육청 강함(전 기관 해당)
CURRENT_COVERAGE  Topic 5 · Guide 0 · AuditCase 3 · Tool 0 · HowTo 10
GAP_TYPE          NO_CONTENT(2) · NO_DIRECT_ANSWER(1) · NO_TOOL(1)
USER_IMPACT       관측 38회 — **전체 1위 질의군**
AUDIT_RISK        중간 (AuditCase 3)
AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (기간제법·교육공무직 관련 지침 미적재)
FRESHNESS_RISK    중간   FUNCTIONAL_ASSET CHECKLIST + LOOKUP   WIZARD_CANDIDATE NO
RATIONALE         관측 1위인데 Guide 0. 기존 매칭이 `sick-leave` 로 새는 것은
                  기간제 전용 콘텐츠가 없어서다. 다만 근거 법령이 미적재라 09 선행 필요.
```

### #6 연말정산·4대보험 정산 — SCORE 25
```
CATEGORY 보수·수당 · 전 기관 공통
CURRENT_COVERAGE  Topic 1(year-end-settlement) · Guide 2 · AuditCase 1 · **Tool 1(4대보험 정산보험료 계산기)**
GAP_TYPE          NO_CONTENT(1) · NO_DIRECT_ANSWER(1) · WEAK_CONTENT(1) — **바로 답 0/3**
USER_IMPACT       관측 28회. **계절성** — 1~2월에 폭증할 항목이 5~9월 로그에서 이미 28회
AUDIT_RISK        낮음      AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (소득세법은 Law 에 있으나 AuthorityDocument 미적재)
FRESHNESS_RISK    **매우 높음** — 매년 요율·공제 기준 변경
FUNCTIONAL_ASSET  CALCULATOR(기존) + CHECKLIST   WIZARD_CANDIDATE NO
RATIONALE         계산기는 있는데 바로 답이 0/3. 도구와 질문 사이가 끊겨 있다.
                  freshness 축이 가장 높은 항목 중 하나 — 스케줄러 없이 만들면 이듬해 거짓말이 된다.
```

### #7 변경계약·설계변경 — SCORE 25
```
CATEGORY 계약·조달 · 전 기관 공통
CURRENT_COVERAGE  Topic 3 · Guide 1 · AuditCase 5 · Tool 1(설계변경 검토서 도우미) · Template 1
GAP_TYPE          NO_DIRECT_ANSWER(3) · COVERED(1)
USER_IMPACT       관측 26회   AUDIT_RISK 매우 높음(AuditCase 5)
AUTHORITY_AVAILABLE LOADED   FRESHNESS_RISK 낮음
FUNCTIONAL_ASSET  기존 도구 + CHECKLIST   WIZARD_CANDIDATE YES ("이 변경은 설계변경인가 계약변경인가")
RATIONALE         "공기연장에따른 간접비"·"계약기간 초과" 같은 실제 난문이 전부 바로답 0.
```

### #8 업무추진비 집행 — SCORE 25
```
CATEGORY 예산·회계 · 전 기관 공통
CURRENT_COVERAGE  Topic 2(entertainment-expense-rules) · Guide 0 · AuditCase 5 · Tool 0
GAP_TYPE          NO_CONTENT(4) · NO_TOOL(1)
USER_IMPACT       관측 18회 ("업무추진비"·"회식"·"급량비"·"행사실비보상금"·"복지포인트 상품권")
AUDIT_RISK        매우 높음 — 업무추진비는 감사·언론 최빈출
AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (지자체 업무추진비 집행기준은 예규·지침 계열)
FRESHNESS_RISK    중간   FUNCTIONAL_ASSET LOOKUP(집행 가능/불가 항목) + CHECKLIST   WIZARD_CANDIDATE YES
RATIONALE         "이거 업무추진비로 되나?"는 전형적 결정 트리 질문인데 자산이 토픽 2건뿐.
```

### #9 일상경비·지출증빙 — SCORE 24
```
CATEGORY 예산·회계 · 전 기관 공통
CURRENT_COVERAGE  Topic 4 · Guide 0 · AuditCase 0 · Tool 0 — **바로 답 0/7**
GAP_TYPE          NO_CONTENT(5) · NO_DIRECT_ANSWER(2)
USER_IMPACT       관측 36회 — 전체 3위
AUDIT_RISK        측정상 0 (AuditCase 매칭 없음) ← **감사사례가 없다는 뜻이지 위험이 없다는 뜻이 아니다**
AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (지방회계법 시행령·지방자치단체 회계관리 훈령)
FRESHNESS_RISK    중간   FUNCTIONAL_ASSET CHECKLIST + LOOKUP   WIZARD_CANDIDATE YES
RATIONALE         관측 3위인데 Guide 0·AuditCase 0·Tool 0. **가장 큰 순수 공백.**
                  "카드결제"·"견적서 미포함 카드지출"·"착오입금"이 전부 zero.
```

### #10 휴가(병가·특별휴가·육아휴직) — SCORE 24
```
CATEGORY 복무 · 전 기관 공통
CURRENT_COVERAGE  Topic 4 · Guide 1 · AuditCase 4 · HowTo 10 · Tool 0
                  바로 답 4/8 — 상위권 중 ANSWER 가 가장 잘 되는 항목
GAP_TYPE          NO_CONTENT(3) · NO_ACTION_STEPS(3) · NO_DIRECT_ANSWER(1) · NO_TOOL(1)
USER_IMPACT       관측 31회   AUDIT_RISK 중간
AUTHORITY_AVAILABLE LOADED (지방공무원 복무규정 적재됨)
FRESHNESS_RISK    중간   FUNCTIONAL_ASSET CHECKLIST(제출서류) + CALCULATOR(잔여일수)   WIZARD_CANDIDATE YES
RATIONALE         답은 있는데 **절차·서류가 없다**(NO_ACTION_STEPS 3건). DO 층 공백의 대표 사례.
                  "임신"·"장기휴가"·"육아휴직중 희망교류 제한"은 아예 0건.
```

### #11 보조금 정산 — SCORE 24
```
CATEGORY 보조금·위탁 · 지자체·교육청 공통
CURRENT_COVERAGE  Topic 6 · Guide 3 · AuditCase 3 · **Tool 1(보조금 정산 체크리스트)** · 시리즈 10편
GAP_TYPE          NO_DIRECT_ANSWER(2) · COVERED(1)
USER_IMPACT       관측 26회   AUDIT_RISK 높음
AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (지방보조금법·보조금 관리에 관한 법률 미적재)
FRESHNESS_RISK    중간   FUNCTIONAL_ASSET 기존 체크리스트 연결   WIZARD_CANDIDATE NO
RATIONALE         자산은 두꺼운데 "보조금정산" 19회 질의에 바로 답이 안 뜬다.
                  시리즈 10편이 검색 결과에 나오지만 클릭이 0 — 표제가 질문과 안 맞는다.
```

### #12 초과근무·시간외수당 — SCORE 24
```
CATEGORY 보수·수당 · 전 기관 공통
CURRENT_COVERAGE  Topic 1 · Guide 0 · AuditCase 1 · **Tool 1(초과근무수당 계산기)** — 바로 답 0/4
GAP_TYPE          NO_CONTENT(3) · NO_DIRECT_ANSWER(1)
USER_IMPACT       관측 13회   AUDIT_RISK 낮음~중간
AUTHORITY_AVAILABLE LOADED (지방공무원 보수규정)   FRESHNESS_RISK **높음**(매년 단가 변경)
FUNCTIONAL_ASSET  기존 계산기 + LOOKUP   WIZARD_CANDIDATE NO
RATIONALE         "시간외정액분 퇴직시"·"특수업무수당3-1"·"교직수당가산금1 교감" 같은
                  **수당 코드 단위 질의**가 전부 0건. 수당 LOOKUP 자산이 없다.
```

### #13 인지세·수입인지 — SCORE 23
```
CATEGORY 계약·조달 · 전 기관 공통
CURRENT_COVERAGE  Topic 6(완화매칭) · Guide 0 · AuditCase 3 · Tool 2(계약보증금 계산기 내 인지세)
                  **바로 답 0/4** · "수입인지" 8회 zero_result
GAP_TYPE          NO_CONTENT(1) · NO_DIRECT_ANSWER(2) · WEAK_CONTENT(1)
USER_IMPACT       관측 23회   AUDIT_RISK 중간
AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (인지세법)   FRESHNESS_RISK 중간
FUNCTIONAL_ASSET  LOOKUP(계약금액 → 인지세액) — 계산기에 이미 있음   WIZARD_CANDIDATE NO
RATIONALE         **계산기 안에 답이 있는데 "인지세"라는 표제 자산이 없다.** #1 과 같은 병.
```

### #14 예산과목 분류(수도광열비 등) — SCORE 23
```
CATEGORY 예산·회계 · 전 기관 공통
CURRENT_COVERAGE  **Topic 0** · Guide 0 · AuditCase 2 · Tool 1(예산 과목 분류 도우미)
GAP_TYPE          NO_CONTENT(4) · WEAK_CONTENT(2)
USER_IMPACT       관측 22회 ("수도광열비" 17 · "환경보전비" 5 · "급량비" 5 · "직접경비" · "자금배정" · "성립전")
AUDIT_RISK        낮음(측정)   AUTHORITY_AVAILABLE EXISTS_NOT_LOADED (지방자치단체 세출예산 집행기준)
FRESHNESS_RISK    **높음** — 집행기준은 매년 개정   FUNCTIONAL_ASSET LOOKUP(기존 도구 강화)   WIZARD_CANDIDATE NO
RATIONALE         도구는 있고 **토픽이 0건**이다. 도구 keywords 에 "수도광열비"가 이미 있는데도
                  질의 6건 중 1건만 도구가 잡혔다. 표제 콘텐츠 없이는 검색이 도구로 못 간다.
```

### #15 PQ·적격심사 — SCORE 23
```
CATEGORY 계약·조달 · 지자체 공통
CURRENT_COVERAGE  Topic 4 · Guide 1 · AuditCase 5 · Tool 1(적격심사 입찰률 확인)
GAP_TYPE          NO_CONTENT(2: "PQ"·"냑찰률") · COVERED(1)
USER_IMPACT       관측 16회   AUDIT_RISK 매우 높음(AuditCase 5)
AUTHORITY_AVAILABLE LOADED   FRESHNESS_RISK 낮음
FUNCTIONAL_ASSET  기존 도구 + 약어 사전   WIZARD_CANDIDATE NO
RATIONALE         "PQ" 같은 **약어**와 "냑찰률" 같은 **오타**가 zero_result 로 떨어진다.
                  콘텐츠가 아니라 동의어·오타 처리 문제인데, P1.6 §5 가 "동의어 대량 자동 생성 금지"라
                  **개별 검증된 약어만** 좁게 다뤄야 한다.
```

### #16 겸직·영리업무 — SCORE 23
```
CATEGORY 복무 · 전 기관 공통
CURRENT_COVERAGE  Topic 1(concurrent-position) · Guide 1 · AuditCase 4 · Tool 0 · 바로 답 1/2
GAP_TYPE          NO_CONTENT(1: "비상주 선임") · NO_TOOL(1)
USER_IMPACT       관측 15회   AUDIT_RISK 높음(AuditCase 4 · 징계 직결)
AUTHORITY_AVAILABLE LOADED (지방공무원법 §56·복무규정)   FRESHNESS_RISK 중간
FUNCTIONAL_ASSET  DECISION_WIZARD("이 활동은 겸직허가 대상인가")   WIZARD_CANDIDATE YES
RATIONALE         답 1건은 있는데 "허가 필요/불필요" 판정이 없다. 전형적 Wizard 대상.
```

## 3. P2 상위 (참고 — 상위 20 채움)

### #17 선금 지급·정산 — SCORE 21
```
Topic 3 · Guide 1 · AuditCase 2 · Tool 0 · 바로 답 2/4 · 관측 16회
GAP NO_CONTENT(1) · NO_DIRECT_ANSWER(1) · NO_TOOL(2)   AUTHORITY LOADED   WIZARD YES
RATIONALE "선금 정산 유예"·"선금청산액" 이 각각 0건. 선금은 금액·법적 영향이 큰데(C=3) 도구가 없다.
```

### #18 명예퇴직·퇴직수당 — SCORE 21
```
Topic 1 · AuditCase 2 · **Tool 2(퇴직금 계산기·연금 계산기)** · 바로 답 0/3 · 관측 8회
GAP NO_CONTENT(1) · NO_DIRECT_ANSWER(1) · WEAK_CONTENT(1)   AUTHORITY EXISTS_NOT_LOADED   FRESHNESS 높음
RATIONALE 계산기 2종이 있는데 "명예퇴직수당" 질의가 WEAK. 도구 keywords 에 "명퇴"는 있으나 표제 콘텐츠 0.
```

### #19 개인정보·영상정보 — SCORE 21
```
Topic 0(매칭된 contract-termination 은 "계약 파기" **오탐**) · Guide 0 · AuditCase 0 · Tool 0
GAP NO_CONTENT   관측 2회   AUTHORITY EXISTS_NOT_LOADED (개인정보보호법 미적재)
C=3(법적 영향 최상위) · J=3(freshness)   WIZARD_CANDIDATE YES
RATIONALE **관측이 2회뿐이라 E=1 로 낮지만, 콘텐츠가 0 이라 검색될 수 없었던 순환이 있다**(04 §5).
          법적 영향은 최상위군. §23 공공데이터·민원 축과도 접점.
```

### #20 국외출장 — SCORE 20
```
Topic 4 · Guide 2 · AuditCase 2 · Tool 1(여비계산기) · Template 1 · 바로 답 1/4 · 관측 12회
GAP NO_CONTENT(2) · NO_DIRECT_ANSWER(1) · NO_TOOL(1)   AUTHORITY EXISTS_NOT_LOADED(공무원 여비 규정은 Law 에는 있음)
RATIONALE "도내출장"·"관외출장 전날 지인집 숙박" 같은 **경계 사례**가 0건. 여비계산기는 국내 중심.
```

## 4. 이 표를 읽을 때의 편향 (§30)

### 4.1 E 축(검색 가능성)에는 순환이 있다
콘텐츠가 없으면 검색 결과가 없고, 결과가 없으면 사용자가 그 질문을 다시 하지 않는다.
**정보공개·기록물·개인정보·행정절차는 E 가 낮은데, 그게 수요가 없다는 증거가 아니다.**
이 4개는 SCORE 로만 보면 하위지만 §17(Wizard moat)·§23(공공데이터) 축에서 다시 평가해야 한다.
→ 10 문서 로드맵에서 "탐색 트랙"으로 분리했다.

### 4.2 B 축(감사 리스크)은 우리 DB 기준이다
AuditCase 257건은 계약·예산에 편중돼 있다(계약 116 · 예산/회계 79 · 기타 62).
따라서 **정보공개·개인정보·민원의 B=0 은 "우리가 그 분야 감사사례를 안 갖고 있다"는 뜻**이지
그 분야가 안전하다는 뜻이 아니다. #9 일상경비의 AUDIT_RISK 주석과 같은 함정이다.

### 4.3 상위 20 중 8건이 "도구는 있는데 안 잡힌다"
#1 #2 #4 #6 #7 #12 #13 #14 — 기존 39개 도구가 질의에 매칭되지 않는다.
**이건 콘텐츠 확장 과제가 아니라 발견성 과제다.** 07 문서에서 별도 트랙으로 뽑았다.
