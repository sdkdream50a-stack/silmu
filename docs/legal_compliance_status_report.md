# 법령 정합성 자동 검증 시스템 상태 보고서

**보고일시**: 2026-02-13
**검증 대상**: 실무.kr 법령 콘텐츠 (토픽, 감사사례 등)
**기준 법령**: 지방계약법, 공무원여비규정 등

---

## 📊 현재 구축 현황

### ✅ 구축 완료 항목

#### 1. 법령 기준 데이터베이스 (`config/legal_standards.yml`)
- **최종 업데이트**: 2026-02-04
- **포함 법령**:
  - 지방계약법 시행령 (2025-07-08 개정)
  - 공무원여비규정 (2026-01-02 개정)
- **관리 항목**:
  - 수의계약 한계금액 (1인/2인 견적, 공사/물품/용역)
  - 출장 여비 기준 (숙박비, 식비, 일비)
  - 계약보증금 면제 한도
  - 전자입찰 필수 금액

#### 2. 자동 검증 서비스 (`app/services/regulation_verifier.rb`)
- **기능**:
  - Anthropic Claude API 연동
  - 토픽 콘텐츠 법령 정합성 자동 검증
  - 금액/날짜/비율 자동 추출 및 검증
  - 불일치 항목 자동 수정 기능
- **검증 대상 필드**:
  - `law_content` (법률 조항)
  - `decree_content` (시행령 조항)
  - `rule_content` (시행규칙)
  - `regulation_content` (지침/예규)
  - `practical_tips` (실무 팁)

#### 3. Rake 태스크 (`lib/tasks/legal_update.rake`)
- **제공 명령어**:
  ```bash
  rake legal:check          # 검증만 수행
  rake legal:update         # 검증 + 자동 수정
  rake legal:report         # 검증 보고서 생성
  rake legal:scan           # 법령 관련 파일 스캔
  rake legal:sources        # 법령 출처 URL 확인
  rake legal:ci_check       # GitHub Actions용 검증
  ```
- **자동 스캔 범위**: 91개 파일
  - Controllers: 17개
  - Services: 13개
  - Views: 44개
  - Seeds: 17개

#### 4. CLI 실행 스크립트 (`bin/legal_check`)
- **기능**:
  - 검증, 수정, 커밋, 푸시까지 자동화
- **사용법**:
  ```bash
  bin/legal_check                # 검증만
  bin/legal_check --update       # 검증 + 자동 수정
  bin/legal_check --commit       # 검증 + 수정 + 커밋
  bin/legal_check --push         # 검증 + 수정 + 커밋 + 푸시
  ```

#### 5. GitHub Actions 워크플로우 (`.github/workflows/legal_check.yml`)
- **자동 실행 조건**:
  1. ✅ **매주 월요일 오전 9시 (KST)** 자동 실행
  2. ✅ `config/legal_standards.yml` 변경 시 자동 실행
  3. ✅ 수동 실행 (Actions 탭에서 "Run workflow")
- **기능**:
  - 법령 기준 검증
  - 불일치 시 GitHub Issue 자동 생성
  - 검증 보고서 아티팩트 업로드 (30일 보관)
  - 선택적 자동 수정 및 커밋

---

## ❌ 미구축 항목

### 1. Solid Queue 통합 (프로덕션 서버 자동 실행)
**현황**: ❌ **미설정**

**문제점**:
- `config/recurring.yml`에 법령 검증 Job 미등록
- 프로덕션 서버(141.164.53.97)에서 자동 실행 안 됨
- GitHub Actions만 실행 (GitHub에서만 검증, 프로덕션 서버는 검증 안 됨)

**필요 작업**:
1. `app/jobs/legal_compliance_job.rb` 생성
2. `config/recurring.yml`에 스케줄 등록
3. 프로덕션 서버에 배포

