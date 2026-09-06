# RESUME_PROMPT — SILMU P2 R2 이후 다음 세션 시작점

> 2026-09-06 세션 ④(R2 구현). **구현·검증 완료 · 운영 배포 0 · 커밋 0.**
> R2 는 "글을 늘리는" 작업이 아니라 **두 도구가 조문과 어긋난 결론을 내던 것을 고친** 작업이다.

---

## 0. 세션 시작 시

```bash
date; date -u
cd /Users/seong/project/silmu
git status --short --branch
git log --oneline -5
curl -sI https://silmu.kr/up | head -1
```

기억한 값보다 실측값이 우선이다.

## 1. 상태 (실측 · 2026-09-06)

```
BRANCH               feature/silmu-p2-general-admin-expansion
HEAD                 f10ad5c (세션 시작 시점) — R2 변경은 아직 커밋되지 않았다
PRODUCTION_REVISION  ce62d2ebee5e465bb230cccf9134e2ada9c71d20   ← R1. 운영은 그대로다
ROLLBACK             ce62d2e
운영 health           200 (/up)
P1_6_STATUS          DEPLOYED · CLOSED/FROZEN — 7파일 해시 대조로 무변경 확인
R1_STATUS            DEPLOYED · CLOSED — 8질의 도구 발견성 유지 확인
R2_STATUS            PRODUCTION_READY (배포 승인 대기) — 근거는 11 문서
독립검증              gemini(파일) 6건 중 5건 수리·1건 기각 · kimi(텍스트) 12건 중 3건 수리·7건 이미충족·2건 기각
                     codex-critic 은 두 번 실측 모두 쿼터 소진(9/7 14:10 해제) — repo 전체를 본 독립 레인은 없다
테스트                599 runs · 3,474 assertions · 0F · 0E · 14 skips (BEFORE 497/3,138/14)
RuboCop              0 offenses
뮤테이션              KILLED=27 · SURVIVED=0 · NOT_APPLIED=0
콘텐츠 변이            0 · DB 마이그레이션 0 · 스키마 0 · 신규 도구 URL 0
```

## 2. R2 가 실제로 고친 것

두 도구는 **조문과 어긋난 결론을 확신 있게 내고 있었다.**

```
① 물품·용역 2천만 초과에서 상대방 자격을 묻지 않고 "수의계약"이라 단정
   — 같은 응답의 작은 글씨는 "일반 업체는 2천만원 초과 시 경쟁입찰 대상"이라고 반대로 적혀 있었다
② `협동조합`을 특례 상대방으로 제시 — 조문(§25①5호바목 4))이 가리키는 건 사회적협동조합이다
③ 청년창업기업(5천만)·소기업/소상공인(1억)이 선택지에 없었다
④ 분할 체크리스트가 물품·용역 분할의 근거로 §77(공사의 분할계약 금지)을 인용
⑤ 합산 기간이 "최근 3개월" — 조문(§7제2호)은 12개월/회계연도
⑥ 위험도가 "체크 3개 이상" — 조문에 없는 임의 점수
⑦ 적법한 분리(§77①1~3호) 경로가 없어 법령상 분리발주까지 위험으로 표시
⑧ 두 도구 모두 테스트 0건
```

**가장 중요한 발견**: 물품·용역 분할은 *금지*가 아니라 **§7제2호 추정가격 합산**으로 규율된다.
구조를 잘못 알아서 근거 조문이 틀렸고, 그래서 합산 기간이 조문에 없는 3개월이 됐다.

## 3. 만든 것

```
config/contract_decision_rules.yml               규칙집 (판정의 단일 출처. 코드에 금액 리터럴 0)
app/services/contract_decision/
  rule_set.rb                                    근거 없는 rule 은 로딩 거부 (+ 양성대조 테스트)
  private_contract_evaluator.rb                  §25①5호 + 6상태
  quotation_requirement.rb                       §30① (§25 와 다른 임계)
  split_procurement_evaluator.rb                 §77 트랙 / §7제2호 트랙 분리
POST /tools/split-contract-checker/evaluate      분할 판정 서버화
test/services/contract_decision/ (4종) · test/integration/contract_decision_flow_test.rb
docs/silmu-p2/r2/ (01~10 · RESUME · _measure · _data)
```

