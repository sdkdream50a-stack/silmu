# 안전한 롤백 (silmu.kr)

이 스킬은 배포 실패 또는 장애 발생 시 silmu.kr을 이전 버전으로 안전하게 롤백합니다.

## 실행 순서

### 1단계: 현재 상태 진단

롤백 전 현재 시스템 상태를 파악하여 롤백 필요 여부를 확인합니다.

```bash
echo "🔍 현재 시스템 상태 진단..."
```

1. **HTTP 상태 확인**
   ```bash
   curl -s -o /dev/null -w 'HTTP: %{http_code}\n' https://silmu.kr
   ```

2. **최근 로그 확인 (에러 여부)**
   ```bash
   cd ~/silmu && kamal app logs --tail 30 | grep -i -E "error|fatal|exception"
   ```

3. **프로세스 상태 확인**
   ```bash
   cd ~/silmu && kamal app exec 'ps aux | grep -E "solid_queue|puma"'
   ```

**진단 결과 보고:**
```
📊 현재 상태:
- HTTP 상태: 502 Bad Gateway ❌
- 최근 에러: 5건 발견 ⚠️
- Solid Queue: 실행 중 ✅
- Puma: 실행 중 ✅

🔴 롤백 필요: HTTP 502 에러 발생 중
```

만약 모든 항목이 정상이면:
```
📊 현재 상태:
- HTTP 상태: 200 OK ✅
- 최근 에러: 없음 ✅
- Solid Queue: 실행 중 ✅
- Puma: 실행 중 ✅

✅ 시스템 정상 — 롤백 불필요

계속 진행하시겠습니까? (y/N)
```

---

### 2단계: 사용자 확인

**롤백은 되돌릴 수 없는 작업이므로 반드시 사용자에게 확인:**

```
⚠️  롤백 확인

다음 작업을 수행합니다:
1. 현재 버전 → 이전 버전으로 롤백
2. 롤백 후 자동 검증 실행
3. 롤백은 되돌릴 수 없습니다

계속하시겠습니까? (y/N)
```

사용자가 `y` 또는 `yes`를 입력하면 진행, 그 외는 중단.

---

### 3단계: 롤백 실행

```bash
echo "🔄 롤백 시작..."
cd ~/silmu && kamal rollback
```

**롤백 프로세스:**
1. 이전 Docker 이미지로 전환
2. 컨테이너 재시작
3. 프록시 라우팅 업데이트
4. 헬스체크 대기 (~30초)

**롤백 출력 모니터링:**
- 에러 발생 시 즉시 사용자에게 보고
- 성공 시 다음 단계로 진행

---

### 4단계: 롤백 후 검증 (CRITICAL)

롤백이 성공적으로 완료되었는지 검증합니다.

```bash
echo "✅ 롤백 완료. 검증 시작..."
sleep 10  # 서비스 안정화 대기
```

1. **HTTP 상태 확인**
   ```bash
   curl -s -o /dev/null -w 'HTTP: %{http_code}\nTime: %{time_total}s\n' https://silmu.kr
   ```
   - ✅ 200 OK (롤백 성공)
   - ❌ 200이 아니면 추가 조치 필요

2. **핵심 엔드포인트 확인**
   ```bash
   for path in "" "/sitemap.xml" "/robots.txt" "/ads.txt"; do
     code=$(curl -s -o /dev/null -w '%{http_code}' "https://silmu.kr$path")
     echo "$path: $code"
   done
   ```

3. **로그 확인 (에러 없는지)**
   ```bash
   cd ~/silmu && kamal app logs --tail 20 | grep -i -E "error|fatal|exception"
   ```
   - 에러가 없으면 성공

4. **Solid Queue 상태 확인**
   ```bash
   cd ~/silmu && kamal app exec 'ps aux | grep solid_queue'
   ```

5. **데이터베이스 연결 확인**
   ```bash
   cd ~/silmu && kamal app exec -i 'rails runner "puts User.count"'
   ```

---

### 5단계: 결과 보고

#### 롤백 성공 시

