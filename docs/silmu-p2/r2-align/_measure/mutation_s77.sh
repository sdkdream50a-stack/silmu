#!/usr/bin/env bash
# §77 적용범위 뮤테이션 — 판정 규칙과 정정을 되돌리면 회귀가 실제로 죽는지 센다.
# 각 뮤턴트는 **적용 여부를 먼저 확인**한다 (0건 치환은 조용히 "생존"처럼 보인다).
set -u
cd "$(dirname "$0")/../../../.." || exit 1
TESTS="test/models/contract_s77_scope_test.rb test/models/contract_split_semantic_alignment_test.rb"
KILLED=0; SURVIVED=0; NOTAPPLIED=0

mutate() { # name file after before
  local name="$1" file="$2" after="$3" before="$4"
  local bak="/tmp/mut77.bak.$$"
  cp "$file" "$bak"
  local n; n=$(python3 - "$file" "$after" <<'PY'
import sys; print(open(sys.argv[1],encoding="utf-8").read().count(sys.argv[2]))
PY
)
  if [ "$n" -eq 0 ]; then
    echo "NOT_APPLIED  $name (대상 문자열 0건 — 뮤턴트가 안 걸렸다)"; NOTAPPLIED=$((NOTAPPLIED+1)); rm -f "$bak"; return
  fi
  python3 - "$file" "$after" "$before" <<'PY'
import sys
p,a,b=sys.argv[1],sys.argv[2],sys.argv[3]
t=open(p,encoding="utf-8").read(); open(p,"w",encoding="utf-8").write(t.replace(a,b))
PY
  if bin/rails test $TESTS >/dev/null 2>&1; then
    echo "SURVIVED     $name"; SURVIVED=$((SURVIVED+1))
  else
    echo "KILLED       $name  (치환 ${n}건)"; KILLED=$((KILLED+1))
  fi
  mv "$bak" "$file"
}

T=test/models/contract_s77_scope_test.rb
A=test/models/contract_split_semantic_alignment_test.rb

# ── 판정 규칙 자체를 망가뜨린다 ──────────────────────────────
# M1 공사 문맥도 오류로 잡게 (공사 표지를 범위 표지에서 제거)
mutate "M1 공사 표지를 범위 인정에서 제거" "$T" \
  'st.match?(CONSTRUCTION) || st.match?(SCOPE_LIMIT) || st.match?(TWO_TRACK)' \
  'st.match?(SCOPE_LIMIT) || st.match?(TWO_TRACK)'
# M2 무엇이든 통과시킨다 (물품 문맥의 §77 일반화가 그대로 지나간다)
mutate "M2 범위 검사를 무조건 통과로" "$T" \
  'st.match?(CONSTRUCTION) || st.match?(SCOPE_LIMIT) || st.match?(TWO_TRACK)' 'true'
# M5 판정 불가(CONTEXT_AMBIGUOUS)를 조용히 정상 처리 — 예외 목록을 넓힌다.
# (테스트의 개수 단언만 무력화하는 뮤턴트는 «다른 단언»이 잡아서 생존처럼 보였다.
#  진짜 위험은 예외 목록 자체가 넓어지는 것이다 — 그쪽을 찌른다)
mutate "M5 예외 목록에 넓은 앵커 추가" "$T" \
  '"db/seeds/audit_cases/contract_method_violations.rb" => [' \
  '"db/seeds/topic_estimated_amount.rb" => [ "§77" ],
    "db/seeds/audit_cases/contract_method_violations.rb" => ['

# TWO_TRACK 완화 — 기재부·조달청 예규를 두 트랙으로 오인
mutate "M8 TWO_TRACK 을 맨 '예규'로 완화" "$T" \
  '집행기준\s*제?1?장|행안부\s*예규|행정안전부\s*예규' '예규'

# ── 정정을 되돌린다 ────────────────────────────────────────
# M3 용역 사례의 §77 일반화 복원
mutate "M3 용역 사례 §77 근거 복원" db/seeds/topic_split_contract.rb \
  '**관련근거:** 시행령 제25조, 제7조제2호(용역 추정가격 합산), 행안부 예규 집행기준 제1장 제1절 5.라' \
  '**관련근거:** 시행령 제25조, 제77조'
# M4 "절대 금지" 표현 복원 (근거보다 강한 표현)
mutate "M4 '분할계약 절대 금지' 복원" db/seeds/subtopics.rb \
  '            부당한 분할계약 금지' '            분할계약 절대 금지!'
# M6 예규 예외(도서 등)·집행기준 근거 제거
mutate "M6 예규 근거 제거(추정가격 토픽)" db/seeds/topic_estimated_amount.rb \
  '와 행정안전부 예규(집행기준 제1장 제1절 5.라)입니다.' '입니다.'
# M7 §77 공사 한정 제거
mutate "M7 §77 표제에서 공사 제거" db/seeds/topic_split_contract.rb \
  '시행령 제77조 (공사의 분할계약 금지)' '시행령 제77조 (추정가격 산정)'
# 창작 인용문 복원
mutate "M9 조문 원문에 없는 인용문 복원" db/seeds/audit_cases/topic_audit_cases_batch_01.rb \
  '지방자치단체의 장 또는 계약담당자는 행정안전부장관이 정하는 동일 구조물공사' \
  '각 중앙관서의 장 또는 계약담당공무원은 수의계약의 한도금액을 초과하기 위하여'
# 도구 신뢰근거 되돌리기
mutate "M10 tool_trust 를 §77 단독으로 복원" config/tool_trust.yml \
  '지방계약법 시행령 제77조(공사)·제7조제2호(물품·용역 추정가격 합산)·행정안전부 예규 집행기준 제1장 제1절 5.라' \
  '지방계약법 시행령 제77조'
# D/E 회귀 유지 확인 (§12)
mutate "M11 §25 특례 5천만 단정 복원" db/seeds/quick_stats.rb \
  '"note" => "청년창업 5,000만원·소기업 등 1억원"' '"note" => "특례기업 5,000만원"'
mutate "M12 소상공인 누락 복원" db/seeds/subtopics.rb \
  '소기업·소상공인·여성·장애인' '소기업·여성·장애인'
mutate "M13 부존재 2026.6.30 만료 주장 복원" app/views/contract_reasons/index.html.erb \
  '시행령 제25조제1항제5호 다목~바목의 상시 제도이며 부칙에 유효기간 조항이 없다.' \
  '~2026.6.30 시행, 만료 후 종전 3천만원으로 회귀).'
# M14 «한시적 특례»라는 말만 지우고 같은 거짓 주장을 남긴다 (M13 이 처음에 생존한 경로)
mutate "M14 '한시적 특례' 표현만 제거하고 회귀 주장 유지" app/views/contract_reasons/index.html.erb \
  '(특례: 청년창업기업 5천만원 이하' \
  '(만료 후 종전 3천만원으로 회귀. 청년창업기업 5천만원 이하'

echo
echo "KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOTAPPLIED"
