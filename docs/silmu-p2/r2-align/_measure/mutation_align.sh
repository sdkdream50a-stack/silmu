#!/usr/bin/env bash
# R2 ↔ 레거시 의미정합 뮤테이션 — 정정을 되돌리면 회귀가 실제로 죽는지 센다.
# 각 뮤턴트는 **적용 여부를 먼저 확인**한다 (0건 치환은 조용히 "생존"처럼 보인다).
set -u
cd "$(dirname "$0")/../../../.." || exit 1
TEST=test/models/contract_split_semantic_alignment_test.rb
KILLED=0; SURVIVED=0; NOTAPPLIED=0; BASELINE_RED=0

# 시작 베이스라인 — 빨간 상태에서 시작하면 모든 뮤턴트가 «죽은 것처럼» 보인다.
if ! bin/rails test "$TEST" >/dev/null 2>&1; then
  echo "BASELINE_RED_AT_START — 뮤테이션을 돌릴 수 없다"; exit 1
fi

mutate() { # name file after before
  local name="$1" file="$2" after="$3" before="$4"
  cp "$file" "/tmp/mut.bak.$$"
  local n; n=$(python3 - "$file" "$after" <<'PY'
import sys; print(open(sys.argv[1],encoding="utf-8").read().count(sys.argv[2]))
PY
)
  if [ "$n" -eq 0 ]; then echo "NOT_APPLIED  $name (대상 문자열 0건 — 뮤턴트가 안 걸렸다)"; NOTAPPLIED=$((NOTAPPLIED+1)); rm -f "/tmp/mut.bak.$$"; return; fi
  python3 - "$file" "$after" "$before" <<'PY'
import sys
p,a,b=sys.argv[1],sys.argv[2],sys.argv[3]
t=open(p,encoding="utf-8").read(); open(p,"w",encoding="utf-8").write(t.replace(a,b))
PY
  if bin/rails test "$TEST" >/dev/null 2>&1; then
    echo "SURVIVED     $name"; SURVIVED=$((SURVIVED+1))
  else
    echo "KILLED       $name  (치환 ${n}건)"; KILLED=$((KILLED+1))
  fi
  # 복원은 «내용»만이 아니라 «mtime»도 되돌려야 한다 — 크기가 같은 뮤턴트면
  # (mtime,size) 로 키를 잡는 컴파일 캐시가 뮤턴트 바이트코드를 계속 물고 있다(2026-09-06 실측).
  mv "/tmp/mut.bak.$$" "$file"; touch "$file"
  if ! bin/rails test "$TEST" >/dev/null 2>&1; then
    echo "BASELINE_RED $name (복원 뒤 스위트가 빨갛다 — 이 뮤턴트 판정은 믿을 수 없다)"
    BASELINE_RED=$((BASELINE_RED+1))
  fi
}

# A — §77 공사 한정 되돌리기
mutate "A1 §77 무한정 매핑 복원" app/services/regulation_verifier.rb \
  '- 공사의 분할계약 금지: 시행령 제77조' '- 분할계약 금지: 시행령 제77조'
mutate "A2 물품·용역 §7제2호 근거 제거" app/services/regulation_verifier.rb \
  '      - 물품·용역의 분할 조달: 시행령 제7조제2호' '      - (삭제됨) 물품·용역'
mutate "A3 §25 소기업 1억 계층 제거" app/services/regulation_verifier.rb \
  '      - 물품/용역 - 소기업·소상공인: 2천만원 초과 1억원 이하 ✅ (같은 호 라목)' '      -'

# B — 물품 절대금지 복원
mutate "B1 금액 무관 절대금지 복원" app/views/guides/contract_flow.html.erb \
  '2,000만원 이하는 수의계약 가능(일반 업체 기준). 동일·유사한 물품을 나눠 사면 시행령 제7조제2호에 따라 직전/직후 12개월 또는 해당 회계연도 총액으로 추정가격을 합산합니다.' \
  '2,000만원 이하는 수의계약 가능. 다만 동일 물품을 나눠서 수의계약하는 분할계약은 금액과 무관하게 금지됩니다.'

# C — 절대금지 헤드라인 복원
mutate "C1 '분할계약 절대 금지' 복원" db/seeds/subtopics.rb \
  '            부당한 분할계약 금지' '            분할계약 절대 금지!'
mutate "C2 '2개 이상 분할하면 지적' 복원" db/seeds/subtopics.rb \
  '수의계약 한도나 경쟁입찰을 회피하려고 단일 사업을 나누면 <strong>감사 1순위 지적 대상</strong>입니다.' \
  '1건의 계약을 2개 이상으로 분할하면 <strong>감사 1순위 지적 대상</strong>입니다.'

# D — §25 특례 5천만 단정 복원 / §30 정본 삭제
mutate "D1 quick_stats §25 5천만 단정 복원" db/seeds/quick_stats.rb \
  '"note" => "청년창업 5,000만원·소기업 등 1억원"' '"note" => "특례기업 5,000만원"'
mutate "D2 sprint3 §25 5천만 단정 복원" db/seeds/quick_stats_sprint3.rb \
  '"note" => "청년창업 5천만원·소기업 등 1억원"' '"note" => "특례기업 5천만원"'
