# 빠른 라이브 검증 (silmu.kr)

이 스킬은 배포 후 또는 긴급 상황에서 silmu.kr이 정상 작동하는지 빠르게 확인합니다.

## 실행 순서 (소요 시간: ~30초)

### 1단계: HTTP 상태 확인 (5초)

```bash
echo "🔍 HTTP 상태 확인..."
curl -s -o /dev/null -w 'HTTP: %{http_code}\nTime: %{time_total}s\n' https://silmu.kr
```

**기대 결과:**
- `HTTP: 200`
- `Time: 2.0s` 이하

**실패 시:**
- 200이 아니면 즉시 중단하고 사용자에게 경고
- 5초 이상 걸리면 성능 이슈 경고

---

### 2단계: 핵심 엔드포인트 확인 (10초)

```bash
echo "🔍 핵심 엔드포인트 확인..."

# 메인 페이지
curl -s -o /dev/null -w 'Main: %{http_code}\n' https://silmu.kr

# sitemap.xml (SEO 중요)
curl -s -o /dev/null -w 'Sitemap: %{http_code}\n' https://silmu.kr/sitemap.xml

# robots.txt
curl -s -o /dev/null -w 'Robots: %{http_code}\n' https://silmu.kr/robots.txt

# ads.txt (AdSense)
curl -s -o /dev/null -w 'Ads.txt: %{http_code}\n' https://silmu.kr/ads.txt
```

**기대 결과:**
- 모두 `200`

---

### 3단계: 애플리케이션 로그 확인 (5초)

```bash
echo "🔍 최근 로그 확인..."
cd ~/silmu && kamal app logs --tail 20
```

**확인 사항:**
- ❌ `ERROR`, `FATAL`, `Exception` 키워드 없는지 확인
- ⚠️ `WARN` 키워드는 맥락 파악 후 판단
- ✅ `INFO` 레벨 로그는 정상

---

### 4단계: Solid Queue 상태 확인 (5초)

```bash
echo "🔍 Solid Queue 상태 확인..."
cd ~/silmu && kamal app exec 'ps aux | grep -E "solid_queue|puma"'
```

**기대 결과:**
- `solid_queue` 프로세스 실행 중
- `puma` 프로세스 실행 중

**실패 시:**
- Solid Queue가 없으면 백그라운드 잡이 실행되지 않음 (경고)

---

### 5단계: SSL 인증서 확인 (5초)

```bash
echo "🔍 SSL 인증서 확인..."
curl -vI https://silmu.kr 2>&1 | grep -E "SSL|subject|expire" | head -5
```

**기대 결과:**
- SSL 연결 성공
- 인증서 유효 (만료일이 현재보다 미래)

---

### 6단계: 데이터베이스 연결 확인 (5초)

```bash
echo "🔍 데이터베이스 연결 확인..."
cd ~/silmu && kamal app exec -i 'rails runner "puts User.count rescue \"DB Error\""'
```

**기대 결과:**
- 숫자 출력 (예: `42`)
- `DB Error`가 출력되면 데이터베이스 연결 실패

---

## 결과 보고 형식

### 성공 시

```
✅ silmu.kr 라이브 검증 완료

📋 검증 결과:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ HTTP 상태: 200 OK (0.8초)
✅ 핵심 엔드포인트:
   - Main: 200
   - Sitemap: 200
   - Robots: 200
   - Ads.txt: 200
✅ 로그: 에러 없음
✅ Solid Queue: 실행 중
✅ Puma: 실행 중
✅ SSL 인증서: 유효 (만료: 2026-05-20)
✅ DB 연결: 정상 (42 users)

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 시스템 상태: 정상
⏱️ 검증 시간: 28초
```

### 문제 발견 시

