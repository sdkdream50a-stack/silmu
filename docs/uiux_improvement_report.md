# exam.silmu.kr UI/UX 개선 통합 보고서

> 작성일: 2026-03-23
> 분석 방법: 경쟁사 벤치마킹 + 글로벌 에듀테크 분석 + YouTube 전문가 리서치 + NotebookLM AI 분석
> NotebookLM 노트북: https://notebooklm.google.com/notebook/c89a8361-aad0-4b76-a929-348f8f32e66e

---

## 1. 현황 요약

**대상**: exam.silmu.kr (공공조달관리사 시험 대비 학습 플랫폼)
**기술 스택**: Rails 8.1 + Hotwire + TailwindCSS + Pretendard + Material Symbols
**주 타겟**: 한국 공무원 시험 준비생

### 현재 강점
- Pretendard Variable — 한국어 최적화 현대 폰트 ✅
- Material Symbols Outlined — 통일된 아이콘 시스템 ✅
- Sticky Nav + 스크롤 배경 변화 ✅
- 반응형 디자인 (md: breakpoint) ✅
- Toast 알림 시스템 ✅
- 다크 오버레이 플래시카드 (집중 환경) ✅

---

## 2. 핵심 문제점 5가지

### 문제 1. 상단 헤더 3중 레이어 → 콘텐츠 시작점 과하게 아래 (심각도: 🔴)
- Notice Bar(파란 배경) + 미로그인 배너 + 6개 메뉴 Nav = 시각적 노이즈 3겹
- 실제 콘텐츠가 뷰포트 아래로 밀려남
- 글로벌 에듀테크 기준: 헤더 1개, 알림은 최소화

### 문제 2. 모바일 Bottom Tab Bar 없음 (심각도: 🔴)
- 모바일에서 오른쪽 사이드 드로어만 있고 하단 탭 없음
- 2025년 모바일 앱 표준: Bottom Tab 5개 이하
- Duolingo, Khan Academy, Coursera 모두 Bottom Tab 사용

### 문제 3. 학습 진행 상태 Nav 미노출 (심각도: 🟠)
- 장기 시험 준비생에게 "내가 얼마나 나아가고 있나" 가시성 없음
- Nav에 진행률 % 또는 연속 학습일 없음
- Khan Academy, Duolingo 모두 헤더에 진행 상태 고정

