#!/usr/bin/env bash
# R2 뮤테이션 — §33 의 9종. 각 뮤턴트를 실제로 적용하고 테스트가 깨지는지 본다.
# "green 이니 안전하다"는 증거가 아니다. 방어를 망가뜨려도 죽지 않는 테스트는 방어가 없는 것이다.
set -uo pipefail
cd "$(dirname "$0")/../../../.." || exit 1
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/postgresql@16/bin:$PATH"

RULES=config/contract_decision_rules.yml
PCE=app/services/contract_decision/private_contract_evaluator.rb
SPE=app/services/contract_decision/split_procurement_evaluator.rb
QR=app/services/contract_decision/quotation_requirement.rb
RS=app/services/contract_decision/rule_set.rb
CMS=app/services/contract_method_service.rb
SUITE="test/services/contract_decision test/integration/contract_decision_flow_test.rb"

BACKUP=$(mktemp -d)
for f in "$RULES" "$PCE" "$SPE" "$QR" "$RS" "$CMS"; do
  mkdir -p "$BACKUP/$(dirname "$f")"; cp "$f" "$BACKUP/$f"
done
restore() { for f in "$RULES" "$PCE" "$SPE" "$QR" "$RS" "$CMS"; do cp "$BACKUP/$f" "$f"; touch "$f"; done; }
trap 'restore; rm -rf "$BACKUP"' EXIT

KILLED=0; SURVIVED=0; NOT_APPLIED=0

# 시작 베이스라인 — 빨간 상태에서 시작하면 모든 뮤턴트가 «죽은 것처럼» 보인다.
restore
if ! bin/rails test $SUITE >/dev/null 2>&1; then
  echo "BASELINE_RED_AT_START — 뮤테이션을 돌릴 수 없다"; exit 1
fi

run_mutant() {
  local name="$1"; shift
  restore
  if ! "$@"; then
    echo "M-$name  NOT_APPLIED  (치환 실패 — 뮤턴트가 적용되지 않았다)"
    NOT_APPLIED=$((NOT_APPLIED+1)); return
  fi
  if bin/rails test $SUITE >/tmp/mut_out.txt 2>&1; then
    echo "M-$name  SURVIVED  ← 방어 없음"
    SURVIVED=$((SURVIVED+1))
  else
    local n; n=$(grep -oE '[0-9]+ failures' /tmp/mut_out.txt | head -1)
    echo "M-$name  KILLED    ($n)"
    KILLED=$((KILLED+1))
  fi
}

# 치환 헬퍼 — 적용되지 않으면 실패로 돌려 "적용 안 된 뮤턴트가 생존처럼 보이는" 함정을 막는다.
sub() { local f="$1" old="$2" new="$3"
  grep -qF -- "$old" "$f" || return 1
  python3 - "$f" "$old" "$new" <<'PY'
import sys
f,old,new=sys.argv[1],sys.argv[2],sys.argv[3]
s=open(f).read()
assert old in s
open(f,'w').write(s.replace(old,new,1))
PY
}

echo "=== R2 MUTATION (9종) ==="

# 1. threshold 하나 변경 — 나목 2천만 → 3천만
run_mutant 1-threshold sub "$RULES" "    max_amount: 20000000
    counterparties: any
    outcome: POSSIBLE
    authority_source: LOCAL_CONTRACT_DECREE
    source_locator: \"제25조제1항제5호나목\"" "    max_amount: 30000000
    counterparties: any
    outcome: POSSIBLE
    authority_source: LOCAL_CONTRACT_DECREE
    source_locator: \"제25조제1항제5호나목\""

# 2. contract type gate 제거 — 계약유형 무시하고 모든 rule 적용
run_mutant 2-type-gate sub "$PCE" \
  'return false unless Array(rule["contract_types"]).include?(@contract_type)' \
  'nil # MUTANT: 계약유형 게이트 제거'

# 3. agency scope 무시 — 범위 밖 기관도 통과
run_mutant 3-agency-scope sub "$PCE" \
  '      return nil if scope["in_scope"]' \
  '      return nil # MUTANT: 기관 범위 무시'

# 4. exception condition 무시 — 취약계층 고용비율 단서 삭제
run_mutant 4-exception sub "$PCE" \
  '      if rule_conditions_on_counterparty?(rule) && rules.vulnerable_ratio_required?(counterparty)' \
  '      if false # MUTANT: 취약계층 고용비율 단서 무시'

