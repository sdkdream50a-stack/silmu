# SILMU — CANONICAL DEPLOYMENT CONTRACT (V1.0)

> 2026-09-07 S3-A. 이 문서의 값은 **실측**이다. 상위 계약:
> 브랜치/CI 거버넌스 = `SILMU_CI_GOVERNANCE_CONTRACT.md` (S2) ·
> 계보 = `SILMU_GIT_PRODUCTION_LINEAGE.md` (S0)

## 계약

```
CANONICAL_SOURCE      = origin/main
REQUIRED_CHECKS       = test · lint · scan_ruby   (GitHub Actions app_id 15368)
DEPLOY_SOURCE         = 명시된 정확한 40자리 SHA   (암묵적 HEAD 금지)
CLEAN_DEPLOY_CHECKOUT = 전용 detached worktree     (개발 checkout 과 분리)
NO_AUTO_DEPLOY        = YES   (사람이 bin/deploy 를 부른다. main push 로 배포되지 않는다)
ADMIN_BYPASS          = EMERGENCY_ONLY
ROLLBACK              = 직전 운영 SHA 로 bin/deploy 재실행
```

## 왜 이것이 필요했나 — 실제로 일어난 일

Kamal 은 이미지 태그를 **«지금 cwd 의 HEAD»** 에서 유도한다(`Kamal::Git.revision`).
2026-09-07 실측: R2 개발 worktree 는 `1481b1c` 에 머물러 있었고 main/production 은 `f927f90` 이었다.
그 worktree 에서 `kamal deploy` 를 부르면 **옛 리비전이 조용히 운영에 올라간다.**
경고도, 확인도 없다. S3 는 이 «아무 worktree 에서나 배포» 를 없앤다.

## 현재(S3 이전) 배포 경로 — 실측

| 단계 | 실측 | INPUT_SHA | ACTUAL_SHA | CAN_GO_STALE | FAIL_CLOSED |
|------|------|-----------|------------|--------------|-------------|
| SOURCE_CHECKOUT | 사람이 있던 아무 checkout | 없음 | cwd HEAD | **YES** | NO |
| secrets | `.kamal/secrets`(gitignore, 로컬 전용) → `config/master.key`·`.env` 참조 | — | — | — | YES(없으면 실패) |
| build | `builder.remote: ssh://root@…:2222`, `context` 미지정 → **git_clone 모드** | cwd HEAD | cwd HEAD | YES | NO |
| GHCR tag | `-t …:<full SHA>` **와 함께 `-t …:latest`** | cwd HEAD | 동일 | YES | NO |
| Kamal deploy | 컨테이너는 `<full SHA>` 태그로 실행 | — | — | — | NO |
| /up · postdeploy | `proxy.healthcheck /up` + `.kamal/hooks/post-deploy`(안내문뿐) | — | — | — | 부분 |

위험 실측 결과:

- **A. stale worktree 배포 가능?** → **YES.** origin/main 과 대조하는 코드가 어디에도 없었다.
- **B. dirty worktree 배포 가능?** → **YES.** 다만 방향이 반대다 — `git_clone?`=true 라서
  Kamal 은 clone 을 HEAD 로 `reset --hard` 한다. 즉 **내 미커밋 수정은 조용히 빠지고**,
  태그에 `_uncommitted_` 접미사도 붙지 않아 깨끗한 배포와 구별되지 않는다.
- **C. origin/main 과 다른 HEAD 배포 가능?** → **YES.** 검사 없음.
- **D. CI red/unknown SHA 배포 가능?** → **YES.** Kamal 은 GitHub check 를 전혀 보지 않는다.
- **E. latest vs exact SHA?** → **둘 다.** 실행 컨테이너는 exact SHA 로 고정되지만 `:latest` 도 함께 이동한다.

## 목표 경로 (S3-A)

```
PR → required checks green → main → bin/deploy <SHA> →
전용 clean detached checkout → preflight(G1..G6) → Kamal → <full SHA> 태그 이미지 →
production readback(이미지 태그 == 대상) → /up 200
```

