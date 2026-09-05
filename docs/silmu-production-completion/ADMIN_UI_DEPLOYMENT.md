# ADMIN_UI_DEPLOYMENT — 검토 큐 UI 운영 배포

## 1. 배포

| 항목 | 값 |
|---|---|
| 커밋 | `f8975b9`(UI) + `50c2624`(문서) → 배포 리비전 **`50c2624`** |
| 배포 시각 | 2026-09-06 · 79.6초 · 무중단(health check 통과) |
| 이전 리비전 | `1bb1c4e` (롤백 이미지로 보존) |
| 방법 | 격리 `DOCKER_CONFIG` 로 자격증명 우회 (`BUILDER_RECOVERY.md`) |

### §5 Deploy Gate (배포 전 확인)
```
production health   200
current revision    1bb1c4e6d2ca
DB connectivity     audit_cases 257 조회 성공
backup availability silmu_production_prewrite_20260905_153316.dump
rollback image      1bb1c4e… , 74056244… (2개 보유)
```
전부 확인됨 → 배포 진행.

## 2. 스모크 테스트

### 인증·인가
| 대상 | 결과 |
|---|---|
| `/admin/authority_reviews` 비로그인 | **302 → /users/sign_in** ✅ |
| `/admin/analytics` 비로그인 | 302 → /users/sign_in ✅ |

### 공개 페이지 회귀 (5xx 0건)
```
/                                          200
/topics/private-contract                   200
/audit-cases/private-contract-over-limit   200
/guides/purchase-and-inspection            200
/tools/contract-method                     200
/up                                        200
```

## 3. §7 — 빈 화면만 보고 끝내지 않았다

운영 검토 태스크는 현재 0건이다(실제 개정이 없으므로 정상).
**운영 DB 에 가짜 태스크를 넣지 않았고**, 대신 두 경로로 표현형을 검증했다.

### ① 개발 환경 실데이터 렌더 (실제 컨트롤러 인스턴스 변수 그대로)
dev 에 실제 감지 사이클을 돌려 77건 태스크를 만들고 뷰를 직접 렌더(204KB).

| §24 요구 | 결과 |
|---|:--:|
| changed document (`지방계약법 시행령`) | ✅ |
| effective date (`2026.12.01`) | ✅ |
| 시행 예정 강조 (`(시행 예정)`) | ✅ |
| diff (`조문 변경`) | ✅ |
| affected content (`AuditCase /`) | ✅ |
| impact level (`DIRECT`) | ✅ |
| review status (`OPEN`) | ✅ |

| §25 결정 5종 | 결과 |
|---|:--:|
| IMPACT_CONFIRMED / NO_IMPACT / UPDATE_REQUIRED / NEEDS_LEGAL_REVIEW / DEFERRED | ✅ 전부 |

렌더 검증 후 **dev 테스트 데이터는 전량 삭제**했다(versions 8 · events 8 · tasks 0 복귀).

### ② 통합 테스트 8종 (실제 컨트롤러·라우트·뷰 경유)
비로그인 차단 · 비관리자 차단 · 한 화면 표현 · 결정 5종 · NO_IMPACT 전이 ·
**§26 위험 전이 방지** · 알 수 없는 결정 거부 · **§27 콘텐츠 무수정**

## 4. 시도했으나 하지 않은 것

dev 서버에 curl 로 로그인해 브라우저 흐름을 재현하려 했으나 CSRF/세션 처리로 2회 실패했다.
**같은 방식을 반복하지 않고** 뷰 직접 렌더로 전환해 동일한 증거를 얻었다.
(P1.55 에서 "같은 실패 3회" 를 겪은 교훈 적용)

## 5. 접근 방법

```
https://silmu.kr/admin/authority_reviews
  로그인 → admin 권한 → 30분 step-up 재인증
```
CLI 대안: `bin/kamal app exec --reuse 'bin/rails silmu:freshness:review_queue'`
