# SEO 전체 감사 (silmu.kr)

이 스킬은 silmu.kr의 SEO 상태를 종합적으로 점검합니다.

## 실행 순서

### 1단계: Sitemap 검증

1. **sitemap.xml 접근 확인**
   ```bash
   curl -s -o /dev/null -w 'HTTP: %{http_code}\n' https://silmu.kr/sitemap.xml
   ```
   - 예상: `HTTP: 200`

2. **sitemap.xml 유효성 검사**
   ```bash
   curl -s https://silmu.kr/sitemap.xml | head -30
   ```
   - ✅ 첫 줄이 `<?xml version="1.0" encoding="UTF-8"?>`인지 확인 (주석이나 공백 없이)
   - ✅ `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">` 네임스페이스 확인
   - ✅ 각 `<url>` 태그에 `<loc>`, `<lastmod>`, `<changefreq>`, `<priority>` 포함 확인

3. **sitemap URL들 응답 확인 (샘플링)**
   ```bash
   # sitemap에서 처음 5개 URL 추출 후 각각 테스트
   curl -s https://silmu.kr/sitemap.xml | grep -oP '(?<=<loc>)[^<]+' | head -5 | while read url; do
     echo "Testing: $url"
     curl -s -o /dev/null -w '%{http_code}\n' "$url"
   done
   ```
   - 모든 URL이 200 응답하는지 확인 (soft 404 방지)

### 2단계: robots.txt 검증

1. **robots.txt 접근 확인**
   ```bash
   curl -s https://silmu.kr/robots.txt
   ```
   - ✅ 200 응답
   - ✅ `Sitemap: https://silmu.kr/sitemap.xml` 라인 포함 확인
   - ✅ 중요한 경로가 Disallow되지 않았는지 확인

### 3단계: ads.txt 검증

1. **ads.txt 접근 확인**
   ```bash
   curl -s https://silmu.kr/ads.txt
   ```
   - ✅ 200 응답
   - ✅ AdSense 게시자 ID 포함 확인: `google.com, pub-6241798439911569, DIRECT, f08c47fec0942fa0`

### 4단계: Meta Tags 검증

1. **메인 페이지 meta tags**
   ```bash
   curl -s https://silmu.kr | grep -E "<title>|<meta name=|<meta property="
   ```
   - ✅ `<title>` 태그 존재 및 적절한 길이 (50-60자)
   - ✅ `<meta name="description">` 존재 및 적절한 길이 (150-160자)
   - ✅ `<meta property="og:title">` (Open Graph)
   - ✅ `<meta property="og:description">`
   - ✅ `<meta property="og:image">`
   - ✅ `<meta property="og:url">`
   - ✅ `<meta name="viewport">` (모바일 반응형)
   - ✅ `<link rel="canonical">` (중복 콘텐츠 방지)

### 5단계: Structured Data (Schema) 검증

1. **JSON-LD schema 확인**
   ```bash
   curl -s https://silmu.kr | grep -A 20 'application/ld+json'
   ```
   - ✅ `<script type="application/ld+json">` 존재
   - ✅ `@type`: `WebSite`, `Organization`, `Article` 등 적절한 타입
   - ✅ 유효한 JSON 형식

### 6단계: 검색엔진 Verification Tags 확인

1. **Google Search Console verification**
   ```bash
   curl -s https://silmu.kr | grep -i "google-site-verification"
   ```
   - ✅ `<meta name="google-site-verification" content="...">` 존재

2. **Naver Search Advisor verification**
   ```bash
   curl -s https://silmu.kr | grep -i "naver-site-verification"
   ```
   - ✅ `<meta name="naver-site-verification" content="...">` 존재

### 7단계: IndexNow Key 파일 확인

1. **IndexNow key 파일 접근**
   ```bash
   # IndexNow key 파일이 있다면 (예: {key}.txt)
   # curl -s -o /dev/null -w '%{http_code}\n' https://silmu.kr/{key}.txt
   echo "IndexNow key 파일 확인 필요 시 수동 체크"
   ```

### 8단째: 모바일 친화성 확인

1. **viewport meta tag**
   ```bash
   curl -s https://silmu.kr | grep -i "viewport"
   ```
   - ✅ `<meta name="viewport" content="width=device-width, initial-scale=1">`

2. **반응형 CSS 확인**
   ```bash
   curl -s https://silmu.kr | grep -i "media="
   ```
   - CSS에 media query 사용 확인

### 9단계: 페이지 속도 확인

1. **응답 시간 측정**
   ```bash
   curl -w "\n응답 시간: %{time_total}s\n" -o /dev/null -s https://silmu.kr
   ```
   - ✅ 2초 이하 권장
   - ⚠️ 2-5초: 개선 필요
   - ❌ 5초 이상: 심각한 성능 문제

2. **페이지 크기 확인**
   ```bash
   curl -s https://silmu.kr | wc -c
   ```
   - ✅ 1MB 이하 권장

### 10단계: Soft 404 확인

**Soft 404란?** 존재하지 않는 페이지가 404 대신 200 OK를 반환하는 문제 (검색엔진이 잘못된 페이지를 색인)