### 문제 4. 색상 일관성 부족 (심각도: 🟠)
- 파란 테마(#1d4ed8) + 1권(emerald) + 2권(blue) + 3권(violet) + 4권(rose) 혼재
- 미로그인 배너 항상 표시 → 추가 시각 노이즈
- 60-30-10 컬러 규칙 미적용

### 문제 5. 폰트 계층 구조 부족 (심각도: 🟡)
- Pretendard 사용 중이나 크기/굵기 체계 불일관
- 법령/장문 읽기 시 피로도 증가
- 2가지 폰트 굵기(Regular + Bold) 원칙 미적용

---

## 3. 글로벌 에듀테크 벤치마킹 핵심 교훈

| 플랫폼 | 핵심 전략 | exam.silmu.kr 적용점 |
|--------|-----------|---------------------|
| **Duolingo** | 감성 피드백 루프, 스트릭/XP | 퀴즈 정답/오답 마이크로 애니메이션, 연속 학습일 표시 |
| **Khan Academy** | 진행 상태 항상 가시화, 마스터리 | 챕터 완료율 Nav 노출, 학습 경로 시각화 |
| **Coursera** | 시맨틱 컬러 토큰, 12컬럼 그리드 | Primary/Success/Error 색상 체계 통일 |
| **Brilliant** | 과목별 색상 테마 유지 + 베이스 통일 | 1~4권 색상 유지하되 배경/레이아웃은 통일 |
| **Phantom** | 폴리시 = 신뢰 | 버튼/전환 애니메이션으로 프리미엄감 구축 |

---

## 4. 개선 로드맵 (우선순위 기반)

### 1순위: 단기 — 시각적 노이즈 제거 (1~2주)

#### 1-1. 헤더 단순화
```
현재: Notice Bar + Login Banner + Nav (3겹)
개선: Nav 단일화 + 스크롤 후 간소화
```

**구현 방법:**
- 미로그인 배너를 조건부 노출로 변경 (첫 방문 또는 특정 페이지만)
- Notice Bar는 학습 페이지에서 자동 숨김
- Nav 높이 h-16 → h-14 로 압축

#### 1-2. 폰트 계층 표준화
```
h1 타이틀:  text-xl font-bold text-gray-900
h2 소타이틀: text-base font-semibold text-gray-800
본문:       text-sm font-normal text-gray-700
부가정보:   text-xs font-normal text-gray-400
```

#### 1-3. 중복 CTA 제거
- 홈 히어로의 "커리큘럼 시작" + Nav의 "학습 시작" → 하나만 유지
- 페이지당 Primary CTA 1개 원칙 적용

**예상 효과**: 첫 화면 어지러움 즉각 해소, 가독성 향상

---

### 2순위: 중기 — 모바일 최적화 + 컬러 시스템 (2~4주)

#### 2-1. 모바일 Bottom Tab Bar 도입
```html
<!-- 모바일 전용 하단 탭 (md:hidden) -->
<nav class="fixed bottom-0 w-full bg-white border-t border-gray-100
            flex justify-around items-center h-16 pb-safe md:hidden z-50">
  <!-- 홈 / 학습 / 모의고사 / 랭킹 / 내정보 (5탭) -->
</nav>
```

**탭 구성 (5개 이하)**:
1. 홈 (home)
2. 학습 (menu_book) — 커리큘럼 + 플래시카드
3. 모의고사 (quiz)
4. 랭킹 (leaderboard)
5. 내 정보 (person)

#### 2-2. 색상 시스템 60-30-10 적용
```
60% Primary:  bg-blue-50 ~ bg-blue-700 (배경, 헤더)
30% Neutral:  bg-white, bg-gray-50, bg-gray-100 (카드, 콘텐츠)
10% Accent:   bg-amber-400, bg-orange-500 (CTA, 강조 포인트)

시맨틱 색상:
  Success: green-500 (정답, 완료)
  Error:   red-400 (오답, 경고)
  Warning: amber-400 (주의)
  Info:    blue-500 (안내)
```

#### 2-3. 학습 진행 상태 Nav 노출
```html
<!-- Nav 우측에 스트릭/진행률 표시 -->
<div class="flex items-center gap-2 text-sm">
  <span class="text-orange-500">🔥 <strong>7</strong></span>
  <span class="text-blue-600 font-medium">52%</span>
</div>
```

**예상 효과**: 모바일 UX 대폭 개선, 학습 동기 부여

---

### 3순위: 장기 — 감성 디자인 + 마이크로 인터랙션 (4~8주)

#### 3-1. 퀴즈 즉각 피드백 애니메이션
```css
/* 정답 */
.answer-correct { @apply animate-[pulse_0.4s] bg-green-50 border-green-500; }

/* 오답 */
.answer-wrong { @apply animate-[shake_0.3s] bg-red-50 border-red-400; }
```

#### 3-2. 챕터 완료 성취 UI
- 플래시카드 덱 완료 시 간단한 축하 오버레이 (confetti or 체크 모션)
- 5문제 연속 정답 시 "🔥 연속 정답!" 토스트

#### 3-3. 진행바 애니메이션
```html
<!-- 진행바 채워짐 트랜지션 -->
<div class="h-2 bg-blue-600 transition-all duration-500 ease-out rounded-full"
     style="width: <%= progress %>%"></div>
```

**예상 효과**: Duolingo 사례처럼 리텐션 및 재방문율 향상, 프리미엄 서비스 신뢰감

---

## 5. 구현 우선순위 체크리스트

### Phase 1 (즉시 - 1순위)
- [ ] 미로그인 배너 조건부 노출 (첫 방문만 또는 dismiss 영구 기억)
- [ ] 폰트 계층 TailwindCSS 유틸리티 클래스 표준화
- [ ] 중복 CTA 제거 (홈 페이지)
- [ ] Notice Bar — 학습 페이지(quiz, flashcard)에서 자동 숨김

### Phase 2 (2~3주 - 2순위)
- [ ] 모바일 Bottom Tab Bar 컴포넌트 (exam layout에 추가)
- [ ] 학습 진행률 헬퍼 메서드 + Nav 노출
- [ ] 연속 학습일(streak) 카운터 모델/뷰 추가
- [ ] 색상 토큰 정리 (CSS variables 또는 TailwindCSS config 기반)

### Phase 3 (4~8주 - 3순위)
- [ ] 퀴즈 정답/오답 마이크로 애니메이션
- [ ] 플래시카드 완료 성취 UI
- [ ] 진행바 트랜지션 통일
- [ ] 성취 토스트 메시지 시스템

---

## 6. 기술 구현 메모

### TailwindCSS 폰트 계층 공통 클래스 (app/assets/stylesheets 추가 권장)
```css
/* Typography Scale */
.heading-1 { @apply text-2xl font-bold text-gray-900 leading-tight; }
.heading-2 { @apply text-xl font-semibold text-gray-800 leading-snug; }
.heading-3 { @apply text-base font-semibold text-gray-800; }
.body-text  { @apply text-sm font-normal text-gray-700 leading-relaxed; }
.caption    { @apply text-xs font-normal text-gray-400; }
```

### Bottom Tab Bar (Ruby ERB)
```erb
<%# app/views/layouts/_mobile_tab_bar.html.erb %>
<nav class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100
            flex md:hidden z-50 pb-safe" aria-label="모바일 하단 네비게이션">
  <% [
    { icon: "home", label: "홈", path: exam_root_path },
    { icon: "menu_book", label: "학습", path: exam_keywords_path },
    { icon: "quiz", label: "모의고사", path: exam_quizzes_path },
    { icon: "leaderboard", label: "랭킹", path: exam_rankings_path },
    { icon: "person", label: "내정보", path: current_user ? profile_path : new_user_session_path }
  ].each do |tab| %>
    <%= link_to tab[:path],
        class: "flex-1 flex flex-col items-center justify-center py-2 gap-0.5
                #{current_page?(tab[:path]) ? 'text-blue-600' : 'text-gray-400'}",
        aria: { label: tab[:label] } do %>
      <span class="material-symbols-outlined text-[22px]"><%= tab[:icon] %></span>
      <span class="text-[10px] font-medium"><%= tab[:label] %></span>
    <% end %>
  <% end %>
</nav>
```

---

## 7. 참고 리서치 소스

| 구분 | 내용 |
|------|------|
| 경쟁사 분석 | 박문각 (국내) |
| 글로벌 에듀테크 | Duolingo, Khan Academy, Coursera, Brilliant |
| YouTube 리서치 | 감성 디자인(Duolingo/Phantom/Revolut), 아이콘 원칙(KR), 폰트 7팁(KR), 모바일 UI 10팁(KR) |
| AI 분석 | NotebookLM (3개 소스 통합 분석) |
| 현장 분석 | exam.silmu.kr 레이아웃 직접 분석 (609줄 exam.html.erb) |

---

*이 보고서는 파이프라인 리서치 결과를 NotebookLM AI 엔진으로 분석하여 생성되었습니다.*