**권장 스케줄**:
```yaml
# config/recurring.yml
weekly_legal_check:
  class: LegalComplianceJob
  args: ["check"]
  schedule: "0 9 * * 1"  # 매주 월요일 9시

monthly_legal_deep_check:
  class: LegalComplianceJob
  args: ["deep_check"]
  schedule: "0 10 1 * *"  # 매월 1일 10시 (AI 검증 포함)
```

### 2. 이메일 알림 (관리자 통보)
**현황**: ❌ **미설정**

**문제점**:
- 법령 불일치 발견 시 GitHub Issue만 생성
- 관리자 이메일 알림 없음
- `ADMIN_EMAIL` 환경변수는 있으나 법령 검증에 미연동

**필요 작업**:
1. `app/mailers/legal_compliance_mailer.rb` 생성
2. 검증 결과 이메일 템플릿 작성
3. RegulationVerifier 서비스에 메일 발송 로직 추가

### 3. AI 기반 심층 검증 (Anthropic API)
**현황**: ⚠️ **코드 구현됨, 실행 안 됨**

**문제점**:
- `RegulationVerifier` 서비스에 AI 검증 코드 있음
- `ANTHROPIC_API_KEY` 환경변수 설정됨
- 하지만 **자동 실행 스케줄 없음** (수동 실행만 가능)

**현재 사용 가능한 수동 명령**:
```bash
# 프로덕션 서버에서 수동 실행
ssh root@141.164.53.97 "docker exec silmu-web-latest bin/rails runner 'RegulationVerifier.new.verify_all'"
```

**자동화 필요**:
- Solid Queue Job으로 월 1회 자동 실행 권장

### 4. 법제처/행정안전부 API 연동
**현황**: ❌ **미구현**

**문제점**:
- 현재는 `config/legal_standards.yml` 파일 수동 업데이트
- 법제처 국가법령정보센터 API 미연동
- 행정안전부 예규/지침 자동 수집 미구현

**가능한 개선**:
1. 법제처 오픈API 연동하여 최신 법령 자동 확인
2. 법령 개정 시 자동 알림
3. 법령 변경이력 자동 추적

---

## 📋 최근 검증 결과 (2026-02-13 09:46)

### 검증 통계
- **스캔된 파일**: 91개
- **검증된 파일**: 91개
- **오류**: 5개 ❌
- **경고**: 5개 ⚠️

### 발견된 오류 (자동 수정 가능)

#### 1. 잘못된 금액 표기 (5건)
| 파일 | 잘못된 값 | 올바른 값 |
|------|----------|----------|
| `app/views/home/index.html.erb` | 2,200만원 | 2천만원 |
| `app/views/home/index.html.erb` | 2,200만원 | 2천만원 |
| `db/seeds/audit_cases.rb` | 2,200만원 | 2천만원 |
| `db/seeds/subtopics.rb` | 2,200만원 | 2천만원 |
| `db/seeds/subtopics.rb` | 5,500만원 | 5천만원 |

**근거**:
- 지방계약법 시행령 제25조
- 1인 견적 수의계약 한도: **2천만원** (20,000,000원)
- 2인 견적 수의계약 한도: **5천만원** (50,000,000원)

### 경고 항목 (확인 필요)

#### 종합공사 수의계약 한도 미명시 (5건)
- `db/seeds/topic_bidding.rb`
- `db/seeds/topic_contract_guarantee_deposit.rb`
- `db/seeds/topic_defect_warranty.rb`
- `db/seeds/topic_estimated_price.rb`
- `db/seeds/topic_joint_contract.rb`

**권장 조치**: 종합공사 수의계약 한도 **4억원** 명시

---

## 🔧 즉시 수정 가능

### 오류 자동 수정 (1분 소요)
```bash
# 로컬에서 실행
bundle exec rake legal:update

# 확인
git diff

# 커밋 및 푸시
git add -A
git commit -m "fix: 법령 기준 금액 수정 (2,200만원 → 2천만원)"
git push
```

---

## 📈 권장 개선안

### 우선순위 높음 (1~2주 내 구현)

#### 1. Solid Queue 통합 ⭐⭐⭐
**목적**: 프로덕션 서버에서 자동 검증

