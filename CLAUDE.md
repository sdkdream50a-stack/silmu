# CLAUDE.md — 실무 법률 가이드 (silmu.kr)

> 글로벌 CLAUDE.md 공통 규칙 적용. 이 파일은 silmu.kr 프로젝트 특화 정보만 포함.

---

## 프로젝트 정보

- **도메인:** https://silmu.kr | **서버:** 141.164.53.97
- **목적:** 공무원을 위한 법률/행정 실무 가이드
- **이메일:** hello@silmu.kr → 50adreamfire@gmail.com

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| Framework | Ruby on Rails 8.1 / Ruby 3.3+ |
| DB | SQLite3(로컬) / PostgreSQL(운영) |
| Frontend | Hotwire + TailwindCSS (cssbundling-rails) |
| Background | Solid Queue / Solid Cache |
| 배포 | Kamal 2 (`config/deploy.yml`) |
| 광고 | Google AdSense ca-pub-6241798439911569 |
| 분석 | GA4 (G-DGH1M308BH) + Microsoft Clarity |

---

## 환경변수 (.kamal/secrets)

```bash
RAILS_MASTER_KEY=          # credentials.yml.enc 복호화
ANTHROPIC_API_KEY=         # Claude API
SILMU_DATABASE_PASSWORD=   # PostgreSQL
KAMAL_REGISTRY_PASSWORD=   # GitHub PAT (ghcr.io)
```

공개 (config/deploy.yml): `SOLID_QUEUE_IN_PUMA=true`, `GA_MEASUREMENT_ID=G-DGH1M308BH`

GHCR 레지스트리: `ghcr.io/sdkdream50a-stack/silmu`

---

## Production DB 접속

```bash
kamal app exec -i 'rails console'
ssh root@141.164.53.97 -L 5432:localhost:5432
```

---

## SEO 식별자

- Google Search Console: google-site-verification meta tag
- Naver Search Advisor: naver-site-verification meta tag
- AdSense: ca-pub-6241798439911569 / ads.txt → `/public/ads.txt`

---

## 배포 후 추가 검증 (silmu 전용)

```bash
curl -s https://silmu.kr | grep "google-site-verification"
curl -s https://silmu.kr | grep "naver-site-verification"
curl -s https://silmu.kr/sitemap.xml | head -5
curl -s https://silmu.kr/ads.txt
```

---

## 재발 방지 규칙 (CRITICAL)

### Date.today 사용 금지
서버 타임존 UTC → `Date.today`는 KST와 최대 9시간 차이 발생.
- ❌ `Date.today` → ✅ `Time.zone.today` 또는 `Time.current.to_date`
- `.rubocop.yml`: `Rails/Date: Enabled: true` 설정으로 자동 감지

---

## 마지막 업데이트
2026-04-05 — CLAUDE.md 컨텍스트 최적화 (177줄 → 80줄)
