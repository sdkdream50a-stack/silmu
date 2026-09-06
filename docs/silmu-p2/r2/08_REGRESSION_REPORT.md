# 08 — REGRESSION REPORT

> §30·§31·§32·§33. 측정 시각 2026-09-06 KST. 모든 수치는 실행 결과다.

---

## 1. 테스트

```
BEFORE (R1 종료 시점)   497 runs · 3,138 assertions · 0F · 0E · 14 skips
AFTER                   599 runs · 3,474 assertions · 0F · 0E · 14 skips
                        +102 runs · +336 assertions · skip 변화 0
RuboCop                 13 files inspected, no offenses (변경 파일 전건)
```

skip 수가 그대로인 것이 중요하다 — 새 skip 을 만들어 초록을 산 것이 아니다.

## 2. P1.6 동결 (§30)

7개 파일 전건 **HEAD 와 내용 동일**. 해시 대조로 확인했다:

```
IDENTICAL 4939cc7bf14ee313  app/services/search_query_parser.rb
IDENTICAL 40825eabe0daf103  app/models/topic.rb
app/views/shared/_solution_status.html.erb      UNCHANGED
app/views/layouts/_nav_v2.html.erb              UNCHANGED
app/views/home/index.html.erb                   UNCHANGED
test/models/topic_search_test.rb                UNCHANGED
test/services/search_query_parser_test.rb       UNCHANGED
```

**양성대조** — 같은 검사를 실제로 바꾼 파일에 걸면 잡는다:
`app/services/contract_method_service.rb` → `1 file changed, 63 insertions(+), 3 deletions(-)`.
검사가 아무것도 안 하는 상태에서 "전건 UNCHANGED"를 보고하는 함정을 막는다.

정밀도 가드 3종 재실행 결과는 07 §3. 검색 엔진 변경 **0**.

## 3. R1 도구 발견성 (§31)

8질의 전건 `tool_count ≥ 1` 유지:

| 질의 | 도구 |
|---|---|
| 수의계약 한도 · 수의계약한도 · 소액수의 | 계약방식 결정 도우미 |
| 분할발주 · 분리 발주 | 분할계약 판단 체크리스트 |
| 수입인지 | 계약보증금 계산기 |
| 보조금정산 | 보조금 정산 체크리스트 |
| 국외출장 | 여비계산기 |

`tools_registry` 의 `keywords` 는 한 글자도 바꾸지 않았다. 무관 도구가 새로 붙은 것도 없다.

## 4. Authority / Freshness (§32)

```
app/services/authority/**       변경 0
app/models/authority_*.rb       변경 0
app/jobs/authority_*.rb         변경 0
config/recurring.yml            변경 0   ← scheduler OFF 유지
AuthorityDocument 신규 적재      0
```

R2 는 Authority 스택에서 `effective_from`·`source_url` 만 **읽어** 규칙집에 옮겨 적었고,
자동 current 판정을 하지 않는다. 근거 표시는 "시행 2026-06-03 · 확인 2026-09-06"으로
**언제 기준인지**를 명시할 뿐 "현행이다"라고 말하지 않는다.

## 5. 콘텐츠 변이

```
EXPECTED  0
ACTUAL    0
```

Topic · Guide · AuditCase · FAQ 어느 것도 쓰지 않았다. 운영 접속은 전부 read-only
(`rails runner` 로 조회 + 법제처 API 조회). 마이그레이션·시드 실행 0.
SearchLog 행 삭제 0 (§5) — 12:10~12:15 KST 45건은 문서 분석 layer 에서만 제외한다.

## 6. 뮤테이션 (§33)

`_measure/mutation_r2.sh` — 각 뮤턴트를 실제 파일에 적용하고 스위트를 돌린다.
치환이 실패하면 `NOT_APPLIED` 로 세어, **적용 안 된 뮤턴트가 생존처럼 보이는** 함정을 막는다.

| # | 뮤턴트 | 결과 |
|---|---|---|
| 1 | §25 나목 임계 2천만 → 3천만 | KILLED (4F) |
| 2 | 계약유형 게이트 제거 | KILLED (6F) |
| 3 | 기관 범위 무시 | KILLED (2F) |
| 4 | 취약계층 고용비율 단서 무시 | KILLED (2F) |
| 4b | 그 단서를 나목·가목까지 **확대** (없는 조건 요구) | KILLED (1F) |
| 5 | §77③ 회피목적 override 제거 | KILLED (1F) |
| 5b | §77③ 적용범위 **확대** (요건·사유 없이도 인용) | KILLED (1F) |
| 6 | 정보 부족 → 가능으로 승격 | KILLED (6F) |
| 7 | 근거(provenance) 검사 무력화 | KILLED (2F) |
| 8 | 근거에서 시행일 제거 | KILLED (2F) |
| 9 | 물품·용역에 §77 오인용 | KILLED (2F) |

4b·5b 는 §33 목록에 없다. 구현 도중 **호스트 자체 전수 프로브가 실제 결함을 찾아** 추가한 축이다.

**4b** —
`SOCIAL_ENTERPRISE` 와 1천만원 물품 계약을 넣으면 `POSSIBLE_WITH_CONDITIONS` 가 나왔다.
§25①5호**나목**(2천만 이하)은 상대방 자격을 조건 삼지 않는데, 상대방 종류만 보고
바목 단서를 적용하고 있었다. 조문이 요구하지 않는 조건을 요구한 것이다.