**구현 방법**:
1. `app/jobs/legal_compliance_job.rb` 생성:
```ruby
class LegalComplianceJob < ApplicationJob
  queue_as :default

  def perform(mode = "check")
    case mode
    when "check"
      # 자동 스캔 검증
      run_legal_check
    when "deep_check"
      # AI 심층 검증
      verifier = RegulationVerifier.new
      verifier.verify_all
    end
  end

  private

  def run_legal_check
    require 'open3'
    stdout, stderr, status = Open3.capture3("bundle exec rake legal:ci_check")

    unless status.success?
      # 오류 발생 시 이메일 발송
      LegalComplianceMailer.error_alert(stdout, stderr).deliver_now
    end
  end
end
```

2. `config/recurring.yml`에 추가:
```yaml
weekly_legal_check:
  class: LegalComplianceJob
  args: ["check"]
  schedule: "0 9 * * 1"  # 매주 월요일 9시

monthly_legal_deep_check:
  class: LegalComplianceJob
  args: ["deep_check"]
  schedule: "0 10 1 * *"  # 매월 1일 10시
```

3. 프로덕션 배포

#### 2. 이메일 알림 구현 ⭐⭐⭐
**목적**: 법령 불일치 발견 시 관리자 즉시 통보

**구현 방법**:
1. `app/mailers/legal_compliance_mailer.rb` 생성
2. 검증 결과 이메일 템플릿 작성
3. `hello@silmu.kr`로 자동 발송

### 우선순위 중간 (1~2개월 내 구현)

#### 3. 법제처 API 연동 ⭐⭐
**목적**: 법령 개정 자동 감지

**API**: 법제처 국가법령정보센터 오픈API
**URL**: https://www.law.go.kr/DRF/lawService.do

**기능**:
- 지방계약법 시행령 개정 여부 자동 확인
- 공무원여비규정 개정 여부 자동 확인
- 개정 시 관리자 알림

#### 4. 대시보드 구축 ⭐
**목적**: 법령 검증 이력 시각화

**기능**:
- 검증 이력 그래프
- 오류 트렌드 분석
- 법령 개정 타임라인

---

## ✅ 결론 및 조치 사항

### 현재 상태 요약

| 항목 | 상태 | 평가 |
|------|------|------|
| 법령 기준 데이터 | ✅ 구축 완료 | 우수 |
| 자동 검증 로직 | ✅ 구축 완료 | 우수 |
| GitHub Actions | ✅ 매주 자동 실행 | 양호 |
| 프로덕션 서버 자동 실행 | ❌ 미설정 | **개선 필요** |
| 이메일 알림 | ❌ 미설정 | **개선 필요** |
| 외부 API 연동 | ❌ 미구현 | 향후 개선 |

### 즉시 조치 사항

1. **오류 수정** (5분):
   ```bash
   bundle exec rake legal:update
   git add -A && git commit -m "fix: 법령 금액 기준 수정"
   git push
   ```

2. **Solid Queue 통합** (1~2시간):
   - LegalComplianceJob 생성
   - recurring.yml 설정
   - 프로덕션 배포

3. **이메일 알림 구현** (1~2시간):
   - LegalComplianceMailer 생성
   - 템플릿 작성
   - Job에 연동

### 최종 평가

**종합 점수**: 70/100

**강점**:
- ✅ 법령 검증 로직 완벽 구현
- ✅ GitHub Actions 자동 실행
- ✅ 91개 파일 자동 스캔

**개선 필요**:
- ❌ 프로덕션 서버 자동 실행 미설정
- ❌ 관리자 이메일 알림 부재
- ❌ 법제처 API 미연동

**권장 조치**:
- **1주 내**: Solid Queue 통합 + 이메일 알림
- **1개월 내**: 법제처 API 연동
- **2개월 내**: 대시보드 구축

---

## 📞 문의
- 이메일: hello@silmu.kr
- 보고서 생성: `bundle exec rake legal:report`