# 4b. 단서를 rule 범위 밖으로 넓히기 — 조문에 없는 조건을 요구하게 만든다
run_mutant 4b-condition-overreach sub "$PCE" \
  '      if rule_conditions_on_counterparty?(rule) && rules.vulnerable_ratio_required?(counterparty)' \
  '      if rules.vulnerable_ratio_required?(counterparty) # MUTANT: 단서를 나목·가목까지 확대'

# 5b. §77③ 적용범위 확대 — 요건·사유 없이도 회피목적만으로 §77③ 인용
run_mutant 5b-override-overreach sub "$SPE" \
  '      if @factors["avoidance_intent"] == "yes" && !prohibited_shape && !ground' \
  '      if false # MUTANT: §77③ 적용범위 게이트 제거'

# 5. split-risk 핵심 조건 반전 — §77③ 회피목적 override 제거
run_mutant 5-split-core sub "$SPE" \
  '      if @factors["avoidance_intent"] == "yes"' \
  '      if false # MUTANT: 회피목적 override 제거'

# 6. REVIEW_REQUIRED 를 POSSIBLE 로 — 정보 부족을 가능으로 승격
run_mutant 6-review-to-possible sub "$PCE" \
  '        state: "INSUFFICIENT_INFORMATION",' \
  '        state: "POSSIBLE", # MUTANT: 정보 부족을 가능으로'

# 7. authority source 없는 rule 허용 — provenance 검사 무력화
run_mutant 7-provenance sub "$RS" \
  '        raise MissingProvenanceError, "rule #{id} — 필수 field 누락: #{missing.join('"'"', '"'"')}" if missing.any?' \
  '        # MUTANT: 근거 검사 무력화'

# 8. effective date 무시 — 근거에서 시행일 제거
run_mutant 8-effective-date sub "$RS" \
  '        effective_from: s["effective_from"], verified_at: s["verified_at"], url: s["url"] }' \
  '        effective_from: nil, verified_at: nil, url: s["url"] } # MUTANT: 시행일 제거'

# 9. 물품·용역에 공사 조문(§77)을 근거로 붙이기 — 조문 오인용
run_mutant 9-wrong-article sub "$SPE" \
  '      basis = [ rules.citation(cfg["authority_source"], cfg["source_locator"], quote: cfg["quote"]) ]
      months = cfg["aggregation_window_months"]' \
  '      basis = [ rules.citation("LOCAL_CONTRACT_DECREE", "제77조제1항") ] # MUTANT: 공사 조문 오인용
      months = cfg["aggregation_window_months"]'

echo
echo "[9종 소계] KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOT_APPLIED"

# ── 추가 5종 (2026-09-06) ──
# 위 9종은 프롬프트가 지정한 축이다. SURVIVED=0 은 "내가 고른 축에서 0"이라는 뜻일 뿐이므로,
# 이번 R2 가 실제로 수리한 결함을 되돌리는 뮤턴트를 따로 건다.
echo
echo "=== R2 MUTATION 추가 5종 ==="

# 10. §30 1인 견적 특례 임계 5천만 → 1억 (§25 한도와 §30 견적요건을 다시 뒤섞기)
run_mutant 10-quote-threshold sub "$RULES" \
  '      max_amount: 50000000
      counterparties: [YOUTH_STARTUP, WOMEN, DISABLED]' \
  '      max_amount: 100000000
      counterparties: [YOUTH_STARTUP, WOMEN, DISABLED]'

# 11. 소기업·소상공인을 1인 견적 대상에 추가 (조문에 열거되지 않은 확장)
run_mutant 11-single-quote-scope sub "$RULES" \
  '      counterparties: [YOUTH_STARTUP, WOMEN, DISABLED]' \
  '      counterparties: [YOUTH_STARTUP, WOMEN, DISABLED, SMALL_ENTERPRISE]'

# 12. 청년창업기업 상한 5천만 → 1억 (다목을 라목처럼 취급)
run_mutant 12-youth-ceiling sub "$RULES" \
  '    max_amount: 50000000
    counterparties: [YOUTH_STARTUP]' \
  '    max_amount: 100000000
    counterparties: [YOUTH_STARTUP]'

# 13. 합산 기간 12개월 → 3개월 (운영에 실제로 있던 임의 기간 재도입)
run_mutant 13-window-3months sub "$RULES" \
  '    aggregation_window_months: 12' \
  '    aggregation_window_months: 3'