mutate "D3 요약문 1억 계층 제거" db/seeds/topic_fold_summary_2026_06_05_batch2.rb \
  '이며, 청년창업기업은 5천만원·소기업·소상공인·여성·장애인·사회적기업 등은 1억원까지 가능합니다.' '(특례기업 5천만원) 이하입니다.'
mutate "D4 §30 1인견적 특례 삭제(과잉정정)" db/seeds/quick_stats_sprint3.rb \
  '{ "label" => "특례기업",      "value" => "5천만원 이하", "note" => "청년·여성·장애인 등" },' ''
mutate "D5 2026.6.30 만료 주장 복원" app/views/contract_reasons/index.html.erb \
  '(특례: 청년창업기업 5천만원 이하, 소기업·소상공인·여성·장애인·사회적기업 등 1억원 이하 — 시행령 제25조제1항제5호 다목~바목의 상시 제도이며 부칙에 유효기간 조항이 없다.' \
  '(한시적 특례: 청년창업·소기업·여성·장애인·사회적기업 등은 5천만원~1억원 이하 ~2026.6.30 시행, 만료 후 종전 3천만원으로 회귀).'

# E — 소상공인 누락 복원 / 대상없는 특례 1억 복원
mutate "E1 소상공인 누락 복원(subtopics)" db/seeds/subtopics.rb \
  '소기업·소상공인·여성·장애인' '소기업·여성·장애인'
mutate "E2 대상없는 '특례 1억' 복원" db/seeds/subtopics.rb \
  '2천만원 (청년창업 5천만·소기업 등 1억)' '2천만원 (특례 1억)'

# ── 독립검증 blocking 수리 (B1·B2·N1 · 2026-09-06) ─────────────
AC=db/seeds/audit_cases/topic_audit_cases_batch_01.rb
FC=app/views/topics/flowcharts/_private_contract_limit.html.erb

mutate "R1 B1 issue 한도액(5천만원) 복원" "$AC" \
  '(총사업비 1억 5천만원)을 수의계약 한도를 초과한다는 이유로' \
  '(총사업비 1억 5천만원)을 수의계약 한도액(5천만원)을 초과한다는 이유로'
mutate "R2 B1 detail 조문 오귀속+한도 단정 복원" "$AC" \
  '수의계약이 가능한 한도는 「지방계약법 시행령」 제25조제1항제5호에 따라' \
  '「지방계약법 시행령」 제25조의 용역 수의계약 한도액(5천만원)을 3배 초과하는 규모였습니다. 원래는'
mutate "R3 B1 적발경위 한도(5천만원) 복원" "$AC" \
  '- **각 계약금액이 5천만원 직하로 균일**' \
  '- **각 계약금액이 수의계약 한도(5천만원) 직하**'
mutate "R4 B1 lesson 5천만원(용역·물품) 복원" "$AC" \
  '**전체 금액을 기준으로** 수의계약 한도(시행령 제25조제1항제5호 — 계약유형·상대방 요건에 따라 다름) 초과 여부를 판단합니다. 분할한 각 계약이 한도 미만이더라도' \
  '전체 금액이 5천만원(용역·물품)을 초과하면 경쟁입찰 대상입니다. 분할한 각 계약이 5천만원 미만이더라도'
mutate "R5 B1 checkpoints 한도(5천만원) 복원" "$AC" \
  "'총사업비가 수의계약 한도를 초과하는지 사업 전체 기준으로 판단 (한도는 시행령 제25조제1항제5호의 계약유형·상대방 요건에 따라 다름)'," \
  "'총사업비가 수의계약 한도(5천만원)를 초과하는지 사업 전체 기준으로 판단',"
mutate "R6 B2 §25①1호(소액) 복원" "$AC" \
  '제25조 제1항 제5호 (소액 수의계약 — 세부 목은 계약유형·상대방 요건에 따라 확인)' \
  '제25조 제1항 제1호 (소액 수의계약)'
mutate "R7 B2 세부목 임의 지정" "$AC" \
  '제25조 제1항 제5호 (소액 수의계약 — 세부 목은 계약유형·상대방 요건에 따라 확인)' \
  '제25조 제1항 제5호 나목 (소액 수의계약)'
mutate "R8 N1 (제9호 등) 복원" "$FC" \
  '제25조제1항제5호에 따른 상시 제도입니다' '제25조제1항(제9호 등)에 따른 상시 제도입니다'
mutate "R9 B1 을 다른 단일 숫자로 치환" "$AC" \
  '수의계약 한도를 초과하는지 사업 전체 기준으로 판단 (한도는' \
  '수의계약 한도(2천만원)를 초과하는지 사업 전체 기준으로 판단 (한도는'
mutate "R10 사건 사실 5천만원 삭제(과잉정정)" "$AC" \
  '- 5천만원 이상 수의계약 전 교육지원청장 사전 승인 의무화' \
  '- 수의계약 전 교육지원청장 사전 승인 의무화'
mutate "R11 N1 정당 기준 훼손(과잉정정)" "$FC" \
  '일반 물품·용역 수의계약 한도는 2천만원, 청년창업기업은 5천만원' \
  '일반 물품·용역 수의계약 한도는 2천만원'

echo
echo "KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOTAPPLIED BASELINE_RED=$BASELINE_RED"
