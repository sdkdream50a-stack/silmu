# MIGRATION_ROLLOUT — 스키마 배포 기록

## 1. 배포 전 상태

```
운영 리비전   74056244ec9ecef46b6f867d29ed2ebe103cc7cd  (= 커밋 7405624, Up 2주)
적용 마이그레이션 62개 · 최신 20260611202659
P1/P1.5 마이그레이션 적용 0/6
```

## 2. 커밋 (Phase 별 4개 + Admin UI 1개)

| 커밋 | 내용 |
|---|---|
| `7027801` | docs: P0 authority audit — 운영 564 URL 전수 감사 |
| `ab6d760` | feat: P1 authority trust layer |
| `3c8b340` | feat: P1.5 law & regulation freshness engine |
| `1bb1c4e` | fix(law): parse_law_meta `<law>` 노드 수정 + rollout 문서 |
| `f8975b9` | feat(admin): 법령 현행성 검토 큐 UI |

## 3. 사전 백업 (§6)

```
/root/backups/silmu/silmu_production_prewrite_20260905_153316.dump   3,792,275 B
무결성: pg_restore -l → 26 TABLE DATA · audit_cases 포함 확인
```
일일 자동 백업(02:00)과 별개로 write 직전에 수동 생성했다.

## 4. Stage 1 — 배포 실행

```bash
bin/kamal deploy
```
```
Building image … → push → pull on 141.164.53.97
docker run … silmu-web-1bb1c4e6d2cae1b27c6e24cf1048e8b700729d9e
kamal-proxy deploy silmu-web --host silmu.kr --host www.silmu.kr --host exam.silmu.kr
INFO First web container is healthy on 141.164.53.97
Finished all in 117.9 seconds
```

- 무중단 교체 (health check `/up` 통과 후 구 컨테이너 stop)
- 같은 서버의 다른 5개 앱(fateaiverse·command_center·student_record_master·intervu_promotion·intervu)은 영향 없음

## 5. 마이그레이션 적용

`bin/docker-entrypoint` 가 `rails server` 기동 시 `db:prepare` 를 실행하므로 **컨테이너 부팅과 함께 자동 적용**되었다.

검증 (운영 DB 직접 조회)
```
적용 확인: 20260905230000 · 20260905230100 · 20260905230200
          20260906010000 · 20260906010100 · 20260906010200   → 6/6
authority 계열 테이블: 7개 생성
콘텐츠 행수: topics 114 · guides 103 · audit_cases 257   (변화 없음)
신규 컬럼: source_type 0건 · freshness_state 0건          (backfill 전 = 정상)
```

- `strong_migrations` 우회 없음
- 전부 additive·nullable — 기존 행 무영향
- 인덱스는 `algorithm: :concurrently` (테이블 잠금 없음)

## 6. Stage 1 스모크 테스트

`PRODUCTION_SMOKE_TEST.md` 참조 — 대표 18 URL 전부 2xx, 5xx 0건.

## 7. Admin UI 배포 (2차)

커밋 `f8975b9` 를 같은 절차로 배포.
스키마 변경 없음(라우트·컨트롤러·뷰만).

## 8. 롤백 경로 (사용하지 않음)

```bash
bin/kamal rollback 74056244ec9ecef46b6f867d29ed2ebe103cc7cd
bin/kamal app exec --reuse 'bin/rails db:rollback STEP=3'   # ← 대상 확인 후
```
⚠️ `STEP` 은 "적용된 마지막 n개"다. 실행 전 `db:migrate:status` 로 확인한다.