```
❌ silmu.kr 라이브 검증 실패

📋 발견된 문제:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ HTTP 상태: 502 Bad Gateway
⚠️ 로그: 3개의 에러 발견
   - Puma worker timeout
   - ActiveRecord::ConnectionTimeoutError
   - 500 Internal Server Error on /guides/123
❌ Solid Queue: 프로세스 없음

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 시스템 상태: 장애

🔧 긴급 조치:
1. 롤백 권장: cd ~/silmu && kamal rollback
2. 로그 상세 확인: kamal app logs --tail 100
3. 컨테이너 재시작 (롤백 실패 시): kamal app restart

⚠️ 주의: 수동 Docker 명령 사용 금지 (연쇄 장애 방지)
```

---

## 사용 사례

### 1. 배포 직후 빠른 검증
```bash
# deploy 스킬 실행 후
/verify-live
```

### 2. 장애 의심 시 현황 파악
```bash
# 사용자 제보나 모니터링 알림 후
/verify-live
```

### 3. 정기 헬스체크
```bash
# 매일 오전/오후 1회씩
/verify-live
```

### 4. DNS/SSL 변경 후 확인
```bash
# DNS 레코드 변경, SSL 인증서 갱신 후
/verify-live
```

---

## deploy 스킬과의 차이점

| 항목 | /deploy | /verify-live |
|------|---------|--------------|
| **소요 시간** | 5-10분 | ~30초 |
| **배포 여부** | 배포 수행 | 검증만 |
| **테스트 실행** | ✅ | ❌ |
| **상세 검증** | ✅ (DNS/SEO 포함) | 핵심만 |
| **용도** | 배포 프로세스 | 빠른 헬스체크 |

---

## 자동화 스크립트 (선택)

전체 검증을 한 번에 실행:

```bash
#!/bin/bash
# ~/silmu/scripts/verify-live.sh

echo "🔍 silmu.kr 라이브 검증 시작..."
echo ""

# 1. HTTP 상태
echo "1️⃣ HTTP 상태 확인"
curl -s -o /dev/null -w 'HTTP: %{http_code}\nTime: %{time_total}s\n' https://silmu.kr
echo ""

# 2. 핵심 엔드포인트
echo "2️⃣ 핵심 엔드포인트 확인"
for path in "" "/sitemap.xml" "/robots.txt" "/ads.txt"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://silmu.kr$path")
  echo "  $path: $code"
done
echo ""

# 3. 로그
echo "3️⃣ 최근 로그 (에러 확인)"
cd ~/silmu && kamal app logs --tail 10 | grep -i error || echo "  에러 없음"
echo ""

# 4. 프로세스
echo "4️⃣ Solid Queue & Puma 상태"
cd ~/silmu && kamal app exec 'ps aux | grep -E "solid_queue|puma" | grep -v grep | wc -l' | xargs -I {} echo "  실행 중인 프로세스: {}"
echo ""

# 5. SSL
echo "5️⃣ SSL 인증서 확인"
curl -vI https://silmu.kr 2>&1 | grep "expire" | head -1
echo ""

# 6. DB
echo "6️⃣ 데이터베이스 연결 확인"
cd ~/silmu && kamal app exec -i 'rails runner "puts \"Users: #{User.count}\""' 2>&1 | tail -1
echo ""

echo "✅ 검증 완료"
```

실행:
```bash
chmod +x ~/silmu/scripts/verify-live.sh
~/silmu/scripts/verify-live.sh
```

---

## 주의사항

- **빠른 검증이 목적:** 상세 SEO 검증은 `/seo-check` 사용
- **배포 전 테스트는 불포함:** 배포는 `/deploy` 사용
- **긴급 상황 대응:** 장애 의심 시 빠른 현황 파악용
- **정기 실행 권장:** cron으로 하루 2회 실행하여 조기 장애 감지

### 과거 장애 사례 참고
- **502 Bad Gateway:** RAILS_MAX_THREADS=2 설정으로 DB 커넥션 풀 고갈
- **Solid Queue 사망:** 메모리 부족 또는 RAILS_MAX_THREADS 설정 오류
- **수동 컨테이너 재시작 실패:** 프록시 라우팅 누락, DB 데이터 손실

이 스킬로 빠르게 현황을 파악하고, 문제가 있으면 `/rollback` 스킬 사용
