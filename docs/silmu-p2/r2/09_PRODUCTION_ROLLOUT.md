# 09 — PRODUCTION ROLLOUT (미실행)

> §35: **이번 세션에서 운영 배포는 금지.** 이 문서는 배포 계획이지 배포 기록이 아니다.
> R1 배포 기록(`../13_R1_PRODUCTION_ROLLOUT.md`)과 혼동하지 말 것.

---

## 1. 현재 상태

```
PRODUCTION_REVISION   ce62d2ebee5e465bb230cccf9134e2ada9c71d20   (R1 · 2026-09-06 12:10 KST)
R2                    로컬 브랜치에만 존재. 커밋 여부는 아래 §5
배포                  0
운영 콘텐츠 변이       0
ROLLBACK              ce62d2e (현재 운영본이 곧 롤백 지점)
```

## 2. 배포 전 확인 (승인 후)

```bash
# ① 비회귀
bin/rails test                    # 565 runs · 0F · 14 skips 기대
bin/rubocop
bash docs/silmu-p2/r2/_measure/mutation_r2.sh   # KILLED=14 SURVIVED=0 NOT_APPLIED=0

# ② 동결 확인 (양성대조 포함)
git diff --stat HEAD -- app/services/search_query_parser.rb app/models/topic.rb   # 비어 있어야 함
git diff --stat HEAD -- app/services/contract_method_service.rb                    # 비어 있으면 검사가 죽은 것

# ③ 운영 read-only 재측정
REV=$(ssh root@141.164.53.97 'docker ps --format "{{.Names}}" | grep ^silmu-web-')
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/r2/_measure/r2_reachability.rb
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/_measure/positive_control.rb
```

## 3. 배포 후 운영 재현 (R1 절차와 동일)

| # | 확인 | 기대 |
|---|---|---|
| 1 | `/up` | 200 |
| 2 | `/tools/contract-method` 렌더 | 기관 선택 6종 · 상대방 9종 노출 · `data-cp="COOPERATIVE"` **부재** |
| 3 | `POST /contract-methods/determine` goods/3천만/상대방 없음 | `decision.state = INSUFFICIENT_INFORMATION` |
| 4 | 〃 counterparty=GENERAL | `COMPETITIVE_PROCEDURE_REQUIRED` · `result.method = "입찰"` |
| 5 | 〃 counterparty=SMALL_ENTERPRISE | `POSSIBLE` · `matched_rule.rule_id = D25-1-5-라` |
| 6 | `POST /tools/split-contract-checker/evaluate` 물품 합산 | `제7조제2호` · `window_months = 12` · §77 **미인용** |
| 7 | 〃 공사 + `separation_ground=D77-1-1` + 회피 아님 | `LEGITIMATE_SEPARATION_POSSIBLE` |
| 8 | R1 8질의 도구 발견성 | 전건 `tool_count ≥ 1` |
| 9 | P1.6 정밀도 3종 | 07 §3 과 동일 |
| 10 | 모바일 렌더 · SEO 메타 | R1 절차 그대로 |
| 11 | 콘텐츠 카운트 | Topic 114 · FAQ 저작 474 · 도달 474 · NON_ARRAY 0 (변이 0 증명) |

**음성대조**: 무관 질의("병가")에 계약 도구가 새로 붙지 않을 것.

## 4. 롤백

코드 변경만이고 마이그레이션·스키마·콘텐츠 변경이 0 이므로
`ce62d2e` 이미지로 되돌리면 완전 복구된다. 데이터 복구 절차 불필요.

## 5. 남은 승인 지점

| 지점 | 결정 |
|---|---|
| **① 독립검증 재실행** | 승인된 2레인이 쿼터 소진(11 문서). 대체 레인 승인 또는 쿼터 회복 후 재실행 |
| ② 커밋 | 이번 세션은 커밋하지 않았다. 커밋 범위·메시지 승인 필요 |
| ③ 운영 배포 | ①·② 이후 별도 승인 |
| ④ Solution Page 콘텐츠 반영 (05 문서) | FAQ·howto_steps·target_agency 는 콘텐츠 변이라 별도 승인 |
| ⑤ `LEGACY_UNVERIFIED` 값 검증 | 낙찰하한율·원가계산 비율. R2 범위 밖이나 "공식 기준" 표시 여부는 확인 필요 |
