# GIT_REMOTE_RECOVERY — 운영 소스 원격 복구지점 확보

> P1.55B §15~§21. 2026-09-06 06:43 KST 측정 · 06:45 KST 실행.

## 1. 문제 (P1.55B 착수 시점의 실측)

운영 중인 코드가 **로컬 디스크에만 존재**했다.

```
origin/main                       = 74056244ec9ecef46b6f867d29ed2ebe103cc7cd
local  fix/tool-accuracy-p1-0804  = 355a81fcad5be429067627228d1fa49d51ccab31
운영 revision                     = 50c2624399c59c6784ef38f681e1a108393c2f0b
```

측정:

```bash
$ git ls-remote --heads origin 'refs/heads/fix/tool-accuracy*'
(빈 출력 — 원격 브랜치 없음)

$ git merge-base --is-ancestor 50c2624 origin/main; echo $?
1     # 운영 커밋이 원격 어느 ref 에서도 도달 불가

$ git log origin/main..HEAD --oneline | wc -l
8
$ git log HEAD..origin/main --oneline | wc -l
0     # HEAD 가 origin/main 을 완전히 포함 — 분기 아님, 순수 선행
```

원격에 없던 8개 커밋 = **P0 감사 · P1 신뢰층 · P1.5 현행성 엔진 · P1.55 운영배포 · P1.55A 전체**.

```
355a81f docs: P1.55A RESUME_PROMPT — 안전 체크포인트 마감
03f7193 docs: P1.55A 중간 체크포인트 — Admin UI 배포 완료, 잔여 3건 판정
50c2624 docs: P1.55 운영 배포 기록 — Stage 1~4 완료, 스케줄러 미가동   ← 운영 revision
f8975b9 feat(admin): 법령 현행성 검토 큐 UI — 판정만 기록, 콘텐츠 무수정
1bb1c4e fix(law): parse_law_meta 가 <law> 노드를 읽도록 수정 — 시행일 미수신 결함
3c8b340 feat: P1.5 law & regulation freshness engine — READ-ONLY detector
ab6d760 feat: P1 authority trust layer — provenance·검증범위 분리·근거 링크·도구 신뢰
7027801 docs: P0 authority audit — 운영 564 URL 전수 감사 결과
```

즉 **로컬 디스크가 죽으면 운영 중인 코드를 복구할 수 없는 상태**였다.

## 2. 조치 (§18 — 백업 브랜치만)

```bash
git push -u origin fix/tool-accuracy-p1-0804
# * [new branch]  fix/tool-accuracy-p1-0804 -> fix/tool-accuracy-p1-0804
```

원격에 동일 이름 브랜치가 **없었으므로** 충돌·덮어쓰기 판단이 필요 없었다.
force 없음. main 무변경.

## 3. 사후 검증 (§21)

| 성공 조건 | 명령 | 결과 |
|---|---|:--:|
| remote branch 존재 | `git ls-remote --heads origin refs/heads/fix/tool-accuracy-p1-0804` | `355a81f…` ✅ |
| local HEAD 가 원격에서 도달 가능 | `git merge-base --is-ancestor HEAD origin/fix/…` | 0 ✅ |
| **운영 커밋이 원격에서 도달 가능** | `git merge-base --is-ancestor 50c2624 origin/fix/…` | 0 ✅ |
| main 무변경 | `git rev-parse origin/main` | `7405624…` (착수 시점과 동일) ✅ |
| force push 없음 | — | 사용 안 함 ✅ |
| 무관한 작업 덮어쓰기 없음 | 커밋 0건 생성 (기존 커밋만 push) | ✅ |

## 4. 작업 트리에 남은 미커밋 변경 (§20 — 분리 판정)

착수 시점 `git status --short` 의 미커밋 항목은 **전부 에이전트 런타임 산출물**이었다.

```
.omc/**            (세션 상태·플랜·리서치)
.claude/**         (agent-memory 감사 기록·scheduled_tasks.lock)
.gitignore · .mcp.json
```

silmu 애플리케이션 소스는 한 건도 없었다 → **이번 작업과 분리**했고 commit 하지 않았다.

## 5. 남은 리스크

```
main 은 여전히 운영보다 뒤에 있다 (74056244 = 배포 이전 상태).
main 병합은 이번 세션에서 승인되지 않았다(§19).
```

원격 복구지점은 확보됐으므로 **재해복구 리스크는 해소**됐다.
main 정렬은 별도 승인 사안으로 남는다.
