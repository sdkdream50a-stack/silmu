#!/usr/bin/env bash
# 공개 §25 표기 수리 뮤테이션 (2026-09-06 2차).
#
# 재는 것 세 가지:
#   ① 공개 양식의 «호 밀림» 과 비정본 금액을 되돌리면 실제로 죽는가
#   ② 탐지기의 각 축(맨몸 호 앵커 · 신호 구별성 · 창 경계 · 검사 범위)을 하나씩 무력화하면 죽는가
#   ③ 운영 반영 경로(정정 시드 UPDATE)를 끊으면 죽는가
#
# 각 뮤턴트는 **적용 여부를 먼저 확인**한다 — 0건 치환은 조용히 «생존» 처럼 보인다.
# 복원은 내용과 **mtime** 을 함께 되돌린다. 크기가 같은 뮤턴트(제4호↔제1호)면
# (mtime,size) 키 컴파일 캐시가 뮤턴트 바이트코드를 계속 물어 이후 전 뮤턴트가 거짓 KILLED 가 된다.
set -u
cd "$(dirname "$0")/../../../.." || exit 1
TESTS="test/models/article25_ho_semantic_alignment_test.rb test/models/deploy_blocker_fix_seed_test.rb test/models/article25_semantic_residual_test.rb"
KILLED=0; SURVIVED=0; NOTAPPLIED=0; BASELINE_RED=0

if ! bin/rails test $TESTS >/dev/null 2>&1; then
  echo "BASELINE_RED_AT_START — 뮤테이션을 돌릴 수 없다"; exit 1
fi

mutate() { # name file after before
  local name="$1" file="$2" after="$3" before="$4"
  local bak="/tmp/mutform.bak.$$"
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
  mv "$bak" "$file"; touch "$file"
  if ! bin/rails test $TESTS >/dev/null 2>&1; then
    echo "BASELINE_RED $name (복원 뒤 스위트가 빨갛다 — 이 판정은 믿을 수 없다)"
    BASELINE_RED=$((BASELINE_RED+1))
  fi
}

FORM=public/forms/수의계약사유서.html
DET=test/models/article25_ho_semantic_alignment_test.rb
SUB=db/seeds/subtopics.rb
RES=app/views/guides/resources.html.erb
SEED=db/seeds/topic_deploy_blocker_fix_2026_09_06.rb

# ── ① 공개 양식 ───────────────────────────────────────────────
mutate "M1 폼 체크박스 제3호 → 제2호 (밀림 재도입)" "$FORM" \
  '제3호: 국가기관, 다른 지방자치단체와 계약하는 경우' \
  '제2호: 국가기관, 다른 지방자치단체와 계약하는 경우'

mutate "M2 폼 체크박스 제4호 → 제3호 (밀림 재도입)" "$FORM" \
  '제4호: 특정인의 기술/용역 또는 특정 위치/구조 등으로 경쟁 불가' \
  '제3호: 특정인의 기술/용역 또는 특정 위치/구조 등으로 경쟁 불가'

mutate "M3 폼 체크박스 제5호 → 제4호 (밀림 재도입)" "$FORM" \
  '제5호: 추정가격이 수의계약 기준금액 이하인 경우' \
  '제4호: 추정가격이 수의계약 기준금액 이하인 경우'

mutate "M4 폼 예시문 제5호 나목 → 제4호 · 2,200만원 재도입" "$FORM" \
  '지방계약법 시행령 제25조 제1항 제5호 나목에 따른 물품의 제조·구매계약 수의계약 기준금액(2천만원) 이하' \
  '지방계약법 시행령 제25조 제1항 제4호에 따른 물품구매 수의계약 기준금액(2,200만원) 이하'

mutate "M5 Word 내보내기만 옛 호로 되돌린다 (화면↔내보내기 어긋남)" "$FORM" \
  "legalBasis.push('제3호: 국가기관, 다른 지방자치단체와 계약');" \
  "legalBasis.push('제2호: 국가기관, 다른 지방자치단체와 계약');"

mutate "M5b Word 내보내기 금액 호만 되돌린다" "$FORM" \
  "legalBasis.push('제5호: 추정가격이 기준금액 이하');" \
  "legalBasis.push('제4호: 추정가격이 기준금액 이하');"

