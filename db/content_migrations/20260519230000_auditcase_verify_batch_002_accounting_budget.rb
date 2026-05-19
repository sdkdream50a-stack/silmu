# AuditCase verify batch #2 — category=회계 10건 + 예산 20건 (2026-05-19)
#
# stale AuditCase 점진 검증의 두 번째 batch. 회계 잔여 전체(10건) + 예산 HAS_ARTICLE 그룹 상위 20건.
#
# 처리:
#   1) Group B 20건 — mcp 법제처 OPEN API 대조 결과 발견한 부정확 legal_basis 정정
#   2) 30건 전체 mark_verified! — 모두 mcp_law_api method
#
# 핵심 발견 (batch #1 학습 — 본문은 이미 정확, legal_basis 메타필드만 부정확한 패턴):
#   - id 56·59·60·66·70: detail/lesson은 이미 올바른 § 인용, legal_basis만 잘못 기재 → 메타만 정정
#   - 폐지 조문 인용 3건 (시급도 최상): id 69(시행령 §60), id 90(법 §53), id 59(법 §64) — 모두 mcp로 폐지 확정
#   - 잘못된 § 6건: id 70(§21 채권 X), id 88·91(시행령 §68 공시방법 X), id 56(§37 투자심사 X), id 60(시행령 §47 과목구분 X), id 65(시행령 §40 외처리경비 X), id 124(§32①1호 학교헌장 X)
#
# 그룹:
#   - Group A (10건, mcp_law_api): legal_basis 정확 — verify-only
#       id: 58, 61, 62, 81, 84, 87, 92, 98, 99, 123
#   - Group B (20건, mcp_law_api): 본 batch mcp 대조 + 정정
#       id: 회계 9 (66, 67, 68, 69, 70, 88, 89, 90, 91) + 예산 11 (56, 57, 59, 60, 63, 64, 65, 82, 85, 94, 124)
#   - 보류: id 125 (학교회계 시행령 §64 정정 필요) — batch #3 진입
#
# mcp 검증 lawId 캐시:
#   - 지방회계법 MST=276363, 지방재정법 MST=281909, 지방재정법 시행령 MST=281539
#   - 회계관계직원책임법 MST=276163, 지방자치법 MST=276357
#   - 부가가치세법 MST=276117, 보조금관리법 MST=276113
#   - 초·중등교육법 MST=279605, 시행령 MST=285453, 지방세기본법 MST=283257

