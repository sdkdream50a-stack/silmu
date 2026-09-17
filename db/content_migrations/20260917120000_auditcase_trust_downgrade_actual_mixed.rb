# 감사사례 신뢰 강등 — «실제 감사결과» 라벨 68건 → 실무.kr 재구성 사례 (2026-09-17 전수감사 F-05·F-19·F-20)
#
# 운영 읽기 전용 실측(2026-09-17): ACTUAL_AUDIT 86건 중
#   · 본문 말미가 «가상 시나리오»라고 스스로 밝힌 52건(원문 발췌 + 재구성 혼합)
#   · 경기도교육청 2021 사례집 기반 62건 — 원문은 연도 «20××» 익명인데 «2024년 ○월 적발»로 시점 창작,
#     원문 대조 50건 중 27건이 원문 «주의·경고»에 견책·고발을 덧붙임
#   · 본문에 2022년 이후 사건 시점을 적은 54건 · 원문 처분에 없는 «견책/고발» 서술
# 합집합 68건. 남는 18건(서울시교육청 2024·2025 공개 PDF)은 처분이 원문 형식(주의·경고·기관주의)이라 유지한다.
#
# 원칙: 확인되지 않은 사례는 강등하고, 공개 원문을 다시 확인한 뒤에만 ACTUAL_AUDIT 로 올린다.
# 원문 URL·기관·연도 필드는 참고 출처로 남긴다(라벨만 바꾼다). 본문 정정은 별도 migration.
# 분류기(AuditCaseProvenanceClassifier)는 TRUST_DOWNGRADE 표식이 있으면 재승격하지 않는다.

marker = AuditCaseProvenanceClassifier::TRUST_DOWNGRADE_MARKER
note = "#{marker}: 원문 발췌와 재구성(사건 시점·처분·교훈)이 섞여 있어 «실제 감사결과»에서 강등. 원문 재대조 후에만 재승격."

slugs = [
  "goe-2021-accounting-disorder-construction",
  "goe-2021-annual-leave-compensation-mispayment",
  "goe-2021-bad-debt-write-off-violation",
  "goe-2021-beneficiary-cost-direct-use",
  "goe-2021-beneficiary-cost-settlement",
  "goe-2021-bid-announcement-period",
  "goe-2021-budget-account-mixed-execution",
  "goe-2021-budget-formation-violation",
  "goe-2021-budget-transfer-violation",
  "goe-2021-building-registration-delay",
  "goe-2021-business-promotion-improper",
  "goe-2021-clothing-expense-improper",
  "goe-2021-condolence-money-improper",
  "goe-2021-contract-method-2stage-bidding",
  "goe-2021-contract-review-omission",
  "goe-2021-credit-card-payment-account",
  "goe-2021-credit-card-self-inspection",
  "goe-2021-credit-card-usage-improper",
  "goe-2021-daily-audit-89-cases",
  "goe-2021-deemed-budget-violation",
  "goe-2021-development-fund-handover",
  "goe-2021-development-fund-misclassified",
  "goe-2021-development-fund-misuse",
  "goe-2021-disposal-procedure-violation",
  "goe-2021-explicit-carryover-violation",
  "goe-2021-failed-bid-private-contract",
  "goe-2021-family-allowance-misdeclaration",
  "goe-2021-fiscal-year-independence-violation",
  "goe-2021-football-team-extension-contract",
  "goe-2021-foreign-teacher-housing-deposit",
  "goe-2021-gift-voucher-management",
  "goe-2021-improper-payee-cleaning-service",
  "goe-2021-improper-payee-personal-card",
  "goe-2021-instructor-allowance-improper",
  "goe-2021-management-allowance-mispayment",
  "goe-2021-misc-allowance-improper",
  "goe-2021-overtime-allowance-mispayment",
  "goe-2021-payment-processing-improper",
  "goe-2021-performance-bonus-mispayment",
  "goe-2021-private-contract-2bid-violation",
  "goe-2021-private-contract-s2b-mismatch",
  "goe-2021-public-property-occupation-violation",
  "goe-2021-reserve-fund-improper",
  "goe-2021-retirement-pension-mismanagement",
  "goe-2021-school-facility-temp-use-permit",
  "goe-2021-special-duty-allowance-mispayment",
  "goe-2021-specialized-construction-license",
  "goe-2021-split-after-school-program",
  "goe-2021-split-care-trip-copier-paint",
  "goe-2021-split-private-contracts",
  "goe-2021-supplies-joint-purchase",
  "goe-2021-supplies-management-neglect",
  "goe-2021-supplies-selection-committee",
  "goe-2021-suspense-cash-embezzlement",
  "goe-2021-suspense-cash-management",
  "goe-2021-suspense-cash-single-approval",
  "goe-2021-suspension-pay-deduction",
  "goe-2021-temporary-building-violation",
  "goe-2021-tenure-allowance-mispayment",
  "goe-2021-travel-expense-improper",
  "goe-2021-vehicle-management-failure",
  "goe-2021-vending-machine-fee-miscalculation",
  "sen-2024-school-s-academic-eval-violation",
  "sen-2024-school-s-school-record-correction",
  "sen-2024-school-s-temp-building-unauthorized",
  "sen-2025-school-d-sick-leave-certificate",
  "sen-2025-school-i-temp-teacher-screening",
  "sen-2025-school-v-budget-pre-execution"
]

changed = 0
missing = []
slugs.each do |slug|
  ac = AuditCase.find_by(slug: slug)
  next missing << slug unless ac
  next unless ac.source_type == "ACTUAL_AUDIT"   # 멱등 — 이미 강등됐거나 다른 경로로 바뀌었으면 건드리지 않는다

  ac.update_columns(
    source_type: "SILMU_RECONSTRUCTED_CASE",
    is_reconstructed: true,
    verification_status: "RECONSTRUCTED",
    verification_note: [ ac.verification_note.presence, note ].compact.join("\n"),
    updated_at: Time.current
  )
  changed += 1
end

puts "  [trust-downgrade] changed=#{changed} missing=#{missing.size} #{missing.first(5).join(',')}"