1. **존재하지 않는 경로 테스트**
   ```bash
   curl -s -o /dev/null -w '%{http_code}\n' https://silmu.kr/this-does-not-exist-12345
   ```
   - ✅ 404 응답
   - ❌ 200 응답 → soft 404 문제 (Rails routes 설정 확인 필요)

2. **Deprecated routes 확인**
   ```bash
   # 과거에 사용했지만 현재는 없는 경로
   # 인사이트 리포트에서 언급된 사례: /chatbot
   for path in "/chatbot" "/old-guide" "/deprecated"; do
     code=$(curl -s -o /dev/null -w '%{http_code}' "https://silmu.kr$path")
     echo "$path: $code"
   done
   ```
   - ✅ 404 (삭제됨) 또는 301 (리다이렉트)
   - ❌ 200 → soft 404 문제

3. **Google Search Console에서 확인**
   - Coverage 리포트에서 "Submitted URL seems to be a Soft 404" 에러 확인
   - 발견 시 해당 URL을 sitemap에서 제거하고 404 응답하도록 수정

### 11단계: SSL/HTTPS 확인

1. **SSL 인증서 유효성**
   ```bash
   curl -vI https://silmu.kr 2>&1 | grep -E "SSL certificate|expire"
   ```
   - ✅ SSL 인증서 유효
   - ⚠️ 만료일 확인 (30일 이내면 경고)

2. **HTTP → HTTPS 리다이렉트 확인**
   ```bash
   curl -s -o /dev/null -w '%{http_code}\n' -L http://silmu.kr
   ```
   - ✅ 최종적으로 HTTPS로 리다이렉트되어야 함

---

## 결과 보고 형식

```
🔍 SEO 감사 결과: silmu.kr

✅ Sitemap (5/5 통과)
   - sitemap.xml 접근: 200 OK
   - XML 유효성: 통과
   - 샘플 URL 응답: 5/5 OK
   - 첫 줄 형식: 올바름
   - 네임스페이스: 올바름

✅ robots.txt (3/3 통과)
   - 접근: 200 OK
   - Sitemap 링크: 포함됨
   - 중요 경로 차단: 없음

✅ ads.txt (2/2 통과)
   - 접근: 200 OK
   - AdSense ID: 확인됨 (pub-6241798439911569)

✅ Meta Tags (8/8 통과)
   - title: 있음 (52자)
   - description: 있음 (158자)
   - og:title: 있음
   - og:description: 있음
   - og:image: 있음
   - og:url: 있음
   - viewport: 있음
   - canonical: 있음

✅ Structured Data (2/2 통과)
   - JSON-LD schema: 있음
   - 타입: WebSite, Organization

✅ 검색엔진 Verification (2/2 통과)
   - Google Search Console: 확인됨
   - Naver Search Advisor: 확인됨

✅ 모바일 친화성 (2/2 통과)
   - viewport meta: 있음
   - 반응형 CSS: 확인됨

✅ 페이지 속도 (2/2 통과)
   - 응답 시간: 0.8초
   - 페이지 크기: 450KB

✅ Soft 404 (2/2 통과)
   - 존재하지 않는 경로: 404 OK
   - Deprecated routes: 404 OK

✅ SSL/HTTPS (2/2 통과)
   - SSL 인증서: 유효 (만료: 2026-05-20)
   - HTTP 리다이렉트: 정상

━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 전체 점수: 32/32 (100%)
✅ SEO 상태: 우수
```

문제가 있는 경우:
```
⚠️ 발견된 문제:
1. Meta description 누락 (메인 페이지)
2. Sitemap URL 중 3개가 404 응답
3. 응답 시간 3.2초 (권장: 2초 이하)

🔧 권장 조치:
1. app/views/layouts/application.html.erb에 meta description 추가
2. sitemap.xml에서 404 URL 제거
3. 페이지 속도 최적화 필요 (이미지 압축, CSS/JS 번들링)
```

---

## 주의사항

- **Google Search Console에서 직접 확인:** 이 스킬은 자동 감사이므로, 실제 인덱싱 상태는 Google Search Console에서 확인 필요
- **Naver Search Advisor에서 직접 확인:** Naver 검색 등록 상태는 Naver Search Advisor에서 확인
- **IndexNow API 사용:** sitemap 업데이트 후 IndexNow API로 Google/Bing/Naver에 알림 (deprecated ping API 사용 금지)
- **과거 실수 방지:**
  - Google/Naver ping API는 deprecated (작동하지 않음) — 최소 3회 시도 사례 있음
  - Google Search Console에 "sitemap 삭제 버튼"은 존재하지 않음 (잘못된 안내 사례 있음)
  - Sitemap XML 첫 줄은 주석 없이 `<?xml version="1.0" encoding="UTF-8"?>`로 시작해야 함

---

## 주기적 실행 권장

- **매주 1회:** SEO 상태 전체 점검
- **배포 후:** sitemap, meta tags, schema 변경 시 필수 점검
- **Google/Naver 업데이트 후:** 검색엔진 알고리즘 변경 시 재점검