corrections = [
  # === 회계 9건 ===

  # id 66 — 증빙서류 미비로 회계처리 부적정
  # silmu: 시행령 §58 "지출증빙서류" — §58 실제 표제 "세출예산의 이월". 본문은 이미 지방회계법 §29 인용.
  {
    slug: "accounting-evidence-missing",
    legal_basis: "지방회계법 제29조(지출원인행위 — 예산 범위 내 집행), 회계관계직원 등의 책임에 관한 법률 제4조(변상책임), 지방회계법 시행령(증빙서류 보존)"
  },
  # id 67 — 복식부기 회계처리 오류
  # silmu: §12 "발생주의·복식부기" — 실제 표제 "지방회계기준"(발생주의·복식부기 방식 위임)
  {
    slug: "double-entry-error",
    legal_basis: "지방회계법 제12조(지방회계기준 — 발생주의·복식부기 방식, 행정안전부령 위임)"
  },
  # id 68 — 결산서 작성 오류
  # silmu: §15 "결산서의 작성" — 실제 표제 "결산서의 구성"
  {
    slug: "financial-statement-error",
    legal_basis: "지방회계법 제15조(결산서의 구성 — 결산 개요·세입세출 결산·재무제표·성과보고서), 지방회계법 제14조(결산의 수행)"
  },
  # id 69 — 현금 출납 관리 부실
  # silmu: 시행령 §60 "현금의 출납" — §60 삭제됨 ⚠️ 폐지 조문
  {
    slug: "cash-management-failure",
    legal_basis: "지방회계법 제43조(현금 취급의 제한), 지방회계법 제44조(출납원 — 임명·구분), 회계관계직원 등의 책임에 관한 법률 제4조 ②항(현금 망실 변상책임)"
  },
  # id 70 — 채권 관리 소홀로 시효 소멸
  # silmu: 지방회계법 §21 "채권의 관리" — §21 실제 "세입의 징수기관과 징수의 방법". 본문은 이미 지방세기본법 §39·§40 인용.
  {
    slug: "debt-management-negligence",
    legal_basis: "지방세기본법 제39조(지방세징수권의 소멸시효 — 5천만원 미만 5년·이상 10년), 지방세기본법 제40조(시효의 중단과 정지 — 납세고지·독촉·교부청구·압류), 회계관계직원 등의 책임에 관한 법률 제4조(변상책임)"
  },
  # id 88 — 예산 목 오류 집행
  # silmu: 시행령 §68 "지출결의" — §68 실제 "지방재정 운용상황의 공시방법". 잘못된 §.
  {
    slug: "budget-item-wrong-category",
    legal_basis: "지방재정법 제41조(예산의 과목 구분 — 장·관·항·세부항목·목), 지방재정법 시행령 제47조(예산의 과목구분 및 설정), 행정안전부 「지방자치단체 세입·세출 예산과목 구분」"
  },
  # id 89 — 업무추진비 개인 유용
  # silmu: §47 "예산의 목적 외 사용금지와 예산 이체" — 실제 §47 단순 "예산의 목적 외 사용금지"
  {
    slug: "business-expense-personal-use",
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지), 지방자치단체 업무추진비 집행에 관한 규칙, 회계관계직원 등의 책임에 관한 법률 제4조(변상책임)"
  },
  # id 90 — 결산서 의회 제출 기한 초과
  # silmu: 지방재정법 §53 "결산" — §53 삭제됨 ⚠️ 폐지 조문 (결산 의무는 지방회계법 §14)
  {
    slug: "settlement-report-delayed",
    legal_basis: "지방회계법 제14조(결산의 수행 — 회계연도마다 결산서 작성·검사위원 검사), 지방자치법 제150조(결산 — 출납 폐쇄 후 80일 내 작성·다음 해 의회 승인)"
  },
  # id 91 — 증빙서류 없는 지출결의
  # silmu: 시행령 §68 "지출결의서" — §68 실제 "공시방법". 잘못된 §.
  {
    slug: "budget-execution-no-receipt",
    legal_basis: "지방회계법 제29조(지출원인행위 — 예산 범위 내 집행), 부가가치세법 제32조(세금계산서 등 — 발급 의무), 회계관계직원 등의 책임에 관한 법률 제4조"
  },

  # === 예산 11건 ===

  # id 56 — 예산편성 시기 위반
  # silmu: 지방재정법 §37 "예산안의 제출시기" — §37 실제 "투자심사". 본문은 이미 지방자치법 §142 인용.
  {
    slug: "budget-timing-violation",
    legal_basis: "지방자치법 제142조(예산의 편성 및 의결 — 시·도 50일 전·시군구 40일 전 제출, 시·도의회 15일 전·시군구의회 10일 전 의결)"
  },
  # id 57 — 예산 목적 외 사용
  # silmu: §47 라벨에 "이용·이체" 부적절 추가 — §47 본문은 단순 목적 외 금지만 명시
  {
    slug: "budget-misuse",
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지), 회계관계직원 등의 책임에 관한 법률 제4조(변상책임)"
  },
  # id 59 — 세입세출외현금 미처리
  # silmu: 지방재정법 §64 — §64 삭제됨 ⚠️ 폐지 조문. 본문은 이미 지방회계법 §20~§23 인용.
  {
    slug: "non-budgetary-funds-violation",
    legal_basis: "지방재정법 제34조 ③항(예산총계주의의 원칙 — 기금 운용·보관 의무 현금 등은 예산 외 처리 가능), 지방재정법 시행령 제40조(세입세출예산 외로 처리할 수 있는 경비의 범위), 지방회계법 제22조(수납기관), 지방회계법 제44조(세입세출외현금 출납원)"
  },
  # id 60 — 사고이월 요건 미충족
  # silmu: 시행령 §47 "사고이월" — §47 실제 "예산 과목구분". 본문은 이미 모법 §50 인용.
  {
    slug: "budget-carryover-violation",
    legal_basis: "지방재정법 제50조(세출예산의 이월 — ②항 사고이월비 4호 요건), 지방재정법 시행령 제58조(세출예산의 이월 — 사고이월 가능 경비 세부)"
  },
  # id 63 — 예산 전용 한도 초과 (의회 승인 누락)
  # silmu: §47 + "정책사업 간 이용·예산 이체" — 전용은 §49, 이용은 별도. §47 자체는 목적외금지.
  {
    slug: "budget-transfer-limit-violation",
    legal_basis: "지방재정법 제49조(예산의 전용 — 정책사업 내 단위사업·목 간 전용), 지방재정법 시행령 제55조(예산의 전용 — 인건비·상환금 원금 제외), 지방재정법 제47조(예산의 목적 외 사용금지)"
  },
  # id 64 — 긴급예산 편성 요건 미충족
  # silmu: §43 "긴급한 예산집행" — §43 실제 "예비비" (예측 불가·예산 외 지출 충당)
  {
    slug: "emergency-budget-violation",
    legal_basis: "지방재정법 제43조(예비비 — 일반회계·교특회계 예산총액 100분의 1 이내), 지방재정법 시행령 제48조(예비비 사용의 제한 — 업무추진비·보조금 제외), 지방자치법 제150조 ①항(예비비 사용 명세서 의회 승인)"
  },
  # id 65 — 예산서 작성 오류
  # silmu: 시행령 §40 "예산서의 작성" — §40 실제 "세입세출예산 외 처리 경비 범위". 모법 §40이 "예산의 내용".
  {
    slug: "budget-document-error",
    legal_basis: "지방재정법 제40조(예산의 내용 — 예산총칙·세입세출예산·계속비·채무부담행위·명시이월비), 지방자치법 제142조(예산의 편성 및 의결)"
  },
  # id 82 — 의회 의결 없이 항 간 이용 처리
  # silmu: §47 라벨 부적절 추가 — 정책사업 간 이용/이체는 §49(전용)
  {
    slug: "budget-transfer-without-council-approval",
    legal_basis: "지방재정법 제47조(예산의 목적 외 사용금지), 지방재정법 제49조(예산의 전용), 지방자치법 제142조(예산의 편성 및 의결 — 의회 의결 의무)"
  },
  # id 85 — 국고보조금 목적 외 사용 환수
  # silmu: §22 + §33 "반환" + §40 — §33은 "보조금수령자에 대한 환수"가 정확 라벨. 보조사업자 반환은 §31.
  {
    slug: "national-subsidy-purpose-misuse",
    legal_basis: "보조금 관리에 관한 법률 제22조(용도 외 사용 금지 — 보조사업자·간접보조사업자), 보조금 관리에 관한 법률 제30조(법령 위반 등에 따른 교부 결정의 취소), 보조금 관리에 관한 법률 제31조(보조금의 반환 — 취소 부분 + 이자), 보조금 관리에 관한 법률 제40조(벌칙 — 10년 이하 징역 또는 1억원 이하 벌금)"
  },
  # id 94 — 국고보조금 정산 허위 보고
  # silmu: §30 "실적보고" — §30 실제 "교부 결정 취소". 실적보고는 §27.
  {
    slug: "subsidy-settlement-false-report",
    legal_basis: "보조금 관리에 관한 법률 제27조(보조사업 또는 간접보조사업의 실적 보고 — 정산보고서·외부감사인 검증), 보조금 관리에 관한 법률 제28조(보조금의 금액 확정 — 심사·현지조사), 보조금 관리에 관한 법률 제31조(보조금의 반환 — 거짓 정산 시 취소+반환), 보조금 관리에 관한 법률 제40조(벌칙)"
  },
  # id 124 — 학교운영위원회 심의 없이 학교회계 예산 확정
  # silmu: §32 ①항 "1호" — 실제 1호는 "학교헌장과 학칙". 학교 예산안과 결산은 §32 ①항 "2호". 시행령 §60은 "심의결과의 시행 등".
  {
    slug: "school-budget-without-committee-review",
    legal_basis: "초·중등교육법 제32조 ①항 제2호(학교운영위원회 심의 사항 — 학교의 예산안과 결산), 초·중등교육법 제31조(학교운영위원회의 설치), 초·중등교육법 제30조의2(학교회계의 설치), 초·중등교육법 시행령 제60조(심의결과의 시행 등)"
  }
]