# ── ② 탐지기 축 ──────────────────────────────────────────────
mutate "M6 맨몸 호 앵커 제거 (조·항 인접 표기만 본다)" "$DET" \
    '    (direct + anchored_cites(src, direct)).sort_by { |c| c[:b] }' \
    '    direct'

mutate "M7 앵커 지배 범위를 0 으로 (머리말이 아무 호도 못 거느린다)" "$DET" \
  '  ANCHOR_SPAN = 800' \
  '  ANCHOR_SPAN = 0'

mutate "M8 신호 구별성 파괴 — 1호에 1·2호 공유 표현을 되돌린다" "$DET" \
  '    1 => /천재지변|천재·지변|감염병|전염병|긴급한?\s*행사|원자재[^\n]{0,6}가격\s*급등|작전상/,' \
  '    1 => /천재지변|천재·지변|감염병|전염병|긴급한?\s*행사|원자재[^\n]{0,6}가격\s*급등|여유가?\s*없|작전상/,'

mutate "M9 자기근거 창의 항목 경계 제거 (앞 항목 설명을 자기 것으로 훔친다)" "$DET" \
  '  ITEM_BOUNDARY = /\n|\\n/' \
  '  ITEM_BOUNDARY = /\A(?!)/'

mutate "M10 검사 범위에서 public/ 제거 (공개 양식을 다시 안 본다)" "$DET" \
  '      Dir[Rails.root.join("public/**/*.{html,md}")] +' \
  ''

mutate "M11 충돌 신호 창을 0 으로 (아무것도 mismatch 로 안 센다)" "$DET" \
  '  W_OTHER = 90  # 충돌 신호는 «바로 옆» 일 때만 센다' \
  '  W_OTHER = 0   # 충돌 신호는 «바로 옆» 일 때만 센다'

mutate "M12 판정 원장을 파일 단위로 되돌린다 (한 결함이 같은 파일 새 결함을 숨긴다)" "$DET" \
  '      mismatches(File.read(f)).map { |x| "#{rel(f)}:#{x[:line]}" }' \
  '      mismatches(File.read(f)).map { |_x| rel(f) }'

# ── ③ 본문·운영 반영 경로 ────────────────────────────────────
mutate "M13 subtopics 긴급수의 제1호 → 제4호 재도입" "$SUB" \
  '긴급수의계약의 구체적 사유는 <strong>시행령 제25조 제1항 제1호</strong>에서 규정합니다' \
  '긴급수의계약의 구체적 사유는 <strong>시행령 제25조 제1항 제4호</strong>에서 규정합니다'

mutate "M14 resources 특허 제4호 → 제1호 재도입" "$RES" \
  '특허권·저작권 등에 의하여 ○○만이 제조·공급할 수 있어 지방계약법 시행령 제25조제1항제4호' \
  '특허권·저작권 등에 의하여 ○○만이 제조·공급할 수 있어 지방계약법 시행령 제25조제1항제1호'

mutate "M15 resources 긴급 제2호 → 제4호 재도입" "$RES" \
  '경쟁입찰에 부칠 여유가 없으므로 지방계약법 시행령 제25조제1항제2호' \
  '경쟁입찰에 부칠 여유가 없으므로 지방계약법 시행령 제25조제1항제4호'

mutate "M16 정정 시드에서 긴급수의 항목 제거 (파일만 고치고 운영 row 는 안 바꾼다)" "$SEED" \
  '    "emergency-contract" => {
      law_content: [
        [ "긴급수의계약의 구체적 사유는 <strong>시행령 제25조 제1항 제4호</strong>에서 규정합니다",
          "긴급수의계약의 구체적 사유는 <strong>시행령 제25조 제1항 제1호</strong>에서 규정합니다" ]
      ]
    }' \
  '    "emergency-contract" => { law_content: [] }'

mutate "M17 정정 시드가 없는 row 를 create 로 만들게 한다" "$SEED" \
  '      rec = Topic.find_by(slug: slug)              # ← create 하지 않는다' \
  '      rec = Topic.find_or_create_by!(slug: slug) { |t| t.name = slug }'

echo "----"
echo "KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOTAPPLIED BASELINE_RED=$BASELINE_RED"
