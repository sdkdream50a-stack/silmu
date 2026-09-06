# PRODUCTION_ROLLOUT — P1.6

> 상태: **DEPLOYED**. 2026-09-06 10:16:46~10:18:18 KST (91.1s).
> 이 문서는 실제 배포 실측 기록이다.

## 1. 배포 대상

```
BRANCH            feature/silmu-p16-task-first-ux
APPROVED_HEAD     18fb7350cbd07c069775f69aef51c0ca8956982a
REMOTE_PUSH       없음 — kamal 2.11 원격 빌더는 로컬 컨텍스트를 쓰므로 push 가 배포 조건이 아니다.
                  롤백도 서버 로컬 이미지 태그로 가능(아래 §6). 그래서 push 하지 않았다.
PRODUCTION_BEFORE 2d05bae9d99fc47518ae212ea24cd806e8fa67c2  (P1.55B)
PRODUCTION_AFTER  18fb7350cbd07c069775f69aef51c0ca8956982a
DELTA             12 커밋 · app 11 파일 · test 7 파일 · docs 19 파일
                  db/ · config/ 변경 **0** → 마이그레이션 0 · 라우트 0 · 스케줄러 설정 0
```

`2d05bae` 는 `18fb735` 의 조상이다(`git merge-base --is-ancestor` 확인) — 전진 배포, 히스토리 분기 없음.

## 2. Docker preflight (P1.55B known trap 재현됨)

```
docker info                  → DOCKER_UNAVAILABLE (로컬 데몬 없음)
pgrep -fl "Docker Desktop"   → (없음)
~/.docker/config.json        → credsStore: "desktop"
```

P1.55A/B 가 규명한 **배포 정지 조건과 동일**. 그대로 `kamal deploy` 했다면 GHCR 푸시에서 멈췄다.
→ `BUILDER_RECOVERY.md` 방식 C(격리 DOCKER_CONFIG)만 사용. **전역 `~/.docker/config.json` 무변경**
(배포 전후 `credsStore: desktop` · `currentContext: desktop-linux` 동일 확인).

## 3. 배포 명령

```bash
DOCKER_CONFIG=<격리사본> bin/kamal deploy --version=18fb7350cbd07c069775f69aef51c0ca8956982a
```

`--version` 을 명시한 이유: 워킹트리에 `.omc/` · `.claude/` · `.mcp.json` 환경 잔재가 더티로 남아 있어
kamal 기본 버전 산출이 `<sha>_uncommitted_<hex>` 를 만든다. 그러면 운영 리비전이 승인 SHA 와
달라지고 SHA 기반 롤백 의미가 깨진다. 환경 잔재는 **커밋하지 않았다**(다른 세션 소유분 포함).

```
INFO First web container is healthy on 141.164.53.97
Finished all in 91.1 seconds
EXIT=0
```

## 4. 배포된 artifact = 18fb735 인가 (exit=0 을 성공으로 치지 않는다)

컨테이너 안 파일과 `git rev-parse 18fb735:<path>` blob 해시를 대조했다.

| 파일 | 판정 |
|---|:--:|
| `app/models/topic.rb` | MATCH |
| `app/services/search_query_parser.rb` | MATCH |
| `app/views/home/index.html.erb` | MATCH |
| `app/views/layouts/_nav_v2.html.erb` | MATCH |

`kamal app version` → `18fb7350cbd07c069775f69aef51c0ca8956982a`.

## 5. 공개 검증 (캐시와 원본 구분)

첫 평문 요청은 `cf-cache-status: UPDATING` · `age: 174` 로 **배포 전 캐시본**이었다 —
여기서 멈췄다면 "배포 실패"로 오판했을 것이다. 유니크 쿼리로 캐시 우회(`?cb=…`) 하니
`cf-cache-status: MISS` 로 원본이 왔고 P1.6 마커 4종이 전부 present.
그 뒤 엣지가 stale-while-revalidate 로 스스로 갱신됐다(`HIT` · age 31 · 마커 present).
**전체 purge 는 하지 않았다.**

## 6. 롤백

```
서버 로컬 이미지  ghcr.io/sdkdream50a-stack/silmu:2d05bae9d99… (923b685818ca) 보유
백업             /root/backups/silmu/ 63개 · 최신 prewrite 20260905_153316.dump
마이그레이션      이번 배포 0건 → DB 롤백 불필요
명령             bin/kamal rollback 2d05bae9d99fc47518ae212ea24cd806e8fa67c2
```

READY=YES · EXECUTED=NO (실패 조건 미발생).
