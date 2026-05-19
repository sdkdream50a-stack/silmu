# AuditCase verify batch #1 — category=회계 30건 (2026-05-19 새 세션)
#
# stale AuditCase 235건 점진 검증의 첫 batch. category=회계의 미검증 30건 처리.
#
# 처리:
#   1) Group B 7건 — mcp 법제처 OPEN API 대조 결과 발견한 부정확 legal_basis 정정
#   2) 30건 전체 mark_verified! — Group별 method/source 차등 적용
#
# 그룹:
#   - Group A (6건, mcp_law_api): Phase A~E batch #1~#4 baseline 재확인
#       slug: accounting-data-falsification, double-booking-budget, budget-execution-wrong-account,
#             family-allowance-ineligible-payment, holiday-bonus-pre-retirement-payment, performance-bonus-score-manipulation
#   - Group B (7건, mcp_law_api): 본 batch mcp spot check + 정정
#       slug: foreign-travel-private-tourism, travel-expense-double-claim, travel-expense-settlement-no-receipt,
#             vehicle-travel-allowance-distance-fraud, retirement-allowance-service-period-error,
#             welfare-point-cash-conversion, year-end-settlement-duplicate-deduction
#   - Group C (17건, manual): 조문번호 명시 없음 — 법령명만 인용
#       slug: budget-item-wrong-travel + goe-2021 시리즈 16건

corrections = [
  # id 155 — 공무원 국외 출장 사적 관광
  {
    slug: "foreign-travel-private-tourism",
    legal_basis: "공무원 국외출장 등에 관한 예규 제4조(출장 목적), 공무원여비규정 제2조(여비의 종류), 공무원여비규정 제22조(국외 가족여비)·제16조 ①항·별표 4(국외 일비·숙박비·식비), 지방공무원 국외출장 업무처리 지침"
  },
  # id 156 — 동일 날짜 2개 기관 출장비 이중 청구
  {
    slug: "travel-expense-double-claim",
    legal_basis: "공무원여비규정 제4조(여비의 계산 — 일반적 경로·방법), 지방공무원 여비규정 제4조(여비의 계산), 지방공무원법 제53조(겸직 금지), 회계관계직원 등의 책임에 관한 법률 제4조(변상책임)"
  },
  # id 157 — 영수증 없이 개산여비 지급
  {
    slug: "travel-expense-settlement-no-receipt",
    legal_basis: "공무원여비규정 제3조(여비의 지급 구분), 공무원여비규정 제4조(여비의 계산), 공무원여비규정 제5조(여행일수의 계산), 지방공무원 여비규정 동일 조문, 지방재정법 시행령 제68조(지출결의서의 증빙)"
  },
  # id 158 — 자가용 출장 여비 거리 부풀리기
  {
    slug: "vehicle-travel-allowance-distance-fraud",
    legal_basis: "공무원여비규정 제13조(자동차운임의 지급)·별표 2(국내 자동차운임 — 자가용 사용 시 단가), 지방공무원 여비규정 자동차운임 동일 조문"
  },
  # id 171 — 퇴직수당 재직기간 오산정
  {
    slug: "retirement-allowance-service-period-error",
    legal_basis: "공무원연금법 제62조(퇴직수당), 공무원연금법 제25조(재직기간의 계산 — ④항·⑤항 퇴직수당 합산 제외 + 휴직·직위해제·정직·강등 ½ 차감)"
  },
  # id 172 — 복지포인트 현금화
  {
    slug: "welfare-point-cash-conversion",
    legal_basis: "공무원 보수 등의 업무지침(행정안전부), 공무원 후생복지에 관한 규정 제6조(맞춤형 복지제도의 항목 — 기본·자율항목), 같은 규정 제9조(복지점수의 사용한도), 지방공무원 보수업무 등 처리지침"
  },
  # id 173 — 연말정산 부양가족 공제 중복
  {
    slug: "year-end-settlement-duplicate-deduction",
    legal_basis: "소득세법 제50조(기본공제), 소득세법 제53조(생계를 같이 하는 부양가족의 범위와 그 판정시기), 소득세법 시행령 제106조(부양가족등의 인적공제 — 중복 시 우선순위)"
  }
]

corrections.each do |c|
  ac = AuditCase.find_by(slug: c[:slug])
  if ac.nil?
    puts "    [skipped] #{c[:slug]} — 미존재"
    next
  end
  ac.legal_basis = c[:legal_basis]
  if ac.changed?
    ac.save!
    puts "    [corrected] #{c[:slug]}"
  else
    puts "    [unchanged] #{c[:slug]}"
  end
end

# === 30건 mark_verified! 일괄 적용 ===

verified_at = Time.current

group_a_slugs = %w[
  accounting-data-falsification
  double-booking-budget
  budget-execution-wrong-account
  family-allowance-ineligible-payment
  holiday-bonus-pre-retirement-payment
  performance-bonus-score-manipulation
]

group_b_slugs = %w[
  foreign-travel-private-tourism
  travel-expense-double-claim
  travel-expense-settlement-no-receipt
  vehicle-travel-allowance-distance-fraud
  retirement-allowance-service-period-error
  welfare-point-cash-conversion
  year-end-settlement-duplicate-deduction
]

group_c_slugs = %w[
  budget-item-wrong-travel
  goe-2021-fiscal-year-independence-violation
  goe-2021-accounting-disorder-construction
  goe-2021-gift-voucher-management
  goe-2021-credit-card-usage-improper
  goe-2021-credit-card-payment-account
  goe-2021-credit-card-self-inspection
  goe-2021-beneficiary-cost-settlement
  goe-2021-beneficiary-cost-direct-use
  goe-2021-reserve-fund-improper
  goe-2021-bad-debt-write-off-violation
  goe-2021-development-fund-handover
  goe-2021-development-fund-misuse
  goe-2021-development-fund-misclassified
  goe-2021-suspense-cash-management
  goe-2021-suspense-cash-single-approval
  goe-2021-retirement-pension-mismanagement
]

group_a_source = "Phase A~E batch #1~#4 mcp baseline 재확인 (2026-05-19 AuditCase verify batch #1)"
group_b_source = "법제처 OPEN API spot check + 부정확 정정 (lawId 001717·001565·003956·009965·009402·000696, 2026-05-19 batch #1)"
group_c_source = "GOE 2021 경기교육청 감사보고서 (조문번호 명시 없음 — 차후 정밀화 backlog)"

[
  [group_a_slugs, "mcp_law_api", group_a_source],
  [group_b_slugs, "mcp_law_api", group_b_source],
  [group_c_slugs, "manual",      group_c_source]
].each do |slugs, method, source|
  slugs.each do |slug|
    ac = AuditCase.find_by(slug: slug)
    if ac.nil?
      puts "    [skipped] #{slug} — 미존재"
      next
    end
    ac.mark_verified!(method: method, source: source, at: verified_at)
    puts "    [verified] #{slug} (#{method})"
  end
end

verified_count = AuditCase.verified_recently.count
puts ""
puts "[INFO] AuditCase verified_recently 총 #{verified_count}건 (기존 6 + 본 batch 30 = 36 기대)"
