# Deploy to Production (silmu.kr)

이 스킬은 silmu.kr 프로젝트를 안전하게 운영 환경에 배포합니다.

## 실행 순서

### 1단계: 배포 전 검증

1. **현재 Git 상태 확인**
   ```bash
   git status
   ```
   - 커밋되지 않은 변경사항이 있으면 배포 중단
   - 사용자에게 변경사항 커밋 또는 스테이시 요청

2. **테스트 실행**
   ```bash
   cd ~/silmu && rails test
   ```
   - 테스트 실패 시 배포 중단
   - 실패한 테스트 목록과 에러 메시지 출력

3. **RAILS_MAX_THREADS 확인**
   ```bash
   grep -r "RAILS_MAX_THREADS" ~/silmu/config/deploy.yml ~/silmu/.kamal/secrets
   ```
   - **5 미만이면 경고 메시지 출력** (DB 커넥션 풀 고갈 위험)
   - 과거 RAILS_MAX_THREADS=2 설정으로 502 에러 발생 사례 있음
   - 권장: 5 이상 (Solid Queue + Puma 동시 사용 시)
   - 계속 진행 여부를 사용자에게 확인

### 2단계: 배포 실행

1. **Kamal 배포**
   ```bash
   cd ~/silmu && kamal deploy
   ```
   - 배포 출력을 모니터링
   - 에러 발생 시 즉시 중단하고 사용자에게 보고

2. **배포 완료 대기**
   - 배포가 완료될 때까지 대기 (일반적으로 2-5분 소요)

### 3단계: 배포 후 검증 (CRITICAL)

**이 단계는 필수입니다. 생략하지 마세요.**

1. **HTTP 상태 확인 (Retry Logic)**
   ```bash
   # 5번 재시도 (10초 간격)
   for i in {1..5}; do
     HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' https://silmu.kr)
     if [ "$HTTP_CODE" = "200" ]; then
       echo "✅ HTTP 200 OK (attempt $i)"
       break
     else
       echo "⚠️ HTTP $HTTP_CODE (attempt $i/5)"
       if [ $i -lt 5 ]; then
         sleep 10
       fi
     fi
   done
   ```
   - 예상 결과: 최종적으로 `200`
   - 5번 모두 실패하면 즉시 사용자에게 보고하고 **자동 롤백 실행**

2. **주요 페이지 확인**
   ```bash
   # 메인 페이지
   curl -s https://silmu.kr | head -20

   # sitemap.xml (SEO 중요)
   curl -s -o /dev/null -w '%{http_code}\n' https://silmu.kr/sitemap.xml

   # robots.txt
   curl -s -o /dev/null -w '%{http_code}\n' https://silmu.kr/robots.txt
   ```
   - 각 페이지가 정상적으로 응답하는지 확인

3. **애플리케이션 로그 확인**
   ```bash
   cd ~/silmu && kamal app logs --tail 50
   ```
   - 최근 50줄의 로그에서 에러나 경고 확인
   - 에러가 있으면 사용자에게 보고

4. **Solid Queue 상태 확인**
   ```bash
   cd ~/silmu && kamal app exec 'ps aux | grep solid_queue'
   ```
   - Solid Queue 프로세스가 실행 중인지 확인
   - 실행되지 않으면 경고 출력

5. **SSL 인증서 확인**
   ```bash
   curl -vI https://silmu.kr 2>&1 | grep -i "ssl\|certificate"
   ```
   - SSL 인증서가 유효한지 확인

6. **응답 시간 확인**
   ```bash
   curl -w "\nTime total: %{time_total}s\n" -o /dev/null -s https://silmu.kr
   ```
   - 응답 시간이 2초 이상이면 경고 (성능 이슈 가능성)

### 4단계: DNS/SEO 변경사항 확인 (해당하는 경우만)

배포에 다음 변경사항이 포함된 경우 추가 검증:

1. **DNS verification 코드 변경**
   ```bash
   curl -s https://silmu.kr | grep -E "google-site-verification|naver-site-verification"
   ```
   - 새 verification 태그가 HTML에 포함되었는지 확인