# 14. 구 cooperative 매핑 부활 (조문에 없는 자격을 특례로 인정)
run_mutant 14-cooperative sub app/services/contract_method_service.rb \
  '      "women" => "WOMEN", "disabled" => "DISABLED", "social" => "SOCIAL_ENTERPRISE",' \
  '      "cooperative" => "SOCIAL_COOPERATIVE",
      "women" => "WOMEN", "disabled" => "DISABLED", "social" => "SOCIAL_ENTERPRISE",'

# ── 독립검증(gemini) 지적 수리분 5종 (2026-09-06) ──
echo
echo "=== R2 MUTATION 독립검증 수리분 5종 ==="

# 15. 마목(특수분야)에서도 상대방을 되묻게 되돌리기 — 결론 나는데 보류
run_mutant 15-special-field-ask sub "$PCE" \
  '      return false if @special_field' \
  '      # MUTANT: 특수분야 무시'

# 16. 유형 상한 검사 제거 — 1억 초과 물품도 상대방을 되묻는다
run_mutant 16-ceiling-ask sub "$PCE" \
  '      return false if price > type_ceiling' \
  '      # MUTANT: 상한 검사 제거'

# 17. 고용비율 충족을 반영하지 않기 — 영원히 조건부
run_mutant 17-ratio-met sub "$PCE" \
  '          conditions.delete(ratio_condition)' \
  '          nil # MUTANT: 충족해도 조건을 지우지 않는다'

# 18. §77 금지요건 확정 미충족인데도 예외 사유를 요구 / §77③ 인용
run_mutant 18-not-prohibited sub "$SPE" \
  '      if shape_definitely_absent' \
  '      if false # MUTANT: 금지요건 미충족 경로 제거'

# 19. 분리 사유 근거 출처를 코드에 하드코딩 (규칙집 우회)
run_mutant 19-hardcoded-source sub "$SPE" \
  'rules.citation(g["authority_source"], g["source_locator"], quote: g["label"])' \
  'rules.citation("LOCAL_CONTRACT_ACT", g["source_locator"], quote: g["label"]) # MUTANT'

# ── §1·§2·§5 강화분 5종 (2026-09-06 재개 세션) ──
echo
echo "=== R2 MUTATION 규칙 provenance·검토축 5종 ==="

# 20. 필수 field 검사를 authority/locator 2개로 되돌리기 (effective_from·outcome 등 통과)
run_mutant 20-required-fields sub "$RS" \
  '        missing = REQUIRED_RULE_FIELDS.reject { |f| rule[f].present? }' \
  '        missing = %w[authority_source source_locator].reject { |f| rule[f].present? } # MUTANT'

# 21. contract_type 검사 제거 — 오타 rule 이 조용히 통과
run_mutant 21-contract-type-gate sub "$RS" \
  '          next if contract_types.key?(t.to_s)' \
  '          next # MUTANT: contract_type 검사 제거'

# 22. agency_scope 검사 제거
run_mutant 22-agency-scope-gate sub "$RS" \
  '          next if agency_scopes.key?(a.to_s)' \
  '          next # MUTANT: agency_scope 검사 제거'

# 23. 물품·용역 검토축에 공사 조문을 근거로 붙이기 (조문 확장)
run_mutant 23-axis-article-bleed sub "$RULES" \
  '        basis: NONE
        review_reason: "물품·용역의 분할 자체를 금지하는 조항을 확인하지 못했다. 제77조는 공사 조항이고, 제7조제2호는 금지가 아니라 추정가격 합산 규칙이다."' \
  '        authority_source: LOCAL_CONTRACT_DECREE
        source_locator: "제77조제3항"'

# 24. 근거 없는 축이 "왜 판정하지 않는지" 없이 나가게 하기
#     (앞선 `if false then "REVIEW_REQUIRED"` 는 else 분기가 같은 값을 내는 **등가 뮤턴트**라 교체했다.
#      등가 뮤턴트를 억지로 죽이지 않는다 — §33.)
run_mutant 24-axis-review-reason sub "$SPE" \
  '          out[:review_reason] = ax["review_reason"]' \
  '          out[:review_reason] = nil # MUTANT: 판정 안 하는 사유 제거'

# ── 독립검증(kimi) 수리분 ──
run_mutant 25-future-window sub "$SPE" \
  '          factor: "FUTURE_WINDOW",' \
  '          factor: "IGNORED", # MUTANT: 직후 12개월 미확정 고지 제거'

echo
echo "TOTAL KILLED=$KILLED SURVIVED=$SURVIVED NOT_APPLIED=$NOT_APPLIED"
