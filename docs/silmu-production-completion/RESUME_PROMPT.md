# RESUME_PROMPT — 다음 세션 시작 프롬프트 (P1.55A 체크포인트)

```
silmu.kr 을 이어서 한다.

프로젝트: /Users/seong/project/silmu   (Rails 8.1 · PostgreSQL · Kamal 2 → 141.164.53.97)
브랜치:   fix/tool-accuracy-p1-0804
로컬 HEAD: 03f7193
운영 리비전: 50c2624  (https://silmu.kr — health 200)

선행 문서 (P0 → P1 → P1.5 → P1.55 → P1.55A):
  docs/silmu-audit/  ·  docs/silmu-p1/  ·  docs/silmu-freshness/
  docs/silmu-production-rollout/  ·  docs/silmu-production-completion/

시작 전 읽을 것:
  1. docs/silmu-production-completion/RESUME_PROMPT.md          ← 이 파일
  2. docs/silmu-production-completion/SOURCE_FAILURE_ALERTING.md ← 다음 1순위 구현안
  3. docs/silmu-production-completion/EFFECTIVE_DATE_RECONCILIATION.md
  4. docs/silmu-production-completion/BUILDER_RECOVERY.md        ← 배포 시 반드시
  5. docs/silmu-freshness/LEGACY_JOB_RISK.md

⚠️ 배포하려면 먼저 (Docker Desktop 이 꺼져 있으면 kamal 이 멈춘다):
   docker info  →  실패하면 아래 격리 자격증명 방식 사용
   TMPCFG=$(mktemp -d); cp -R ~/.docker "$TMPCFG/cfg"
   # config.json 에서 credsStore/credHelpers 제거 + auths["ghcr.io"].auth =
   #   base64("sdkdream50a-stack:" + .kamal/secrets 의 KAMAL_REGISTRY_PASSWORD)
   DOCKER_CONFIG="$TMPCFG/cfg" bin/kamal deploy
   (근거·검증 = BUILDER_RECOVERY.md)

이번 세션 목표 (우선순위 순, 택1):
  A. 소스 장애 알림 구현 — SOURCE_FAILURE_ALERTING.md §5 그대로.
     additive 마이그레이션 2컬럼(first_failed_at·alerted_at) + record_failure! 확장
     + 3회 연속 실패 시 ADMIN_EMAIL 메일 1회(중복 억제). 알림 실패가 수집을 막지 않게 rescue.
     ※ 스케줄러 등록보다 이것이 먼저다 — 사람이 화면을 안 보면 소스가 조용히 죽는다.
  B. 화요일 07:00 LawSyncJob 결과 확인 — laws.effective_date 15행이 채워졌는지,
     EFFECTIVE_DATE_RECONCILIATION.md §5 표(3건)와 일치하는지. 그 뒤 laws/LawSyncJob 폐기 판단.
  C. Cloudflare 캐시 — CLOUDFLARE_FRESHNESS_CACHE.md §4 조사부터. 전 사이트 no-cache 금지.
  D. P1.6 UI/UX — P1_6_FINAL_HANDOFF.md 의 인터페이스만 사용. 충돌 파일 §5 확인 후 홈·네비·검색부터.
  E. 콘텐츠 편집 4건 — EDITORIAL_MANUAL_REVIEW.md (AI 자동수정 금지, 사람 판단)

제약:
  - 구 LegalComplianceJob 의 recurring.yml 주석을 해제하지 않는다.
  - Freshness Engine 은 게시 콘텐츠 본문을 절대 수정하지 않는다(freshness_state 등 3컬럼만).
  - 운영 DB write 는 dry-run → 사람 검토 → 명시적 실행.
  - 스케줄러(AuthorityFreshnessCheckJob) 등록은 별도 승인 대상.
  - 일반행정 콘텐츠 대량 확장·17개 교육청 ingestion·신규 RAG 금지 (P2_GATE = CONDITIONAL).

검증:
  bin/rails test                                   # baseline 353 runs / 2,682 assertions / 0F / 0E / 14 skips
  bin/kamal app exec --reuse 'bin/rails silmu:freshness:status'
  bin/kamal app exec --reuse 'bin/rails silmu:p1:leak_scan'
  curl -sS -o /dev/null -w "%{http_code}\n" https://silmu.kr/up
```