```
✅ 롤백 성공

📋 검증 결과:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ HTTP 상태: 200 OK (0.9초)
✅ 핵심 엔드포인트: 모두 200 OK
✅ 로그: 에러 없음
✅ Solid Queue: 실행 중
✅ DB 연결: 정상 (42 users)

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 이전 버전으로 정상 복구됨

📌 다음 단계:
1. 배포 실패 원인 분석
2. 로컬에서 수정 및 테스트
3. 다시 배포 시도
```

#### 롤백 실패 시

```
❌ 롤백 실패 또는 검증 실패

📋 검증 결과:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ HTTP 상태: 502 Bad Gateway
⚠️ 로그: 에러 계속 발생
   - Puma worker timeout
   - ActiveRecord::ConnectionTimeoutError
❌ Solid Queue: 프로세스 없음

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 롤백 후에도 문제 지속

🔧 긴급 조치:
1. 컨테이너 완전 재시작:
   cd ~/silmu && kamal app restart

2. 그래도 실패 시 수동 진단:
   ssh root@141.164.53.97
   docker ps -a
   docker logs [container_id]

3. DB 연결 확인:
   psql 접속하여 연결 테스트

⚠️ 주의: 수동 Docker 명령 사용은 최후의 수단
```

---

## 롤백 시나리오별 대응

### 시나리오 1: 배포 직후 502 에러

**원인:** 새 버전에 버그 또는 설정 오류

**대응:**
```bash
# 즉시 롤백
/rollback

# 로컬에서 문제 수정
git log -1  # 문제가 있는 커밋 확인
git revert HEAD  # 또는 수동 수정
rails test  # 테스트 통과 확인

# 재배포
/deploy
```

---

### 시나리오 2: DB 마이그레이션 실패

**원인:** 마이그레이션 에러로 DB 스키마 불일치

**대응:**
```bash
# 1. 롤백 (코드만 롤백, DB는 유지됨)
/rollback

# 2. DB 마이그레이션 롤백 (필요 시)
cd ~/silmu && kamal app exec -i 'rails db:rollback STEP=1'

# 3. 로컬에서 마이그레이션 수정
# 4. 재배포
/deploy
```

⚠️ **주의:** DB 마이그레이션 롤백은 데이터 손실 위험이 있으므로 신중히 진행

---

### 시나리오 3: RAILS_MAX_THREADS 설정 오류 (실제 발생 사례)

**원인:** RAILS_MAX_THREADS=2로 설정하여 DB 커넥션 풀 고갈 → Solid Queue 크래시 → 502 에러 대란

**증상:**
- 502 Bad Gateway 연속 발생
- Solid Queue 프로세스 사망
- SSH forwarding 실패
- 복구에 수시간 소요

**대응:**
```bash
# 1. 즉시 롤백
/rollback

# 2. 설정 확인 및 수정
# config/deploy.yml 또는 .kamal/secrets에서 RAILS_MAX_THREADS >= 5 확인
# (Solid Queue + Puma 동시 사용 시 권장: 5 이상)

# 3. 로컬에서 테스트
rails test

# 4. 재배포
/deploy
```

**예방:**
- `/deploy` 스킬 1단계에서 자동으로 RAILS_MAX_THREADS 검증

---

### 시나리오 4: 환경변수 누락

**원인:** `.kamal/secrets` 파일에 필수 환경변수 누락

**대응:**
```bash
# 1. 롤백
/rollback

# 2. 환경변수 추가
# .kamal/secrets 파일 수정 (RAILS_MASTER_KEY, ANTHROPIC_API_KEY 등)

# 3. 재배포
/deploy
```

---

### 시나리오 5: Solid Queue 프로세스 사망

**원인:** 메모리 부족 또는 설정 오류

**대응:**
```bash
# 1. 롤백
/rollback

# 2. Solid Queue 설정 확인
# config/queue.yml 또는 SOLID_QUEUE_IN_PUMA 설정 확인

# 3. 재배포
/deploy
```

---

## 롤백 불가 상황 (최후의 수단)

롤백도 실패하고 시스템이 완전히 다운된 경우:

### 1. 컨테이너 완전 재시작

```bash
cd ~/silmu && kamal app restart
```

### 2. 수동 Docker 진단

```bash
ssh root@141.164.53.97

# 컨테이너 목록 확인
docker ps -a

# 로그 확인
docker logs [container_id]

# 컨테이너 재시작 (최후의 수단)
docker restart [container_id]
```

