# CLAUDE.md — 실무 법률 가이드 (silmu.kr)

**글로벌 CLAUDE.md (`~/.claude/CLAUDE.md`)의 공통 규칙을 따르며, 이 파일은 silmu.kr 프로젝트 특화 정보만 포함합니다.**

---

## 프로젝트 정보

- **프로젝트명:** silmu (실무 법률 가이드)
- **도메인:** https://silmu.kr
- **서버:** 141.164.53.97
- **목적:** 공무원을 위한 법률/행정 실무 가이드 제공 플랫폼
- **주요 기능:** 법률 가이드 콘텐츠, SEO 최적화, AdSense 광고, 검색엔진 인덱싱

---

## 기술 스택

| 구분 | 기술 | 비고 |
|------|------|------|
| **프레임워크** | Ruby on Rails 8.1 | |
| **Ruby 버전** | 3.3+ | |
| **DB (로컬)** | SQLite3 | |
| **DB (운영)** | PostgreSQL | |
| **프론트엔드** | Hotwire (Turbo + Stimulus) | |
| **CSS** | TailwindCSS | `cssbundling-rails` |
| **백그라운드** | Solid Queue | Rails 8.1 내장 |
| **캐시** | Solid Cache | Rails 8.1 내장 |
| **배포** | Kamal 2 | `config/deploy.yml` |
| **웹서버** | Puma | |
| **에셋** | Propshaft | |
| **분석** | Google Analytics (GA4), Microsoft Clarity | |
| **광고** | Google AdSense | ca-pub-6241798439911569 |

---

## 환경변수

### 필수 환경변수 (.kamal/secrets)
```bash
RAILS_MASTER_KEY=<credentials.yml.enc 복호화 키>
ANTHROPIC_API_KEY=<Claude API 키>
SILMU_DATABASE_PASSWORD=<PostgreSQL 비밀번호>
KAMAL_REGISTRY_PASSWORD=<GitHub PAT (ghcr.io 접근용)>
```

**GitHub Container Registry (GHCR):**
- Registry: `ghcr.io/sdkdream50a-stack/silmu`
- Username: `sdkdream50a-stack`
- Token: GitHub Classic PAT with `repo`, `write:packages`, `delete:packages`
- Public 패키지 (무료, 용량 무제한)

### 공개 환경변수 (config/deploy.yml)
```bash
SOLID_QUEUE_IN_PUMA=true
GA_MEASUREMENT_ID=G-DGH1M308BH
ADSENSE_CLIENT_ID=ca-pub-6241798439911569
```

---

## Production DB 접속

```bash
# SSH 터널
ssh root@141.164.53.97 -L 5432:localhost:5432

# Rails console (production)
kamal app exec -i 'rails console'
```

---

## 프로젝트 구조

```
silmu/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   ├── services/       # 비즈니스 로직
│   ├── jobs/           # Solid Queue 잡
│   ├── mailers/
│   └── javascript/
│       └── controllers/  # Stimulus
├── config/
│   ├── deploy.yml      # Kamal 설정
│   ├── routes.rb
│   └── credentials/
├── db/
├── public/
│   ├── sitemap.xml
│   ├── robots.txt
│   └── ads.txt
├── .kamal/
│   └── secrets         # 환경변수
└── CLAUDE.md          # 이 파일
```

---

## SEO 특화 사항

### Google Search Console
- Property: https://silmu.kr
- Verification: google-site-verification meta tag

### Naver Search Advisor
- Site: https://silmu.kr
- Verification: naver-site-verification meta tag

### AdSense
- Client ID: ca-pub-6241798439911569
- ads.txt 위치: /public/ads.txt

### Analytics
- Google Analytics: G-DGH1M308BH
- Microsoft Clarity: (설치됨)

---

## 배포 시 추가 검증 항목 (silmu 전용)

### DNS/SEO 변경사항 확인
1. **Google Search Console verification tag**
   ```bash
   curl -s https://silmu.kr | grep "google-site-verification"
   ```

2. **Naver Search Advisor verification tag**
   ```bash
   curl -s https://silmu.kr | grep "naver-site-verification"
   ```

3. **sitemap.xml**
   ```bash
   curl -s https://silmu.kr/sitemap.xml | head -20
   ```

4. **ads.txt (AdSense)**
   ```bash
   curl -s https://silmu.kr/ads.txt
   ```

5. **robots.txt**
   ```bash
   curl -s https://silmu.kr/robots.txt
   ```

---

## 연락처 및 문서

- **도메인:** https://silmu.kr
- **이메일:** hello@silmu.kr (Forward Email → 50adreamfire@gmail.com)
- **서버 접속:** `ssh root@141.164.53.97`

---

## 재발 방지 규칙 (silmu 전용)

### Date.today 사용 금지 (CRITICAL)
**서버 타임존은 UTC이므로 `Date.today`는 한국 시간과 최대 9시간 차이 발생.**

- ❌ `Date.today` — UTC 기준, 자정~09:00 KST 구간에서 하루 오차
- ✅ `Time.zone.today` — KST 기준 (Rails `config.time_zone = "Seoul"` 적용)
- ✅ `Time.current.to_date` — 동일

**적용 위치:** 뷰, 컨트롤러, 모델, 잡 등 모든 Ruby 코드

**RuboCop 룰:** `.rubocop.yml`에 `Rails/Date: Enabled: true` 설정으로 자동 감지

---

## 마지막 업데이트
2026-02-27 — Date.today → Time.zone.today 전면 교체 및 재발 방지 룰 추가
