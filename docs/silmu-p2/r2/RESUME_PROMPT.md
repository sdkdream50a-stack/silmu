# SILMU R2 — FINAL INDEPENDENT REVIEW HANDOFF

```
CODE_TARGET          ea18c18
STATUS               REVIEW_REQUIRED
R-A                  FIXED
R-H                  FIXED
R2_CORE_MODIFIED     YES
INDEPENDENT_REVIEW   NOT_RUN
DEPLOY               NO
SEED_EXECUTED        NO
```

**다음 정확한 작업 — `ea18c18` 을 대상으로 host 와 다른 vendor 독립검증 1회.**
codex-critic 은 **2026-09-07 14:10 KST 이후**에 열린다(provider 메시지 실측).
**검증 통과 전 deploy · seed · main merge 금지.**

> 이 문서는 2026-09-07 06:5x KST shutdown-safe handoff 로 갱신됐다.
> 이전 판(2026-09-06 세션 ④)은 `HEAD f10ad5c · R2_STATUS PRODUCTION_READY` 라고 적고 있었으나
> 그 뒤 **커밋 6개**가 더 쌓였고 독립검증이 blocking 을 계속 냈다. 그 문구는 **폐기**한다.
> `PRODUCTION_READY` 는 이 계보에서 아직 한 번도 성립한 적이 없다.

---

## 0. 세션 시작 시

```bash
date; date -u
cd /Users/seong/project/silmu-worktrees/r2-source-quality-integration-0906   # ← 본체(~/project/silmu)가 아니다
git status --short --branch
git log --oneline -6
```

기억한 값보다 실측값이 우선이다. 본체 `/Users/seong/project/silmu` 는 다른 브랜치
(`feature/silmu-p2-general-admin-expansion` @ `a1e8e25`)에 있고 **이 작업의 대상이 아니다.**

## 1. 상태 (실측 · 2026-09-07 06:51 KST · READ-ONLY 재측정으로 확인)

```
WORKTREE             /Users/seong/project/silmu-worktrees/r2-source-quality-integration-0906
BRANCH               fix/silmu-r2-legacy-semantic-alignment-0906
CODE_TARGET          ea18c184156c5ea5ffbb034deee49274d71397cb  (2026-09-07 00:44:12 +0900)
PREVIOUS_HEAD        96a1afb1cdc8ac2d1d8e266d111df6ea8017288f  (2026-09-07 00:15:52 +0900)
DIRTY                NO  (git status --porcelain -uall = 0줄)
PUSH                 NO  (upstream 미설정 · branch --contains ea18c18 = 로컬 1개)
DEPLOY               NO  (ea18c18 은 어떤 remote·main 에도 없다)
SEED_EXECUTED        NO  (이번 4파일은 앱코드/뷰 = DEPLOY_ONLY)
PRODUCTION_REVISION  ce62d2ebee5e465bb230cccf9134e2ada9c71d20   ← R1. 운영은 그대로다
ROLLBACK             ce62d2e
STATUS               REVIEW_REQUIRED
INDEPENDENT_REVIEW   NOT_RUN — ea18c18 · 96a1afb 둘 다 외부 검증 0회
                     마지막 = 5a70437 (2026-09-06 23:35) CONDITIONAL_GO · BLOCKING 1 → REVIEW_REQUIRED
                     codex-critic 쿼터 해제 2026-09-07 14:10 KST
```

### 이 계보의 커밋 연혁 (a1e8e25 이후)

```
ea18c18  09-07 00:44  R-A 사유서 생성기 §25①1호 · R-H 유찰 3경로 §26①   ← CODE_TARGET
96a1afb  09-07 00:15  공개 양식 §25 호가 제2호부터 한 칸씩 밀려 있었다
5a70437  09-06 22:48  §25①1호 잔여 12건 (마지막 독립검증 대상)
29664de  09-06 21:21  배포 blocker F1·F2·F3·F5
ada9b48  09-06 20:44  독립검증 blocking 2건 + 오기 1건
132d463  09-06 19:47  계측기 정정
57d1763  09-06 19:46  잔여 §77 전건 문맥 판정
1ccf310  09-06 19:17  엔진과 본문이 반대로 말하던 5건
93c4fd0  09-06 18:37  merge source-quality(183da50)
a1e8e25  09-06 18:31  R2 계약 판단 Moat
```