---

## 현재 상태 (2026-09-06 체크포인트)

### git
```
브랜치       fix/tool-accuracy-p1-0804
로컬 HEAD    03f7193
미푸시 커밋   7개  (7405624 이후 전부)
origin/main  74056244…  = 커밋 7405624 (배포 이전 상태)
원격 브랜치   fix/tool-accuracy-p1-0804 → 존재하지 않음
```
🔴 **운영이 돌고 있는 코드가 로컬에만 존재한다.** → `PUSH_RECOMMENDED` (§25 에 따라 실제 push 는 하지 않음)

| 커밋 | 내용 |
|---|---|
| `7027801` | docs: P0 authority audit |
| `ab6d760` | feat: P1 authority trust layer |
| `3c8b340` | feat: P1.5 freshness engine |
| `1bb1c4e` | fix(law): parse_law_meta `<law>` 노드 |
| `f8975b9` | feat(admin): 검토 큐 UI |
| `50c2624` | docs: P1.55 rollout 기록 |
| `03f7193` | docs: P1.55A 체크포인트 |

### 운영
```
리비전        50c2624399c59c6784ef38f681e1a108393c2f0b   (health 200)
마이그레이션    P1 3 + P1.5 3 = 6/6 적용
provenance    ACTUAL_AUDIT 86 · RECONSTRUCTED 110 · UNVERIFIED 61  (= 257)
agency HIGH   AuditCase 210 · Topic 15 · Guide 0
Authority     소스 1 · 문서 8 · 버전 8 · 이벤트 8(기준선) · 간선 209
검토 태스크    0   (실제 개정 없음 = 정상)
freshness 관측 0
콘텐츠 자동변경 0
스케줄러       AuthorityFreshnessCheckJob 미등록 / 구 LegalComplianceJob 주석 유지
백업          일일 자동 02:00 + prewrite_20260905_153316.dump
롤백 이미지     1bb1c4e… · 74056244…
```

### dev
```
이번 세션 검증용 데이터 전량 삭제 완료 (versions 8 · events 8 · tasks 0 · freshness 0)
p155a-admin@silmu.kr 계정 삭제 완료
```

---

## 이번 세션(P1.55A)에서 실제로 확인한 사실

1. **빌더 정지의 진짜 원인** — `~/.docker/config.json` 의 `credsStore: "desktop"` + Docker Desktop 미실행.
   GHCR 푸시 시 `docker-credential-desktop` 이 응답하지 않아 멈춘다.
   원격 빌더는 정상이었다(최소 alpine 빌드 0.4초 성공으로 증명).
   **P1.55 의 "빌더 열화" 진단은 틀렸고 이 문서에서 정정했다.**
2. **SSH 포트 22 는 애초에 쓰이지 않았다** — 서버 sshd 는 2222 만 리스닝하고
   `~/.ssh/config` 가 이 호스트를 2222 로 매핑한다. fail2ban 과 무관.
3. **`laws.effective_date` 공개 소비처 = 0** — 전수 추적 결과
   `Law.current` · `Law#law_go_kr_url` 사용처 0, 공개 UI 는 `LawContentFetcher` 실시간 캐시를 쓴다.
   `laws` 는 `LawSyncJob` 의 내부 비교용 스냅샷일 뿐이다.
4. **`weekly_law_sync` 는 활성이다** (`recurring.yml`, 화 07:00) — 파서가 고쳐졌으므로
   다음 실행에서 15행이 공식 API 값으로 채워진다. 첫 채움은 `prev=NULL` 이라 거짓 개정 알림이 없다.
