# PRODUCTION_REALITY — 운영 실측 (2026-09-06)

> §5 — dev 숫자를 운영 정본으로 쓰지 않는다. 아래는 전부 운영 서버에서 직접 조회한 값이다.

---

## 1. 인프라

| 항목 | 값 | 확인 방법 |
|---|---|---|
| 서버 | `141.164.53.97` (hostname `vultr`) | SSH |
| 배포 | Kamal 2.11.0 · GHCR (`ghcr.io/sdkdream50a-stack/silmu`) | `config/deploy.yml`, `Gemfile.lock` |
| 호스트 | `silmu.kr` · `www.silmu.kr` · `exam.silmu.kr` | `config/deploy.yml` proxy |
| 프록시 | `kamal-proxy:v0.9.2` (Up 6주) | `docker ps` |
| DB | **호스트 설치 PostgreSQL** (컨테이너 아님) · `systemctl is-active` = active | SSH |
| 디스크 | 150G 중 39G 여유 (73% 사용) | `df -h` |

⚠️ **이 서버는 6개 앱을 함께 호스팅한다** — silmu · fateaiverse · command_center · student_record_master · intervu_promotion · intervu.
silmu 배포는 다른 앱에 영향을 주지 않아야 한다(Kamal 컨테이너 단위 교체).

## 2. 현재 배포 리비전

```
silmu-web-74056244ec9ecef46b6f867d29ed2ebe103cc7cd   Up 2 weeks
image: ghcr.io/sdkdream50a-stack/silmu:74056244ec9ecef46b6f867d29ed2ebe103cc7cd
```
= 커밋 **`7405624`** (`fix(tools): correct qualification evaluation accuracy`)

**로컬 HEAD 도 `7405624` 다.** 즉 P0·P1·P1.5 작업은 전부 **미커밋 상태**이며 운영에 존재하지 않는다.

## 3. 마이그레이션 상태

| 항목 | 값 |
|---|---|
| 운영 적용 마이그레이션 총수 | **62** |
| 최신 적용 | `20260611202659` (Add source to search logs) |
| P1 마이그레이션 3종 적용 | **0 / 3** |
| P1.5 마이그레이션 3종 적용 | **0 / 3** |

→ 운영에는 `source_type` · `verification_status` · `target_agency` · `freshness_state` · `authority_*` 테이블이 **없다.**

## 4. 콘텐츠 실측 (운영 vs dev)

| 테이블 | **운영** | dev | 차이 |
|---|---:|---:|---:|
| topics | **114** | 92 | +22 |
| guides | **103** | 103 | 0 |
| audit_cases | **257** | 191 | **+66** |
| laws | **15** | 0 | +15 |
| slug_redirects | 0 | 0 | — |
| search_logs | **2,151** | 10 | +2,141 |

- 전부 `published = true`
- **guides 는 dev 와 같다**(103). P0 sitemap 의 107 은 컨트롤러 하드코딩 가이드 4종을 포함한 수치였다
- `search_logs 2,151` — 운영 계측은 살아 있다 (P0 에서 dev 10행만 보고 "계측 사실상 미가동"이라 적었던 것은 dev 기준이었다)

## 5. P1 backfill 대상 실측 (운영 `audit_cases` 257건)

| 지표 | 운영 | dev |
|---|---:|---:|
| `source` jsonb 에 원문 URL 보유 | **86** | 86 |
| `source` 가 문자열(`"silmu-2026"`) | **16** | 16 |
| `source` 가 빈 객체 `{}` | **155** | 89 |
| `verification_source` 보유 | **246** | 179 |
| `legal_basis` 보유 | **257 (100%)** | 191 |

→ dev 대비 늘어난 66건은 전부 `source = {}` 이다. P1 분류기 기준으로 `ACTUAL_AUDIT` 은 **86건으로 dev 와 동일**할 것으로 예상되며, `UNVERIFIED` 가 42 → 약 108 로 늘어난다.
**단, 이는 예측이다. 운영 dry-run 으로 확정해야 한다**(`P1_BACKFILL_PRODUCTION.md`).

## 6. 판정

| 항목 | 상태 |
|---|---|
| 운영 접근 | ✅ SSH · DB 조회 가능 |
| 백업/복구 | ✅ `BACKUP_ROLLBACK.md` 참조 |
| 코드 배포 전제 | 🔴 **P0/P1/P1.5 전부 미커밋** — 배포하려면 먼저 커밋해야 한다 |
| 스키마 | 🔴 P1/P1.5 마이그레이션 0/6 적용 |
| 데이터 | ✅ 운영 데이터 건강 (누락·손상 징후 없음) |