새 배포 플랫폼을 만들지 않았다. Kamal 을 그대로 쓰고, Kamal 이 이미 제공하는
`pre-deploy` 훅(0 이 아니면 배포 중단)에 게이트를 얹었다.

## 구성 요소 (2파일)

| 경로 | 역할 |
|------|------|
| `bin/deploy` | 정본 진입점. 대상 SHA 확정 → 전용 clean checkout → secret 연결 → preflight → Kamal → 사후 readback |
| `.kamal/hooks/pre-deploy` | fail-closed 게이트. **어느 checkout 에서 kamal 을 부르든** 통과해야 한다 |

`bin/deploy` 는 **자기와 같은 커밋의 훅**을 실행한다. 배포 대상 checkout 의 훅을 쓰면
게이트 도입 이전 SHA 로 롤백할 때 게이트가 조용히 사라지기 때문이다.

## FAIL-CLOSED 조건

| 코드 | 차단 사유 |
|------|-----------|
| `G0_NOT_A_GIT_CHECKOUT` | git checkout 이 아니다(버전이 커밋 SHA 에서 나온다) |
| `G1_TARGET_MISMATCH` | `DEPLOY_TARGET_SHA` 미지정 · 40자리 SHA 아님 · HEAD 불일치 · `KAMAL_VERSION` 불일치 |
| `G2_DIRTY` | `git status --porcelain` 이 비어 있지 않다 |
| `G3_NOT_MAIN_LINEAGE` | 대상이 `origin/main` 의 조상이 아니다 |
| `G4_CI_NOT_GREEN` | 대상 SHA 에서 `test`·`lint`·`scan_ruby` 중 하나라도 success 가 아니다(pending·missing 포함) |
| `G5_ROLLBACK_UNKNOWN` | 현재 운영 이미지 태그가 40자리 SHA 로 읽히지 않는다 |
| `G6_SECRET_PATH_INVALID` | `.kamal/secrets` 또는 `config/master.key` 를 읽을 수 없다 |

같은 이름의 check 가 여러 번 돌았으면 **가장 최근 것**을 본다(옛 green 이 새 실패를 가리지 못하게).

## SECRETS 계약

배포 전용 secret 과 개발용 credential 을 **목적으로 갈라** 둔다.

| 파일 | 분류 | 정본 위치 |
|---|---|---|
| `.kamal/secrets` | **DEPLOY_ONLY** — 레지스트리 비밀번호·서버 DB 비밀번호 등, kamal 만 읽는다 | **checkout 밖** `<project 부모>/.silmu-deploy-secrets/kamal-secrets` |
| `config/master.key` | **APP_DEV_REQUIRED** — Rails credentials 복호화. 개발·테스트에 필요 | 정본 checkout `/Users/seong/project/silmu/config/master.key` |
| `.env` | **APP_DEV_REQUIRED** — ANTHROPIC_API_KEY 등 | 정본 checkout |

- 배포 전용 secret 을 **어느 checkout 안에도 두지 않는다.** 개발 checkout 에 그 파일이 있으면
  거기서 `kamal deploy` 를 직접 불러 `bin/deploy` 의 게이트를 통째로 우회할 수 있다(S3C).
- `bin/deploy` 는 배포 checkout 에 이 파일들을 **symlink** 한다 — 사본을 늘리지 않는다.
  경로는 `SILMU_DEPLOY_SECRETS` 로 덮어쓸 수 있다.
- 셋 다 `.gitignore` 로 봉인되어 있고 **git 이력에 들어간 적이 없다**(실측 확인).
- 게이트는 존재·가독성만 본다. **값을 읽거나 출력하지 않는다.**
  (Kamal 은 `pre-deploy` 훅에 secret 을 env 로 넘긴다 — 훅은 env 를 덤프하지 않는다.)
