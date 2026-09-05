# PRODUCTION_DEPLOYMENT — P1.55B 운영 배포 기록

> §43~§47. 2026-09-06 07:05~07:12 KST.

## 1. 배포 전 게이트 (§44) — 전부 실측

| 항목 | 기대 | 실측 | 판정 |
|---|---|---|:--:|
| production health | 200 | `GET /up` → **200** | ✅ |
| current revision | 50c2624 | `kamal app version` → **50c2624399c…** | ✅ |
| backup availability | 최신 백업 존재 | `silmu_production_prewrite_20260905_153316.dump` (3.8MB) · 일일 백업 정상 | ✅ |
| rollback image | 서버에 존재 | `ghcr.io/…/silmu:50c2624…` = `28effa7ff200` (서버 로컬) | ✅ |
| pending migrations | 없음 | `needs_migration? = false` · schema `20260906010200` | ✅ |

## 2. Docker 사전 확인 (§12·§43) — P1.55A 조건 재현됨

```bash
$ docker info
DOCKER_UNAVAILABLE          # 로컬 데몬 없음

$ pgrep -fl "Docker Desktop"
(없음)                       # Docker Desktop OFF

~/.docker/config.json → credsStore: "desktop"
```

**P1.55A 가 규명한 배포 정지 조건과 정확히 동일**했다.
그대로 `kamal deploy` 를 실행했다면 GHCR 푸시에서 조용히 멈췄을 것이다.

### 조치 — BUILDER_RECOVERY.md 방식 C (전역 무변경)

```bash
TMPCFG=<scratchpad>/dockercfg
cp -R ~/.docker "$TMPCFG"
#   credsStore / credHelpers 제거
#   auths["ghcr.io"].auth = base64("sdkdream50a-stack:<KAMAL_REGISTRY_PASSWORD>")
chmod 600 "$TMPCFG/config.json"
DOCKER_CONFIG="$TMPCFG" bin/kamal deploy
```

- 토큰은 `.kamal/secrets` 에서 읽어 **파일에만** 기록했고 출력·로그에 노출하지 않았다.
- 배포 종료 후 임시 디렉터리를 **삭제**했다.
- `~/.docker/config.json` 은 배포 전후 동일(`credsStore: desktop` · `currentContext: desktop-linux`) — **전역 설정 무변경**.

원격 빌더는 정상이었다: `kamal-remote-ssh---root-141-164-53-97-2222` · BuildKit v0.29.0 · running.

## 3. 배포 결과

```
INFO First web container is healthy on 141.164.53.97
Finished all in 78.3 seconds
```

```
REVISION_BEFORE  50c2624399c59c6784ef38f681e1a108393c2f0b
REVISION_AFTER   2d05bae9d99fc47518ae212ea24cd806e8fa67c2
```

## 4. 마이그레이션 (§45)

`docker-entrypoint` 의 `bin/rails db:prepare` 로 컨테이너 부팅 시 적용됐다.

```
NEEDS_MIGRATION = false
SCHEMA_VERSION  = 20260906065000
COLUMNS         = ["alerted_at", "first_failed_at"]
```

```
additive · nullable · reversible · 인덱스 없음 · 백필 없음 · 테이블 삭제/rename 없음
```

## 5. 스모크 테스트 (§46)

| route | 코드 |
|---|:--:|
| `https://silmu.kr/up` | **200** |
| `https://silmu.kr/` | **200** |
| `https://silmu.kr/topics` | **200** |
| `https://silmu.kr/guides` | **200** |
| `https://silmu.kr/audit-cases` | **200** |
| `https://silmu.kr/tools` | **200** |
| `https://silmu.kr/admin/authority_reviews` | **302** (관리자 로그인 리다이렉트 — 기대 동작) |

`bin/rails silmu:freshness:status` 운영 실행 정상 (문서 8건 · 링크 209 · 검토 큐 0).

## 6. 콘텐츠 자동 변경 (§7·§39) — 배포 전후 대조

동일한 pluck 결과를 `Digest::SHA256(Marshal.dump(...))` 로 지문화해 비교했다.

| 테이블 | rows | 배포 전 sha256 | 배포 후 sha256 | 동일 |
|---|:--:|---|---|:--:|
| Topic | 114 | `c6d34d78…0bfbf4` | `c6d34d78…0bfbf4` | ✅ |
| Guide | 103 | `e5a4ecad…d03d4e` | `e5a4ecad…d03d4e` | ✅ |
| AuditCase | 257 | `38d9cab0…652907` | `38d9cab0…652907` | ✅ |

```
EXPECTED automatic content mutations = 0
ACTUAL                               = 0
```

**양성 대조**: 이 지문 비교기가 실제로 변경을 잡는다는 것은 테스트에서 먼저 증명했다
(`Topic#summary` 를 바꾸면 스냅샷이 달라지고, 되돌리면 같아진다 —
`SOURCE_FAILURE_TESTS.md` §5). 탐지기가 죽어 있어서 "0" 이 나온 것이 아니다.

## 7. 운영 데이터 무결성 (§47)

가짜 실패 데이터를 운영에 넣지 않았다.

```
moleg_law_api  failure_count=0  first_failed_at=nil  alerted_at=nil
               last_success_at=2026-09-06 00:40:46 +0900
```

새 컬럼 2개는 **전부 NULL** 로 시작한다 — 실제 장애가 나야 값이 생긴다.
알림 기능의 표현형은 test fixture 에서 검증했고(9 tests · 뮤테이션 7/7 KILLED),
관측 출력(`장애시작=… 알림=… 임계값=…`)의 렌더링은 development DB 의
**롤백된 트랜잭션** 안에서 확인했다.

## 8. 스케줄러 (§31·§48) — 여전히 OFF

운영 컨테이너에서 직접 확인:

```
RECURRING_HAS_FRESHNESS               = false   # AuthorityFreshnessCheckJob 미등록
RECURRING_HAS_ACTIVE_LEGALCOMPLIANCE  = false   # 구 unsafe 잡 주석 그대로
```

`config/recurring.yml` 은 이번 세션에서 **한 글자도 바뀌지 않았다.**
스케줄러 활성화는 별도 승인 단계다.

## 9. 롤백 방법

```bash
bin/kamal rollback 50c2624399c59c6784ef38f681e1a108393c2f0b
```

이미지가 서버에 있다. 마이그레이션은 additive nullable 이라 이전 리비전이 그대로 동작한다
(구 코드는 두 컬럼을 읽지 않는다) — **스키마 롤백 불필요**.
