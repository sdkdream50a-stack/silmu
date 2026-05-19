# P6 Phase 2 — db/seeds/audit_cases/legal_basis_correction_2026_05_19.rb 컨버전
#
# 2026-05-19 — 회계·재정 인용 정합성 정정 batch
# Phase A~E 전수 검증 후 발견된 audit_case 4건 legal_basis 정정
# 정정 사유:
#   - 시행령 제65조(재정분석)를 예비비 사용 근거로 잘못 인용 → 시행령 제48조(예비비 사용의 제한)로 정정
#   - 시행령 제72조(긴급재정관리)를 사고이월 근거로 잘못 인용 → 모법 제50조 제2항(사고이월비)으로 정정
#   - §36의2(성인지 예산서) → §38 ②항(예산편성기준 위임)
# 5단계 게이트 검증: 법제처 mcp 대조 완료 (MST 281909, 281539)

corrections = [
  {
    slug: "contingency-fund-misuse",
    legal_basis: "지방재정법 제43조(예비비), 지방재정법 시행령 제48조(예비비 사용의 제한)"
  },
  {
    slug: "budget-lapse-improper-carryover",
    legal_basis: "지방재정법 제50조 제2항(사고이월비 — 회계연도 내 지출원인행위 + 불가피 사유)"
  },
  {
    slug: "contingency-fund-purpose-misuse",
    legal_basis: "지방재정법 제43조 제2항(목적예비비 — 재해·재난 별도 계상), 지방재정법 시행령 제48조(예비비 사용 제한 — 업무추진비·보조금 제외)"
  },
  {
    slug: "guideline-excess-budget-compilation",
    legal_basis: "지방재정법 제38조 제2항(예산편성기준 — 행정안전부령 위임), 지방재정법 제41조(예산의 과목 구분), 행정안전부 「지방자치단체 예산편성 운영기준」",
    body_substitutions: [
      ["지방재정법 제36조의2 제2항", "지방재정법 제38조 제2항"],
      ["지방재정법 제36조의2", "지방재정법 제38조 제2항"]
    ]
  }
]

corrections.each do |c|
  ac = AuditCase.find_by(slug: c[:slug])
  if ac.nil?
    puts "    [skipped] #{c[:slug]} — 미존재"
    next
  end
  ac.legal_basis = c[:legal_basis] if c[:legal_basis]
  if c[:body_substitutions]
    c[:body_substitutions].each do |from, to|
      ac.detail = ac.detail.gsub(from, to) if ac.detail
      ac.lesson = ac.lesson.gsub(from, to) if ac.lesson
    end
  end
  if ac.changed?
    ac.save!
    puts "    [updated] #{c[:slug]} — #{ac.previous_changes.keys.join(', ')}"
  else
    puts "    [unchanged] #{c[:slug]}"
  end
end
