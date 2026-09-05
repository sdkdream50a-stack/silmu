# BUILDER_RECOVERY — 배포 빌더 정지 원인 규명

> P1.55 에서 `kamal deploy` 가 buildx 단계에서 3회 연속 정지했다. 그때의 진단은 **틀렸다.**

---

## 1. P1.55 의 잘못된 진단 (정정)

P1.55 문서와 커밋에 다음과 같이 적었다.
> "같은 세션 첫 배포는 117.9초 정상이었으므로 **빌더 열화**로 판단"

**틀렸다.** 원격 빌더는 처음부터 정상이었다.

## 2. 실측 (§3 — 추측하지 않는다)

| 확인 | 결과 |
|---|---|
| `docker buildx ls` | 원격 빌더 2개 **running** (v0.30.0 / v0.29.0) |
| `docker buildx inspect …-2222` | Status running · BuildKit v0.29.0 · Last Activity 기록됨 |
| **최소 빌드 시험** (`alpine` + `--output=type=cacheonly`) | **성공** — `builder-alive` 출력, 0.4초 |
| 원격 buildkit CPU | 정지 시점 0.01~0.4% = **아무것도 전달되지 않았다** |
| 서버 부하 | load 0.32 · 디스크 39G 여유 |

→ 빌더는 정상. 문제는 **빌드가 빌더에 도달하기 전** 단계다.

## 3. 곁가지에서 배제한 것

| 가설 | 검증 | 판정 |
|---|---|---|
| 원격 빌더 손상 | 최소 빌드 성공 | ❌ 기각 |
| SSH 포트 22 차단(fail2ban) | 서버 sshd 는 **2222 만** 리스닝. `~/.ssh/config` 가 이 호스트를 2222 로 매핑 → 내 SSH 는 처음부터 2222 를 썼다 | ❌ 기각 (문제 아님) |
| 서버 자원 부족 | load 0.32 · 39G 여유 | ❌ 기각 |

## 4. 근본 원인

```
~/.docker/config.json
{
  "auths": { "ghcr.io": {} },
  "credsStore": "desktop",          ← Docker Desktop 자격증명 헬퍼
  "currentContext": "desktop-linux"
}
```

```
$ docker info
failed to connect to the docker API at unix:///Users/seong/.docker/run/docker.sock
$ ls ~/.docker/run/          →  (비어 있음, dir mtime Aug 4)
$ pgrep -fl "Docker Desktop" →  (없음)
```

**Docker Desktop 이 실행되고 있지 않다.**
`kamal deploy` 는 `docker buildx build --output=type=registry` 로 GHCR 에 **직접 푸시**한다.
그 푸시는 `credsStore: desktop` → `docker-credential-desktop` 을 호출하고,
Docker Desktop 백엔드 소켓이 없으므로 **응답 없이 멈춘다**.

빌드가 시작 로그만 남기고 진행 출력이 전혀 없던 것, 원격 빌더 CPU 가 유휴였던 것이 전부 이것으로 설명된다.

### 왜 첫 배포는 성공했나
P1.55 첫 배포(117.9초)는 성공했고 그 이후만 실패했다.
Docker Desktop 은 그때도 꺼져 있었으므로(소켓 디렉터리 mtime = 8/4) **자격증명이 다른 경로로 해결된 상태**였던 것으로 보인다(세션 캐시 추정).
이 부분은 **확정하지 못했다** — `UNMEASURED` 로 남긴다. 다만 재현 가능한 실패 조건과 해결책은 확정했다.

## 5. 해결 — 전역 설정 무변경

사용자의 `~/.docker/config.json` 을 고치지 않고, **격리된 DOCKER_CONFIG** 를 만들어 사용했다.

```bash
TMPCFG=<scratchpad>/dockercfg
cp -R ~/.docker "$TMPCFG"        # 컨텍스트·빌더 정의·CLI 플러그인 포함 전체 복사
# config.json 에서
#   credsStore / credHelpers 제거
#   auths["ghcr.io"].auth = base64("sdkdream50a-stack:<KAMAL_REGISTRY_PASSWORD>")
chmod 600 "$TMPCFG/config.json"

DOCKER_CONFIG="$TMPCFG" bin/kamal deploy
```

토큰은 `.kamal/secrets` 에서 읽어 **파일에만** 기록했다(출력·로그에 노출하지 않음).

### 검증 (푸시 경로 단독 시험)
```
#7 [auth] sdkdream50a-stack/silmu:pull,push token for ghcr.io   DONE 0.0s
#6 pushing layers                                                3.0s done
#6 pushing manifest for ghcr.io/sdkdream50a-stack/silmu:credtest 1.7s done
#6 DONE 4.8s
```
멈추던 지점이 **4.8초에 통과**했다.

### 실제 배포 결과
```
INFO First web container is healthy on 141.164.53.97
Finished all in 79.6 seconds
EXIT=0
```

## 6. 영구 조치안 (다음 세션 판단 필요)

| 안 | 장점 | 단점 |
|---|---|---|
| A. Docker Desktop 실행 후 배포 | 원래 워크플로 | GUI 의존 · 배포마다 확인 필요 |
| B. `credsStore` → `osxkeychain` 으로 전역 변경 | Desktop 불필요 | 키체인에 GHCR 토큰 등록 필요 · 사용자 전역 설정 변경 |
| C. 배포 스크립트가 격리 DOCKER_CONFIG 를 쓰도록 고정 | 전역 무변경 · 재현 가능 | 토큰이 임시 파일에 존재(권한 600) |

**이번 세션은 C 를 임시 적용**했고 영구 채택은 하지 않았다. 사용자 환경 설정 변경은 별도 판단 사항이다.

## 7. 남긴 흔적

GHCR 에 시험용 태그 `ghcr.io/sdkdream50a-stack/silmu:credtest` 를 푸시했다(alpine 기반 소형 이미지).
**정리 대상** — 다음 세션에서 삭제하거나, GHCR 패키지 화면에서 제거한다.
