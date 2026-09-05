# PRODUCTION_ROLLOUT — P1.6

> 상태: **미배포**. 이 문서는 배포 절차와 전제조건만 정리한다.

## 1. 현재

```
BRANCH        feature/silmu-p16-task-first-ux
BASE          fix/tool-accuracy-p1-0804 @ e0342a7
운영 리비전    2d05bae9d99fc47518ae212ea24cd806e8fa67c2 (P1.55B, 변경 없음)
PUSH          없음
DEPLOY        없음
```

## 2. 배포 전 필수 (§75)

```bash
docker info        # ← 반드시 먼저. P1.55B known trap
```
Docker Desktop 이 꺼져 있고 `credsStore: desktop` 이면 GHCR credential lookup 이 멈춘다.
그때는 `docs/silmu-production-completion/BUILDER_RECOVERY.md` 의 **방식 C(격리 DOCKER_CONFIG)** 를 쓴다.
**전역 Docker config 를 수정하지 않는다.**

> BUILDER_RECOVERY §6 이월 사항: P1.55A·P1.55B 모두 방식 C 를 임시 적용했고 영구 채택은 아직이다.
> 매 배포마다 같은 우회가 필요하므로 A/B/C 중 하나를 결정할 시점이다. P1.6 에서 결정하지 않았다.

## 3. 마이그레이션

**없다.** 스키마 변경 0 · 신규 컬럼 0 · 신규 테이블 0.
→ 롤백은 이전 이미지로 되돌리는 것만으로 완결된다(데이터 되돌림 불필요).

## 4. 캐시 (§71)

배포 후 화면이 안 바뀌어 보이면 **DB 실패로 결론내지 않는다.**
Cloudflare edge cache TTL ≈ 4h. 먼저 `CF-Cache-Status` 가 HIT 인지 확인한다.

P1.6 이 건드리는 캐시 키:
```
home/task_entry_counts/v1      (신규, 1h)
home/curated/*                 (기존)
topics/fragment_version        (기존)
```
업무 카드 커버리지는 최대 1시간 지연될 수 있다 — 콘텐츠를 추가한 직후 카드가 안 보여도 정상이다.

## 5. 배포 후 확인 목록

```
[ ] /                      업무 카드가 운영 콘텐츠 기준으로 렌더되는가 (dev 와 다를 수 있음)
[ ] /silmu-search?q=병가 며칠 쓰면 진단서 내야 하나요   → 바로 답 카드
[ ] /topics/private-contract  → 상태 칩 + 지금 해야 할 일
[ ] /topics /guides /audit-cases /tools  전부 200
[ ] /sitemap.xml /robots.txt /feed.rss   전부 200
[ ] rake silmu:p1:leak_scan  → 실제 누출 0 · positive control OK
[ ] 콘텐츠 자동 변이 0 (digest 대조)
```

## 6. 켜지 않는 것

```
AuthorityFreshnessCheckJob 스케줄러   OFF 유지 (별도 승인 사안)
LegacyLegalComplianceJob             영구 비활성
푸터 문구 강화                        금지 (스케줄러 실증 전)
main merge / push                    승인되지 않음
```