⚠️ **경고:** 수동 Docker 명령은 연쇄 장애를 유발할 수 있으므로 최후의 수단으로만 사용

### 3. DB 연결 문제 진단

```bash
ssh root@141.164.53.97
psql -U postgres -d silmu_production

# 연결 수 확인
SELECT count(*) FROM pg_stat_activity;

# 연결 종료 (위험)
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'silmu_production';
```

---

## 롤백 후 체크리스트

롤백 성공 후 다음을 확인:

- [ ] HTTP 200 응답
- [ ] 핵심 엔드포인트 정상
- [ ] 로그에 에러 없음
- [ ] Solid Queue 실행 중
- [ ] DB 연결 정상
- [ ] SSL 인증서 유효
- [ ] 사용자가 사이트 정상 이용 가능

---

## 주의사항

1. **롤백은 코드만 되돌림:** DB 스키마는 유지되므로 마이그레이션 롤백이 필요하면 별도로 수행
2. **롤백 전 백업 권장:** 중요한 DB 변경이 있었다면 롤백 전 DB 백업
3. **롤백은 긴급 조치:** 근본 원인을 해결하고 재배포해야 함
4. **롤백도 실패하면:** 수동 진단 및 복구 필요 (서버 접속)
5. **과거 성공 사례 참고:** 과거 배포 기록을 확인하여 안정적인 버전으로 롤백

### 실제 발생한 롤백 사례 (학습 자료)

#### 사례 1: RAILS_MAX_THREADS=2 설정 (Critical)
- **증상:** 502 에러, Solid Queue 크래시, DB 커넥션 풀 고갈
- **조치:** 즉시 롤백 → 설정 수정 (RAILS_MAX_THREADS >= 5) → 재배포
- **소요 시간:** 수시간 (SSH forwarding 문제로 복구 지연)
- **교훈:** 성능 최적화는 반드시 테스트 후 점진적으로 적용

#### 사례 2: 수동 컨테이너 재시작 (High)
- **증상:** 502 에러, DB 데이터 손실, 프록시 라우팅 누락
- **조치:** 롤백 시도했으나 이미 데이터 손실, 수동 복구 필요
- **소요 시간:** 다수 시간
- **교훈:** 수동 Docker 명령 절대 금지, `kamal app restart`만 사용

#### 사례 3: 배포 후 검증 생략
- **증상:** sitemap, AdSense 스크립트 미적용, 검색엔진 색인 실패
- **조치:** 롤백 후 재배포 (검증 포함)
- **소요 시간:** 약 1시간
- **교훈:** `/deploy` 스킬의 3단계 검증 절대 생략 금지

---

## 자동화 스크립트 (선택)

전체 롤백 프로세스를 스크립트로 실행:

```bash
#!/bin/bash
# ~/silmu/scripts/safe-rollback.sh

set -e  # 에러 발생 시 즉시 중단

echo "🔍 현재 상태 진단..."
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' https://silmu.kr)
echo "HTTP: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 시스템 정상. 롤백 불필요."
  read -p "그래도 롤백하시겠습니까? (y/N): " confirm
  if [ "$confirm" != "y" ]; then
    echo "롤백 취소."
    exit 0
  fi
fi

echo ""
echo "⚠️  롤백을 시작합니다."
read -p "계속하시겠습니까? (y/N): " confirm
if [ "$confirm" != "y" ]; then
  echo "롤백 취소."
  exit 0
fi

echo ""
echo "🔄 롤백 실행..."
cd ~/silmu && kamal rollback

echo ""
echo "⏳ 서비스 안정화 대기 (10초)..."
sleep 10

echo ""
echo "✅ 롤백 완료. 검증 시작..."
NEW_HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' https://silmu.kr)
echo "HTTP: $NEW_HTTP_CODE"

if [ "$NEW_HTTP_CODE" = "200" ]; then
  echo "✅ 롤백 성공! 시스템 정상 복구됨."
else
  echo "❌ 롤백 후에도 문제 지속 (HTTP: $NEW_HTTP_CODE)"
  echo "긴급 조치 필요: kamal app restart"
fi
```

실행:
```bash
chmod +x ~/silmu/scripts/safe-rollback.sh
~/silmu/scripts/safe-rollback.sh
```
