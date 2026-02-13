# Google Search Console 재검증 가이드

## 🎯 개요
SEO 최적화 작업(canonical 태그, 404 수정, 구조화 데이터 개선)이 완료되었으므로, Google Search Console에서 재검증하여 색인 생성을 정상화합니다.

---

## ✅ 1단계: URL 검사 도구로 개별 페이지 재검증

### 1-1. 우선 재검증 대상 페이지 (404 수정 완료)
이전에 404 오류가 발생했던 페이지들을 먼저 재검증합니다:

```
https://silmu.kr/topics/travel-expense
https://silmu.kr/topics/budget-carryover
https://silmu.kr/topics/year-end-settlement
https://silmu.kr/topics/direct-payment
https://silmu.kr/topics/private-contract
https://silmu.kr/topics/payment-period
https://silmu.kr/topics/joint-contract
```

### 1-2. Canonical 태그 수정 페이지
```
https://silmu.kr/guides
https://silmu.kr/topics
https://silmu.kr/audit-cases
```

### 1-3. 재검증 절차
1. [Google Search Console](https://search.google.com/search-console) 접속
2. 상단 검색바에 URL 입력 (예: `https://silmu.kr/topics/travel-expense`)
3. **"URL 검사"** 클릭
4. 결과 확인:
   - ❌ **"URL이 Google에 등록되어 있지 않음"** → 정상 (새 페이지)
   - ✅ **"URL이 Google에 등록되어 있음"** → 이미 색인됨
5. **"색인 생성 요청"** 버튼 클릭
6. 1~2분 대기 후 **"색인 생성됨"** 확인

---

## 🔄 2단계: Sitemap 재제출

### 2-1. 기존 Sitemap 삭제 및 재제출
1. Google Search Console > **Sitemaps** 메뉴
2. 기존 sitemap 삭제:
   - `https://silmu.kr/sitemap.xml` → 삭제
3. 새 sitemap 제출:
   - `https://silmu.kr/sitemap.xml` 입력 → **제출**

### 2-2. Sitemap 구조 확인
현재 sitemap에는 다음 콘텐츠가 포함됩니다:
- 법령 가이드(토픽): 29개
- 감사사례: 55개
- 자동화 도구: 19개
- 실무 서식: 23개
- 정적 페이지: 10개

**총 136개 URL** 색인 대상

---

## 📊 3단계: 색인 생성 상태 모니터링 (1~2주)

### 3-1. 확인 항목
Google Search Console > **색인 생성** 메뉴에서:

1. **페이지** 탭:
   - "색인 생성됨" 개수 증가 확인 (목표: 130개 이상)
   - "발견됨 - 현재 색인이 생성되지 않음" 감소 확인

2. **실적** 탭:
   - "총 클릭수" 변화 추이
   - "총 노출수" 증가 확인 (새 페이지 색인 후)

3. **환경** 탭:
   - "모바일 사용 편의성" 오류 없음 확인
   - "Core Web Vitals" 정상 확인

### 3-2. 자동 모니터링 (실무.kr)
별도 작업 불필요 - 자동 리포트 수신:
- 매주 월요일 9시: SEO 주간 리포트 (hello@silmu.kr)
- 매월 1일 10시: PageSpeed 월간 리포트
- 매주 수요일 15시: 깨진 링크 자동 체크

---

## 🚨 4단계: 오류 발생 시 대응

### 4-1. "서버 오류(5xx)" 발생 시
```bash
# 서버 로그 확인
ssh root@141.164.53.97 "docker logs silmu-web-latest --tail 100"

# 컨테이너 재시작
ssh root@141.164.53.97 "docker restart silmu-web-latest"
```

### 4-2. "리디렉션 오류" 발생 시
- config/routes.rb 확인
- 무한 리디렉션 방지 (예: redirect → redirect 체인)

### 4-3. "Canonical 오류" 재발 시
- app/controllers/application_controller.rb의 `canonical_url` 헬퍼 확인
- 모든 컨트롤러에서 `canonical: canonical_url` 설정 확인

---

## 📈 5단계: 성과 측정 (3~4주 후)

### 5-1. 색인 생성 성공률
- **목표**: 130개 이상 페이지 색인 (95% 이상)
- **현재**: 0개 → 130개 증가 예상

### 5-2. 자연 검색 트래픽
Google Analytics (GA4) 확인:
- **획득** > **트래픽 획득** > **Organic Search** 세션 증가

### 5-3. 검색 순위 모니터링
주요 키워드 순위 확인 (Google Search Console > 실적):
- "지방계약법" / "수의계약" / "계약보증금"
- "입찰참가자격" / "선금" / "하자보수"
- "계약실무" / "공공조달"

---

## 🎯 예상 결과

### 1~2주 후:
- ✅ 404 오류 페이지 0개 (현재 7개)
- ✅ Canonical 오류 0개 (현재 3개)
- ✅ 색인 생성된 페이지 100개 이상

### 3~4주 후:
- ✅ 자연 검색 유입 30% 이상 증가
- ✅ 평균 검색 순위 10위권 진입 (주요 키워드)
- ✅ 월간 방문자 1,000명 돌파

---

## 📞 문의 및 지원
- 이메일: hello@silmu.kr
- 자동 리포트 수신 확인: 매주 월요일 9시 (SEO 주간 리포트)