### ea18c18 이 고친 것 (파일 실측)

```
R-A  app/views/contract_reasons/index.html.erb  :249 :447 :450 :451 :452
     §25①2호 → §25①1호 (5자리). :448 lawText 는 원래부터 제1호 원문이었다.
     이 화면은 결재용 사유서를 «생성» 하고 #download_hwpx 가 law·lawText 를 그대로 싣는다.
R-H  유찰 후 수의계약 = §25① 어느 호도 아니라 영 제26조제1항. 3경로 + 가이드 동시:
     app/controllers/faq_controller.rb:58 · app/views/guides/resources.html.erb:476 ·
     app/services/contract_method_service.rb:296 :323  ← R2 core (R2_CORE_MODIFIED=YES)
음성대조  resources:476 예시(2) 재해 긴급복구 = §25①2호 그대로 보존 (문자열 일괄치환 안 했다)
계측     탐지기 대상4파일 BEFORE 9 → AFTER 0 · scope 밖 28 → 28 (부수 변화 0)
         2026-09-07 06:51 재실행에서 after.json 과 findings 완전 일치
```

## 1-b. ⚠️ 증거 공백 — 독립검증자가 먼저 알아야 한다

```
TESTS       RECORDED_BUT_RAW_ARTIFACT_MISSING
            기록값: targeted R2 238/1448/0F 0E · CPSC·CPEB 11/198/0F ·
                    full 695/4646/0F 0E/14 skips · RuboCop 변경 4파일 0 offense
            원본 출력 파일이 없다. 증거는 log.md + 커밋 메시지의 산문뿐이다.
MUTATIONS   RECORDED_BUT_RAW_ARTIFACT_MISSING
            기록값: 3차 KILLED 18/18 · SURVIVED 0 · NOT_APPLIED 0 · BASELINE/POST GREEN
            harness 는 실재한다: tasks/silmu-p2-r2-final-known-blocker-cleanup-0907/
            artifacts/mutation_run.py (mutant 18개 확인). 출력은 저장되지 않았다.
DETECTOR    OK — before.json · after.json 이 아티팩트로 남아 있고 재실행으로 재현됨.
```

독립검증 전에 이 두 줄을 **재생성**할지, 리뷰어에게 재현을 맡길지 먼저 정한다.

## 1-c. 지금 대상 밖 (건드리지 않는다)

```
R-J   재공고 1인 참가 → §25①5호 오기 6곳 + 치환표 사본 7곳 (db/seeds/*)
      ⚠️ 운영 DB row 로 서빙된다. 파일 수정만으로는 운영이 안 바뀐다
      (find_or_create_by! 는 기존 row 를 갱신하지 않는다 — 29664de F3 학습).
      수리하려면 UPDATE 전용 시드가 필요하다.
      원장 = test/models/article25_ho_semantic_alignment_test.rb FAILED_BID_OUT_OF_SCOPE (17건)
§25① 축 잔존 7건  R-B~R-G · R-I(사람 판정) = ADJUDICATED_OUT_OF_SCOPE 그대로
```

---

> 아래 §2~§7 은 **2026-09-06 세션 ④(R2 구현 라운드)의 기록**이다. 설계 의도와 함정은 여전히 유효하나,
> 그 안의 `R2_STATUS = PRODUCTION_READY`·`HEAD f10ad5c`·테스트/뮤테이션 수치는 **이후 6커밋으로 대체됐다.**
> 현행값은 위 §1 을 쓴다.

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