2. **sitemap.xml 업데이트**
   ```bash
   curl -s https://silmu.kr/sitemap.xml | head -20
   ```
   - sitemap이 유효한 XML인지 확인
   - 첫 줄이 `<?xml version="1.0" encoding="UTF-8"?>`인지 확인 (주석이나 공백 없이)

3. **ads.txt 변경**
   ```bash
   curl -s https://silmu.kr/ads.txt
   ```
   - AdSense 게시자 ID가 올바른지 확인 (ca-pub-6241798439911569)

4. **robots.txt 변경**
   ```bash
   curl -s https://silmu.kr/robots.txt
   ```
   - Disallow 규칙이 의도대로 적용되었는지 확인

### 5단계: 결과 보고

배포 결과를 다음 형식으로 사용자에게 보고:

```
✅ 배포 완료: silmu.kr

📋 검증 결과:
- HTTP 상태: 200 OK
- 메인 페이지: 정상
- sitemap.xml: 200 OK
- robots.txt: 200 OK
- 애플리케이션 로그: 에러 없음
- Solid Queue: 실행 중
- SSL 인증서: 유효
- 응답 시간: 0.8초

[DNS/SEO 변경사항이 있었다면]
- Google verification 태그: 확인됨
- sitemap.xml: 유효한 XML, 최신 URL 포함
- ads.txt: AdSense ID 확인됨

🔗 배포된 사이트: https://silmu.kr
📊 로그 확인: kamal app logs --tail 100
```

에러가 있었다면:
```
❌ 배포 실패 또는 검증 실패

문제:
- [구체적인 문제 설명]

롤백 권장:
cd ~/silmu && kamal rollback
```

---

## 롤백 절차 (배포 실패 시)

배포가 실패하거나 검증에서 문제가 발견된 경우:

```bash
cd ~/silmu && kamal rollback
```

롤백 후 동일한 검증 단계를 재수행하여 이전 버전으로 정상 복구되었는지 확인.

---

## 주의사항

1. **테스트 실패 시 절대 배포하지 않음**
2. **커밋되지 않은 변경사항이 있으면 배포하지 않음** (Kamal은 커밋된 코드만 배포)
3. **HTTP 200이 아니면 즉시 롤백 권장**
4. **배포 후 검증을 건너뛰지 않음** — 이 단계가 가장 중요함
5. **DNS/SEO 변경사항은 반드시 라이브 환경에서 확인** — Google Search Console, Naver Search Advisor에서 실제 적용 여부 확인

---

## 과거 발생한 이슈 (재발 방지)

### Critical (반드시 방지)
- **RAILS_MAX_THREADS=2 설정 → 502 에러 대란**
  - DB 커넥션 풀 고갈로 Solid Queue 크래시
  - 연쇄적으로 502 Bad Gateway, SSH forwarding 실패, 복구에 수시간 소요
  - **해결:** 항상 RAILS_MAX_THREADS >= 5 유지

- **수동 컨테이너 재시작 → 연쇄 장애**
  - Docker 명령 수동 실행 시 프록시 라우팅 누락, DB 데이터 손실
  - **해결:** `kamal app restart`만 사용, 수동 Docker 명령 절대 금지

### High (빈번히 발생)
- **변경사항 커밋 후 배포 누락** (다수 발생)
  - Naver verification, sitemap, AdSense 스크립트 변경 후 배포 누락
  - **해결:** 이 스킬의 1단계에서 자동으로 커밋 여부 확인

- **배포 후 검증 생략**
  - 배포 성공으로 판단했으나 실제로는 변경사항 미적용
  - **해결:** 3단계 검증 절대 생략 금지

### Medium
- **로컬 DB 조회 실수** (최소 2회)
  - 운영 데이터 확인 시 로컬 개발 DB를 조회
  - **해결:** Database 섹션의 "ALWAYS PRODUCTION" 규칙 준수

---

## 빠른 실행 (자동화)

전체 프로세스를 자동으로 실행:

```bash
cd ~/silmu && \
git status && \
rails test && \
kamal deploy && \
sleep 30 && \
curl -s -o /dev/null -w 'HTTP: %{http_code}\nTime: %{time_total}s\n' https://silmu.kr && \
kamal app logs --tail 20
```

단, 이 자동화 스크립트는 에러 발생 시 즉시 중단되지 않으므로 각 단계를 수동으로 확인하는 것을 권장합니다.
