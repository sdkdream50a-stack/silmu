# ADMIN_REVIEW_UI — 검토 큐 화면

> §24 — 목표는 아름다운 UI 가 아니라 한 화면에서 필요한 것을 보는 것.

## 1. 경로

```
GET  /admin/authority_reviews              검토 큐
POST /admin/authority_reviews/:id/decide   판정 기록
```
`Admin::BaseController` 상속 → 로그인 + admin 권한 + 30분 step-up 재인증.

## 2. 한 화면에 보이는 것 (§24 요구)

| 요구 | 구현 |
|---|---|
| changed document | 태스크마다 `근거 <문서명>` |
| effective date | `시행일 YYYY.MM.DD` · 미래면 **(시행 예정)** 강조 |
| diff | `diff: <diff_summary>` (조문 변경 포함) |
| affected content | `affected_label` (타입 / 제목) |
| impact level | `P<우선순위> <DIRECT/INDIRECT/POSSIBLE/UNKNOWN>` 색상 배지 |
| review status | 태스크 `status` + 처리 완료 시 검토자·시각·메모 |

상단에 감시 대상 표(문서·유형·현행 시행일·버전수·간선수·마지막 검사)와
통계 5종(검토 대기·전체 태스크·열린 변경·최근 7일 검증·영향 간선)을 함께 보여준다.

## 3. §25 결정 5종

```
IMPACT_CONFIRMED · NO_IMPACT · UPDATE_REQUIRED · NEEDS_LEGAL_REVIEW · DEFERRED
```
`AuthorityReviewTask::DECISIONS` 를 그대로 순회해 버튼을 만든다 —
**모델의 state model 과 화면이 어긋날 수 없다**(상수가 단일 출처).
알 수 없는 값은 컨트롤러에서 거부한다.

## 4. 안전 (§26·§27)

| 보장 | 방법 |
|---|---|
| 콘텐츠 무수정 | 컨트롤러는 `task.decide!` 만 호출. 게시 모델에 쓰기 없음 |
| 위험 전이 방지 | `IMPACT_CONFIRMED` → `REVIEW_REQUIRED` 유지 (VERIFIED 로 가지 않음) |
| 검증 이력 | 판정마다 `AuthorityVerificationEvent` 생성 (어떤 **버전**을 보고 판정했는지 포함) |
| 권한 | 비로그인·비관리자 접근 차단 |

## 5. 회귀 테스트 8종

| 테스트 | 검증 |
|---|---|
| 비로그인 차단 | redirect |
| 비관리자 차단 | redirect |
| 한 화면에 변경·시행일·영향·근거 | 문서명·DIRECT·제25조 노출 |
| §25 결정 5종 제공 | 5개 버튼 전부 |
| NO_IMPACT 판정 | 검증 이벤트 +1 · `VERIFIED_AFTER_CHANGE` 전이 · 검토자 기록 |
| **§26 위험 전이 방지** | `IMPACT_CONFIRMED` → `REVIEW_REQUIRED` 유지 |
| 알 수 없는 결정 거부 | 상태 `OPEN` 유지 |
| **§27 콘텐츠 무수정** | 판정 후 title·issue·detail·legal_basis·published 동일 |

## 6. 배포 상태 — ⚠️ 코드는 커밋됐으나 **운영 미배포**

```
커밋   f8975b9  (테스트 8/8 통과 · rubocop 0 offenses)
배포   실패 — kamal buildx 가 3회 연속 정지
```

증상: `docker buildx build` 가 시작된 뒤 진행 출력 없이 멈추고, 원격 buildkit 컨테이너 CPU 가
0.01~0.40% 로 유휴 상태가 된다. 이미지가 GHCR 에 푸시되지 않는다.

시도한 조치
1. 프로세스 kill 후 재시도 → 같은 지점에서 정지
2. 원격 buildkit 컨테이너 재시작 후 재시도 → 같은 지점에서 정지

**같은 세션의 첫 배포(`1bb1c4e`)는 117.9초에 정상 완료**했으므로 구조적 문제는 아니고
빌더가 그 이후 열화된 것으로 보인다. 3회 반복 실패이므로 더 시도하지 않았다.

영향
- 운영에는 Admin UI 가 **없다.** 검토는 `bin/rails silmu:freshness:review_queue` 로 가능하다.
- 현재 검토 대기 태스크가 0건이라 실무 지장은 없다.
- P1.55 핵심 목표(Stage 1~4)는 `1bb1c4e` 로 이미 달성·검증되었다.

다음 세션 조치안
```bash
docker buildx rm kamal-remote-ssh---root-141-164-53-97-2222   # 빌더 재생성
bin/kamal build create
bin/kamal deploy
```
또는 로컬 빌드로 전환(`builder: local` 또는 `arch: amd64` 확인).

## 7. 현재 운영 상태

```
검토 대기 0 · 전체 태스크 0 · 열린 변경 8(기준선) · 영향 간선 209
```
검토할 것이 없으면 "검토 대기 중인 태스크가 없습니다 / 감지된 법령 변경이 없거나 모두 판정 완료되었습니다" 를 보여준다.

## 8. 개발 중 발견한 것

Devise 통합 테스트에서 `post admin_reauthentication_path` 를 호출하면 **세션이 파괴되어** 이후 요청이 로그인 페이지로 튕겼다.
확인 결과 `config/initializers/warden_admin_hook.rb` 가 `Warden::Manager.after_set_user` 에서 이미
`session[:admin_confirmed_at]` 을 설정하므로 **재인증 POST 자체가 불필요**했다.
(테스트에서 굳이 호출한 것이 문제였고, 운영 동작에는 영향 없다.)

## 9. 남은 개선 (P2)

- 문서별 필터·페이지네이션 (현재 200건 상한)
- diff 전문 보기 (현재 요약만)
- 일괄 판정
- 검증 이력 조회 화면
