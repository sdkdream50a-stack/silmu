# BACKUP_ROLLBACK — 복구 준비 상태

> §6 — 실제 복구 경로가 불명확하면 production write 를 진행하지 않는다.

---

## 1. DB 백업 — ✅ 검증됨

**자동화**
```
crontab: 0 2 * * *  /root/backup.sh >> /root/backup.log 2>&1
backup.sh:  backup_postgres "silmu_production" "silmu"
            backup_volume   "silmu-web" "/rails/storage" "silmu"
```

**실물 확인** (`/root/backups/silmu/`)
```
silmu_production_20260829_020001.dump   3,695,299 B
…
silmu_production_20260905_020001.dump   3,789,437 B   ← 최신 (약 25시간 전)
silmu_20260905_020001.tar.gz                3,062 B   ← storage 볼륨
```
- 8일치 이상 보존 확인
- `backup.sh` 는 백업 누락 시 `ALERT` 를 로그에 남긴다 (실제로 `seteuk_preview has no backup file` 경고가 동작 중 → **알림 기능이 살아 있음이 증명됨**)
- silmu 는 `ALERT` 없음 = 정상 백업 중

**write 직전 수동 백업 (필수)**
```bash
ssh root@141.164.53.97 \
  'sudo -u postgres pg_dump -Fc silmu_production > /root/backups/silmu/silmu_production_prewrite_$(date +%Y%m%d_%H%M%S).dump'
```

**복구**
```bash
ssh root@141.164.53.97 \
  'sudo -u postgres pg_restore -d silmu_production --clean --if-exists /root/backups/silmu/<dump>'
```

## 2. 코드 롤백 — ✅ 가능

**보유 이미지**
```
ghcr.io/sdkdream50a-stack/silmu:74056244ec9ecef46b6f867d29ed2ebe103cc7cd  ← 현재 운영
ghcr.io/sdkdream50a-stack/silmu:08cb935dcee5d460c187b36ad03aac8bbdd7e560  ← 직전
ghcr.io/sdkdream50a-stack/silmu:latest
```

**Kamal 롤백**
```bash
cd ~/project/silmu
bin/kamal app version                 # 현재 리비전 확인
bin/kamal rollback 74056244ec9ecef46b6f867d29ed2ebe103cc7cd
```
직전 이미지가 서버에 남아 있으므로 이미지 재빌드 없이 즉시 되돌릴 수 있다.

## 3. 마이그레이션 롤백

P1·P1.5 마이그레이션은 전부 additive·reversible이며 dev 에서 왕복 검증했다.
```bash
bin/kamal app exec --reuse 'bin/rails db:rollback STEP=3'   # P1.5 3개
bin/kamal app exec --reuse 'bin/rails db:rollback STEP=3'   # P1 3개
```

⚠️ **`STEP` 은 "적용된 마지막 n개"다.** 실행 전 반드시 대상을 확인한다.
```bash
bin/kamal app exec --reuse 'bin/rails db:migrate:status' | tail -10
```
(P1.5 세션에서 이 함정으로 dev backfill 값을 잃은 전례가 있다)

## 4. backfill 롤백

P1 backfill 은 **신규 컬럼에만** 쓴다. 기존 컬럼은 읽기만 한다.
잘못되면 신규 컬럼을 비우면 되고, 앱은 컬럼이 비어도 보수적 기본값으로 동작한다.
```sql
UPDATE audit_cases SET source_type=NULL, source_agency=NULL, source_title=NULL,
       source_url=NULL, source_year=NULL, source_page=NULL, source_reference=NULL,
       is_reconstructed=NULL, provenance_confidence=NULL,
       verification_status=NULL, verification_note=NULL;
```

## 5. 롤백 트리거 (§43)

다음 중 하나라도 발생하면 **즉시 다음 단계를 중단**하고 위 절차로 되돌린다.
```
5xx 증가 · 페이지 렌더 오류 · 예기치 않은 콘텐츠 변경
중복 version/event · 거짓 freshness 경고 · 외부 요청 폭주
DB lock/지연 · provenance 덮어쓰기
```

## 6. 판정

```
BACKUP_VERIFIED   = YES  (일일 자동 + 실물 8일치 + 알림 동작 확인)
ROLLBACK_PATH     = YES  (Kamal 이미지 2개 + 마이그레이션 reversible + backfill 되돌리기 가능)
DISK_HEADROOM     = YES  (39G)
→ §6 조건 충족. production write 를 진행할 수 있는 상태다.
```