- 배포 전용 secret 이 없으면 Kamal 은 `Kamal::ConfigurationError: Secret '…' not found,
  no secret files (.kamal/secrets) provided` 로 **fail-closed** 한다(서버 접속 이전 단계).

## ROLLBACK 계약

```
ROLLBACK_SHA = 배포 직전 시점에 «실제로 운영 중이던» 이미지 태그
복귀         = bin/deploy <ROLLBACK_SHA>
```
게이트가 매 배포마다 이 값을 먼저 확정하고, 확정할 수 없으면 배포를 시작하지 않는다(G5).

## POSTDEPLOY 계약

1. `docker ps` 의 실행 이미지 태그 == 요청한 SHA
2. `https://silmu.kr/up` == 200

둘 중 하나라도 어긋나면 `bin/deploy` 는 0 이 아닌 코드로 끝난다.

## 검증 (2026-09-07)

- 합성 fixture 회귀 **13 runs / 44 assertions / 0F** — `test/scripts/deploy_preflight_test.rb`
  (gh·ssh 는 PATH shim 으로 대체하고 git 은 실물을 쓴다. 게이트에 테스트 전용 분기는 없다.)
- 뮤테이션 **APPLIED 8/8 · KILLED 7 · EQUIVALENT 1**
  (등가 = 40자리 정규식을 `{7,40}` 으로 푼 것. 짧은 SHA 는 HEAD 비교에서 어차피 G1 에 막힌다 —
  원본·뮤턴트의 종료코드와 차단코드가 동일함을 실증했다. 죽이는 테스트를 지어내지 않았다.)
- **live positive control**: 실 gh + 실 운영 ssh 로 `f927f90` → `PREFLIGHT_PASS`
- **live negative control**: 그 사고의 실물 SHA `1481b1c` 로
  - 암묵 배포(`DEPLOY_TARGET_SHA` 없음) → `G1_TARGET_MISMATCH`
  - 명시 지목(main 조상이지만 CI red) → `G4_CI_NOT_GREEN` (`test` = failure)
- `bin/deploy --preflight` 전 구간 실행 → clean checkout 생성(dirty 0) → PASS → **배포 0**

## 한계 — 정직하게

- **게이트는 자기가 들어 있는 커밋에만 있다.** `bin/deploy` 를 통하면 스크립트와 훅이 같은
  커밋에서 함께 오므로 게이트 도입 이전 SHA 로 롤백해도 게이트가 돈다. 그러나 **게이트 이전 SHA 의
  checkout 에서 `kamal deploy` 를 직접 부르면** 그 checkout 에는 훅이 없어 아무것도 막지 못한다.
  현재 그런 checkout 이 실재한다(아래).
- `kamal deploy --skip-hooks` 는 게이트를 건너뛴다. 이것은 Kamal 이 제공하는 기존 탈출구이며
  **EMERGENCY_ONLY** 다. 새 우회 스위치를 따로 만들지 않았다.
- 게이트는 `gh` 와 `jq` 를 요구한다. 없으면 `G4` 로 **차단**된다(통과가 아니다).

### 지금 남아 있는 stale checkout (2026-09-07 실측)

`.kamal/secrets` 가 있어 **실제로 배포를 시작할 수 있는** checkout:

| checkout | HEAD | 상태 |
|---|---|---|
| `/Users/seong/project/silmu` (정본) | `a1e8e25` · dirty 40 | 게이트 이전 |
| `…/silmu-worktrees/r2-source-quality-integration-0906` | `1481b1c` | 게이트 이전 |

권장 후속(사용자 판단 필요, 이번에 하지 않음): 배포에 쓰지 않는 checkout 에서
`.kamal/secrets` 를 치우면 그 경로는 `G6` 이전에 Kamal 단계에서 이미 fail-closed 가 된다.

## 하지 않은 것

자동 배포 · Kamal 교체 · GitHub Actions 재설계 · 새 배포 플랫폼 · 애플리케이션 기능 변경.
`AUTO_DEPLOY_FROM_MAIN = NO` 는 그대로다.