## 4. ⛔ 다음 세션이 먼저 봐야 할 것

`docs/silmu-p2/r2/11_INDEPENDENT_REVIEW.md` 를 읽고 **R2_STATUS 확정값**을 확인하라.
`09_PRODUCTION_ROLLOUT.md` §5 에 남은 승인 지점 5개가 있다.

```
① 독립검증 결과 처분      ← 11 문서
② 커밋                    이번 세션은 커밋하지 않았다
③ 운영 배포               ①② 이후 별도 승인
④ Solution Page 콘텐츠     05 문서 사양. FAQ·howto_steps·target_agency = 콘텐츠 변이
⑤ LEGACY_UNVERIFIED 검증  낙찰하한율·원가계산 비율 (R2 범위 밖이나 "공식 기준" 표시 여부 확인 필요)
```

## 5. 건드리지 않는 것

```
P1.6 검색 엔진 7파일        FROZEN. 해시 대조로 무변경 확인했다
tools_registry keywords    R1 자산. 한 글자도 안 바꿨다
Authority/Freshness core   변경 0 · scheduler OFF 유지
낙찰하한율·원가계산 비율     LEGACY_UNVERIFIED 로 분류만. R2 판정 경로 밖
command_center             §25 — 무수정
운영 콘텐츠                 AUTO_PUBLISH=OFF · 변이 0
SearchLog                  행 삭제 금지. 12:10~12:15 KST 45건은 R1 검증 트래픽(수요 아님)
```

## 6. 다음 세션이 잊으면 안 되는 것

```
· dev DB ≠ 운영. `split-contract-prohibition` 은 dev 에 없고 운영에 있다.
  dev 기준으로 봤으면 "토픽 없음"이라는 틀린 전제로 새 글을 썼을 것이다 (R1 P-3 와 같은 함정)
· Authority 스택은 조문 **본문**을 갖고 있지 않다 — normalized_content 는 메타데이터 127~190자이고
  시행령 항목엔 "제25조 … 기존 조문 본문" 이라는 자리표시 문자열이 있다.
  09 문서의 "LOADED" = 현행성 메타데이터 적재. 근거 텍스트는 법제처 API 에서 가져와야 한다
· §25 한도와 §30 견적요건은 **다른 숫자다.** 소기업·소상공인은 §25 로 1억까지 수의계약이 되지만
  §30 의 1인 견적 열거에는 없다. 두 축을 합치면 반드시 틀린다
· 뮤테이션 `SURVIVED=0` 은 **내가 고른 축에서 0**이라는 뜻이다.
  §33 의 9종은 전부 죽었는데, R2 가 수리한 결함을 되돌리는 5종을 추가하니 2건이 살아남았다.
  그 뒤 조합 전수 프로브가 테스트·뮤테이션을 다 통과한 결함 2건을 또 찾았고,
  독립검증이 다시 5건을 찾았다. 초록은 어느 단계에서도 증거가 아니었다
· **외부 리뷰어의 지적도 그대로 받지 않는다.** gemini 가 BLOCKING 으로 올린 1건은
  조문 원문에 없는 문장을 인용한 것이었다. 재대조 없이 받았다면 맞는 구현을 틀리게 고쳤을 것이다
· "0건"·"UNCHANGED"를 보고하기 전에 **그 검사가 양성을 잡는지** 먼저 증명한다.
  이 세션에서 answer_for 를 잘못된 인자로 불러 전 질의 "답 없음"이라는 거짓 음성을 한 번 만들었다
```

## 7. 재측정

```bash
REV=$(ssh root@141.164.53.97 'docker ps --format "{{.Names}}" | grep ^silmu-web-')
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/r2/_measure/r2_asset_audit.rb
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/r2/_measure/r2_reachability.rb
ssh root@141.164.53.97 "docker exec -i $REV bin/rails runner -" < docs/silmu-p2/r2/_measure/r2_engine_probe.rb   # 배포 후에만 의미 있음
bash docs/silmu-p2/r2/_measure/mutation_r2.sh
```

`r2_reachability.rb` 는 **양성대조를 먼저 돌린다** — "답 없음"·"도구 0"을 보고하기 전에
프로브가 양성을 잡는지 증명한다.