5. **파서 수정은 과거 데이터를 소급 반영하지 않는다** — 배포 후 재측정에서 여전히 0/15 였다.
6. **Admin UI 는 운영에 배포되어 보호된다** — 비로그인 302, 공개 페이지 회귀 0.

## 수정한 파일 (이번 세션)
```
없음 (앱 코드 무변경)
추가: docs/silmu-production-completion/  8문서
```
앱 코드·스키마·운영 DB 데이터 변경 **0**. 배포는 이미 커밋된 `f8975b9`·`50c2624` 를 올린 것이다.

## 테스트
```
353 runs · 2,682 assertions · 0 failures · 0 errors · 14 skips   (baseline 동일, 악화 없음)
```

## 미완료 항목

| # | 항목 | 상태 |
|:--:|---|---|
| 1 | 소스 장애 알림 | 🔴 미구현 — 설계만 (`SOURCE_FAILURE_ALERTING.md`) |
| 2 | Cloudflare 캐시 지연 | 🔴 DESIGN_ONLY — 조사 미착수 |
| 3 | `laws.effective_date` 실제 채움 | 🟡 화요일 자동 실행 대기 (수동 backfill 안 함) |
| 4 | 운영 토픽 시행일 표기 노출 확인 | 🔴 `topic_law_refs` 7일 캐시로 미확인 |
| 5 | 콘텐츠 내부표현 4건 편집 | 🔴 사람 작업 (`EDITORIAL_MANUAL_REVIEW.md`) |
| 6 | 스케줄러 등록 | 🔴 별도 승인 대기 |
| 7 | git push | 🔴 `PUSH_RECOMMENDED` — 승인 대기 |
| 8 | GHCR `credtest` 태그 정리 | 🔴 시험 잔여물 |
| 9 | 운영 Admin UI 로그인 상태 렌더 | 🟡 dev 렌더로 대체 검증 |

## 다음 우선순위
```
1. 소스 장애 알림 (스케줄러보다 먼저)
2. git push 판단  ← 운영 코드가 로컬에만 있다
3. 화요일 LawSyncJob 결과 확인
4. Cloudflare 캐시 조사
5. P1.6 UI/UX (병렬 가능, 별도 worktree)
```

## 함정 (반복하지 말 것)

1. **배포 전 `docker info` 확인.** Docker Desktop 이 꺼져 있으면 kamal 이 buildx 에서 조용히 멈춘다.
   증상: 진행 출력 없음 + 원격 빌더 CPU 0.0x% + 이미지 미푸시. → `BUILDER_RECOVERY.md` 방식 사용.
2. **같은 실패 2회면 방식을 바꾼다.** dev 브라우저 로그인이 2회 실패하자 뷰 직접 렌더로 전환해 해결했다.
   P1.55 에서 같은 배포를 3회 반복해 40분을 쓴 전례가 있다.
3. **"자동으로 채워졌겠지" 라고 가정하지 않는다.** 파서를 고쳐도 과거 행은 그대로였다. 항상 재측정.
4. **소비처를 먼저 세고 backfill 을 결정한다.** 소비처 0인 테이블을 채우면 부채만 는다.
5. **Cloudflare 캐시 4시간.** 배포·backfill 후 공개 페이지가 안 바뀌면 DB 가 아니라 엣지 캐시부터 본다
   (`cf-cache-status` 헤더 → `?cb=` + `no-cache` 로 우회 검증).
6. **운영 DB 에 검증용 가짜 데이터를 넣지 않는다.** dev 에서 만들고 반드시 지운다.
7. **`db:rollback STEP=n` 은 "적용된 마지막 n개"다.** 실행 전 `db:migrate:status` 확인.
8. **Tailwind 동적 클래스 금지 / ERB 블록 안에서는 `#` 주석.**
9. **Devise 통합 테스트에서 재인증 POST 불필요** — `warden_admin_hook` 이 이미 처리하며,
   그 POST 가 테스트 세션을 깨뜨린다.