**5b** — 공사 트랙 27개 조합을 전수로 찍어 보니 `avoidance_intent=yes` 면 사실관계와 무관하게
전부 `HIGH_SPLIT_RISK` + §77③ 인용이 나왔다. §77③ 은 "제1항 각 호의 공사"에 붙는 조항이라
요건도 사유도 성립하지 않은 조합에서 그것을 근거로 들면 적용범위를 넘는다.
`REVIEW_NEEDED` + `AVOIDANCE_SCOPE` 미해결 요인으로 바꿨다.

둘 다 **테스트를 통과한 채로 존재하던 결함**이다. 전체 스위트도 뮤테이션 14종도 잡지 못했다 —
잡은 것은 조합 전수 프로브였다.

**§33 의 9종은 전부 죽었다. 그러나 `SURVIVED=0` 은 내가 고른 축에서 0 이라는 뜻일 뿐이다.**
R2 가 실제로 수리한 결함을 되돌리는 5종을 추가로 걸었고, **2건이 살아남았다**:

| # | 추가 뮤턴트 | 1차 | 수리 후 |
|---|---|---|---|
| 10 | §30 1인 견적 특례 5천만 → 1억 | **SURVIVED** | KILLED |
| 11 | 소기업·소상공인을 1인 견적 열거에 추가 | **SURVIVED** | KILLED |
| 12 | 청년창업기업 상한 5천만 → 1억 | KILLED | KILLED |
| 13 | 합산 창 12개월 → 3개월 | KILLED | KILLED |
| 14 | 구 `cooperative` 매핑 부활 | KILLED | KILLED |

독립검증(gemini) 지적을 수리한 뒤 그 5건을 되돌리는 뮤턴트를 추가로 걸었다 (11 문서 §5.2):

| # | 뮤턴트 | 결과 |
|---|---|---|
| 15 | 특수분야인데 상대방을 되묻기 | KILLED |
| 16 | 유형 상한 검사 제거 (1억 초과도 되묻기) | KILLED |
| 17 | 고용비율 충족을 반영하지 않기 | KILLED |
| 18 | §77 금지요건 확정 미충족 경로 제거 | KILLED |
| 19 | 분리 사유 근거 출처를 코드에 하드코딩 | KILLED |

재개 세션에서 규칙 provenance·검토축 강화분 6종을 추가로 걸었다:

| # | 뮤턴트 | 결과 |
|---|---|---|
| 20 | 필수 field 검사를 authority/locator 2개로 축소 | KILLED |
| 21 | contract_type 검사 제거 (오타 rule 이 조용히 통과) | KILLED |
| 22 | agency_scope 검사 제거 | KILLED |
| 23 | 물품·용역 검토축에 공사 조문(§77③)을 근거로 부착 | KILLED |
| 24 | 근거 없는 축의 "판정 안 하는 사유" 제거 | KILLED |
| 25 | §7제2호 직후 12개월 미확정 고지 제거 | KILLED |

> **등가 뮤턴트 1건은 억지로 죽이지 않았다.** 처음 24번은 `if ax["basis"] == "NONE"` 을
> `if false` 로 바꾸는 것이었는데, `else` 분기가 같은 값(`REVIEW_REQUIRED`)을 내서
> **동작이 바뀌지 않는 등가 뮤턴트**였다. 억지로 kill 하는 대신 실제 불변식
> ("근거 없는 축은 왜 판정하지 않는지를 함께 낸다")을 겨냥하는 뮤턴트로 교체했다.

10·11 은 **§30 견적요건 축에 테스트가 없어서** 살아남았다 — §25 축만 검증하고 있었다.
`quotation_requirement_test.rb`(9 tests · 20 assertions)를 추가해 죽였다.

```
최종  KILLED=27  SURVIVED=0  NOT_APPLIED=0
```

> 수리 직후 **두 번** `NOT_APPLIED=1` 이 나왔다 — M-4 가 겨냥하던 코드가 수리로 바뀌어
> 치환이 실패한 것이다. 스크립트가 그것을 **생존이 아니라 미적용으로** 셌기 때문에 드러났다.
> 적용되지 않은 뮤턴트를 생존으로 세면 방어가 있는 것처럼 보이고, 통과로 세면 없는 방어가
> 있는 것처럼 보인다. 둘 다 거짓 안심이다. (M-4·M-5b 두 번 다 겨냥하던 코드가 수리로 바뀐 경우였고,
> 뮤턴트를 새 코드에 맞춰 고친 뒤 다시 죽었다.)

## 7. 이번 변경 파일 전량

```
M  app/controllers/contract_methods_controller.rb     파라미터 4개 통과
M  app/controllers/tools_controller.rb                평가 엔드포인트 추가
M  app/services/contract_method_service.rb            판정 위임 + 결론 문구 정합
M  app/views/contract_methods/index.html.erb          기관·상대방 입력 + 판정 패널
M  app/views/tools/split_contract_checker.html.erb    서버 판정 연동 + 조문 정정
M  config/routes.rb                                   POST 1개
M  config/contract_thresholds.yml                     cooperative 항목 삭제 + 주석
A  config/contract_decision_rules.yml                 규칙집 (신규)
A  app/services/contract_decision/{rule_set,private_contract_evaluator,quotation_requirement,split_procurement_evaluator}.rb
A  test/services/contract_decision/*_test.rb          4종
A  test/integration/contract_decision_flow_test.rb
A  docs/silmu-p2/r2/**                                산출물 · 측정 스크립트 · 원자료
```

DB 마이그레이션 0 · 스키마 변경 0 · 신규 route 1 (기존 도구의 POST) · 신규 도구 URL 0.
