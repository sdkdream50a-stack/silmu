#!/usr/bin/env bash
# §25①1호 의미 오용 «잔여 정리» 뮤테이션 (2026-09-06).
# 앞 라운드 탐지기는 괄호 표기를 요구해 같은 오용 7건을 놓쳤다. 이번 탐지기가
# 그 7건을 실제로 잡는지, 그리고 과잉정정을 막는지 되돌려서 센다.
# 각 뮤턴트는 **적용 여부를 먼저 확인**한다 (0건 치환은 조용히 "생존"처럼 보인다).
set -u
cd "$(dirname "$0")/../../../.." || exit 1
TESTS="test/models/article25_semantic_residual_test.rb test/models/deploy_blocker_fix_seed_test.rb test/services/blog_legal_verifier_test.rb"
KILLED=0; SURVIVED=0; NOTAPPLIED=0; BASELINE_RED=0

# 시작 베이스라인 — 빨간 상태에서 시작하면 모든 뮤턴트가 «죽은 것처럼» 보인다.
if ! bin/rails test $TESTS >/dev/null 2>&1; then
  echo "BASELINE_RED_AT_START — 뮤테이션을 돌릴 수 없다"; exit 1
fi

mutate() { # name file after before
  local name="$1" file="$2" after="$3" before="$4"
  local bak="/tmp/mut25r.bak.$$"
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
  # 복원은 «내용»만이 아니라 «mtime»도 되돌려야 한다.
  # cp/mv 는 백업의 mtime 을 그대로 되돌려 놓는데, 크기가 같은 뮤턴트(제5호↔제1호)면
  # (mtime,size) 로 키를 잡는 컴파일 캐시가 **뮤턴트 바이트코드를 계속 물고 있다**.
  # 그러면 그 뒤 뮤턴트는 전부 «이미 빨간» 베이스라인 위에서 KILLED 로 보인다(2026-09-06 실측).
  mv "$bak" "$file"; touch "$file"
  if ! bin/rails test $TESTS >/dev/null 2>&1; then
    echo "BASELINE_RED $name (복원 뒤 스위트가 빨갛다 — 이 뮤턴트 판정은 믿을 수 없다)"
    BASELINE_RED=$((BASELINE_RED+1))
  fi
}

DET=test/models/article25_semantic_residual_test.rb
FC=app/views/topics/flowcharts/_private_contract_limit.html.erb
SHOW=app/views/topics/show.html.erb
AC=db/seeds/audit_cases/contract_topic_audit_cases.rb
VER=app/services/blog_legal_verifier.rb
SEED=db/seeds/topic_deploy_blocker_fix_2026_09_06.rb

# M1 — 탐지기를 다시 «괄호 의존» 으로 되돌린다. 이번 7건은 괄호가 없다.
mutate "M1 semantic detector → exact 괄호 의존" "$DET" \
  'CLAIM = /소액\s*수의|수의계약\s*한도|한도액|기준금액|한도\s*이하|추정가격[^\n]{0,24}이하|수의계약\s*기준/' \
  'CLAIM = /\(\s*소액\s*수의계약|\(\s*수의계약\s*한도/'

# M2 — view :63 오기 재도입
mutate "M2 view :63 §25①1호 재도입" "$FC" \
  '✓ 추정가격이 한도 이하여야 수의계약 가능 (시행령 제25조 제1항 제5호 — 세부 목은 계약유형·상대방 요건에 따라 확인)' \
  '✓ 추정가격이 한도 이하여야 수의계약 가능 (시행령 제25조 제1항 제1호)'

# M3 — view :287 오기 재도입
mutate "M3 view :287 §25①1호 재도입" "$FC" \
  'desc: "시행령 제25조 제1항 제5호 (세부 목은 계약유형·상대방 요건에 따라 확인)",' \
  'desc: "시행령 제25조 제1항 제1호",'

# M3b — 같은 파일 :162·:220 (앞 라운드가 «4줄 위»를 놓쳤던 자리와 같은 모양)
mutate "M3b view :162/:220 §25①1호 재도입" "$FC" \
  '시행령 제25조 제1항 제5호 명시' '시행령 제25조 제1항 제1호 명시'

# M4 — topics/show 오기 재도입
mutate "M4 topics/show :1207 §25①1호 재도입" "$SHOW" \
  '지방계약법 시행령 제25조 제1항 제5호 나목에 따라 추정가격이 물품구매 수의계약 기준금액(2천만원) 이하' \
  '지방계약법 시행령 제25조 제1항 제1호에 따라 추정가격이 물품구매 수의계약 기준금액(2천만원) 이하'

# M5 — 감사사례 원천 오기 재도입 + 정정 시드의 치환쌍도 함께 되돌린다(운영 전파 축)
mutate "M5 contract_topic_audit_cases:22 오기 재도입(원천)" "$AC" \
  '지방계약법 시행령 제25조 제1항 제5호 나목의 물품 수의계약 기준(2,000만원 초과 시 경쟁 원칙)' \
  '지방계약법 시행령 제25조 제1항 제1호의 물품 수의계약 기준(2,000만원 초과 시 경쟁 원칙)'

# M5b — 원천만 고치고 «운영 row 갱신»(G1 치환쌍)을 빼면 죽어야 한다 (F3 과 같은 축)
mutate "M5b G1 치환쌍 제거(운영 미전파)" "$SEED" \
  '      [ "지방계약법 시행령 제25조 제1항 제1호의 물품 수의계약 기준(2,000만원 초과 시 경쟁 원칙)",' \
  '      [ "__M5b_DISABLED__",'

# M6·M7·M8 — 검증기 3건. «정답» 을 다시 긴급 조항에 매단다.
mutate "M6 verifier 물품·용역(:40) 제1호 재도입" "$VER" \
  '제25조 제1항 제5호 나목"' '제25조 제1항 제1호"'
mutate "M7 verifier 전문공사(:48)·종합공사(:56) 제1호 재도입" "$VER" \
  '제25조 제1항 제5호 가목"' '제25조 제1항 제1호"'
# M8 — 조문만 옮기고 컨텍스트 게이트 문자열을 두고 온다 (게이트가 조용히 죽는다)
mutate "M8 verifier 컨텍스트 게이트 조문 미이관" "$VER" \
  'if rule[:source].to_s.include?("제25조 제1항 제5호")' \
  'if rule[:source].to_s.include?("제25조 제1항 제1호")'

# M9 — 과잉정정: 정당한 §25①1호 긴급계약까지 제5호로 바꾼다
mutate "M9 정당한 긴급 §25①1호를 제5호로 오정정" db/seeds/topics.rb \
  '| **긴급 수의** | 시행령 제25조 제1항 제1호 | 천재지변, 긴급 행사 등 경쟁 여유 없음 |' \
  '| **긴급 수의** | 시행령 제25조 제1항 제5호 | 천재지변, 긴급 행사 등 경쟁 여유 없음 |'

echo
echo "KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOTAPPLIED BASELINE_RED=$BASELINE_RED"