puts ""
puts "=== AuditCase verify batch #2 — corrections (#{corrections.size}건) ==="

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

# Group A — legal_basis 정확, verify-only (10건)
# id 58 budget-overrun / 61 supplementary-budget-violation / 62 reserve-fund-violation
# id 81 budget-execution-before-approval / 84 supplementary-budget-before-council
# id 87 accounting-officer-dual-role-fraud / 92 local-bond-excess-issuance
# id 98 budget-appropriation-mistake / 99 expenditure-over-budget
# id 123 guideline-abolished-project-budget
group_a_slugs = %w[
  accounting-officer-dual-role-fraud
  supplementary-budget-violation
  reserve-fund-violation
  budget-execution-before-approval
  supplementary-budget-before-council
  local-bond-excess-issuance
  budget-appropriation-mistake
  expenditure-over-budget
  budget-overrun
  guideline-abolished-project-budget
]

# Group B — corrections + verify (20건)
group_b_slugs = corrections.map { |c| c[:slug] }

group_a_source = "법제처 OPEN API mcp 대조 — legal_basis 정확 확인 (lawId 276363·281909·276163·276357·276113·281539, 2026-05-19 batch #2)"
group_b_source = "법제처 OPEN API mcp spot check + 부정확 정정 (lawId 276363·281909·281539·276163·276357·276117·276113·279605·285453·283257, 2026-05-19 batch #2 — 폐지 조문 3건 + 잘못된 § 9건 정정)"

puts ""
puts "=== AuditCase verify batch #2 — mark_verified! (#{group_a_slugs.size + group_b_slugs.size}건) ==="

[
  [group_a_slugs, "mcp_law_api", group_a_source],
  [group_b_slugs, "mcp_law_api", group_b_source]
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
puts "[INFO] AuditCase verified_recently 총 #{verified_count}건 (기존 36 + 본 batch 30 = 66 기대)"
