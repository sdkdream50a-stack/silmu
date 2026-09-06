#!/usr/bin/env bash
# 배포 blocker 정정(F1·F2·F3·F5) 뮤테이션 — 정정과 «UPDATE 경로»를 되돌리면 회귀가 실제로 죽는지 센다.
# 각 뮤턴트는 **적용 여부를 먼저 확인**한다 (0건 치환은 조용히 "생존"처럼 보인다).
set -u
cd "$(dirname "$0")/../../../.." || exit 1
TESTS="test/models/contract_split_semantic_alignment_test.rb test/models/deploy_blocker_fix_seed_test.rb"
KILLED=0; SURVIVED=0; NOTAPPLIED=0; BASELINE_RED=0

# 시작 베이스라인 — 빨간 상태에서 시작하면 모든 뮤턴트가 «죽은 것처럼» 보인다.
if ! bin/rails test $TESTS >/dev/null 2>&1; then
  echo "BASELINE_RED_AT_START — 뮤테이션을 돌릴 수 없다"; exit 1
fi

mutate() { # name file after before
  local name="$1" file="$2" after="$3" before="$4"
  local bak="/tmp/mutdb.bak.$$"
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

AC=db/seeds/audit_cases/topic_audit_cases_batch_01.rb
SUB=db/seeds/subtopics.rb
FC=app/views/topics/flowcharts/_private_contract_limit.html.erb
SEED=db/seeds/topic_deploy_blocker_fix_2026_09_06.rb

# M1 — F1 오기 다시 허용 (원천)
mutate "M1 F1 §25①1호(소액) 복원(원천)" "$AC" \
  'ac.legal_basis = '"'"'지방계약법 시행령 제25조 제1항 제5호 (소액 수의계약 — 세부 목은 계약유형·상대방 요건에 따라 확인), 행정안전부 예규 제2023-24호 제5장 제3절' \
  'ac.legal_basis = '"'"'지방계약법 시행령 제25조 제1항 제1호 (소액 수의계약), 행정안전부 예규 제2023-24호 제5장 제3절'

# M2 — verification_source 동기화 제거
mutate "M2 verification_source 동기화 제거" "$SEED" \
  'if rec.has_attribute?("verification_source") && derived_verification_source?(rec.verification_source)' \
  'if false'

# M3 — UPDATE 경로를 create 로 바꾼다 (F3 의 핵심축)
mutate "M3 find_by → find_or_create_by!(AuditCase)" "$SEED" \
  'rec = AuditCase.find_by(slug: slug)          # ← create 하지 않는다' \
  'rec = AuditCase.find_or_create_by!(slug: slug) { |r| r.title = "auto" }'

# M4 — B1 mapping 제거
mutate "M4 B1 mapping(checkpoints) 제거" "$SEED" \
  '[ "총사업비가 수의계약 한도(5천만원)를 초과하는지 사업 전체 기준으로 판단",' \
  '[ "__M4_DISABLED__",'

# M5 — B2 mapping 제거
mutate "M5 B2 mapping 제거" "$SEED" \
  '[ "지방계약법 시행령 제25조 제1항 제1호 (소액 수의계약), 지방계약법 시행령 제77조",' \
  '[ "__M5_DISABLED__",'

# M6 — N1 정정 복원 (뷰. DB row 없음 → 원천 회귀가 잡아야 한다)
mutate "M6 N1 (제9호 등) 복원" "$FC" \
  '제25조제1항제5호에 따른 상시 제도입니다' '제25조제1항(제9호 등)에 따른 상시 제도입니다'

# M7 — F5 를 다시 제1호로
mutate "M7 F5 §25①1호(수의계약 한도) 복원" "$SUB" \
  '<strong>지방계약법 시행령 제25조 제1항 제5호 (수의계약 한도)</strong>' \
  '<strong>지방계약법 시행령 제25조 제1항 제1호 (수의계약 한도)</strong>'

# M8 — 정당한 §25①1호 긴급계약까지 잘못 «정정» (과잉정정)
mutate "M8 긴급계약 §25①1호를 소액수의로 오정정" db/seeds/topics.rb \
  '| **긴급 수의** | 시행령 제25조 제1항 제1호 | 천재지변, 긴급 행사 등 경쟁 여유 없음 |' \
  '| **긴급 수의** | 시행령 제25조 제1항 제1호 (소액 수의계약) | 경쟁 여유 없음 |'

echo
echo "KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOTAPPLIED BASELINE_RED=$BASELINE_RED"
