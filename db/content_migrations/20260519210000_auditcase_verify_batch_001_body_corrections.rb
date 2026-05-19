# AuditCase verify batch #1 — 본문 부정확 조문 인용 정정 (2026-05-19)
#
# verify batch #1 (20260519200000)에서 legal_basis만 정정한 Group B 3건의
# detail/lesson 본문에 부정확 조문 인용 잔존을 발견. mcp 대조 기반 본문 gsub 적용.
#
# 정정 대상:
#   1) vehicle-travel-allowance-distance-fraud — 본문 §18 → §13·별표 2
#      (mcp: §18 = 근무지 내 국내 출장. 자가용여비는 §13 자동차운임)
#   2) retirement-allowance-service-period-error — 본문 시행령 §19 → 모법 §25 ④항
#      (mcp: 시행령 §19 = 재직기간 감축사유 통보. 합산 제외는 모법 §25)
#   3) travel-expense-settlement-no-receipt — 본문 §5 "실비 계산" → §4 "실비 계산"
#      (mcp: §5 = 여행일수 계산. 실비 계산은 §4 단서)
#
# 안전: detail/lesson 필드만 gsub. legal_basis는 verify batch #1에서 이미 정정 완료, 건드리지 않음.

body_corrections = [
  {
    slug: "vehicle-travel-allowance-distance-fraud",
    substitutions: [
      ["공무원여비규정 제18조", "공무원여비규정 제13조·별표 2(자동차운임)"],
      ["지방공무원 여비규정 제18조", "지방공무원 여비규정 제13조·별표 2(자동차운임)"]
    ]
  },
  {
    slug: "retirement-allowance-service-period-error",
    substitutions: [
      ["공무원연금법 시행령 제19조", "공무원연금법 제25조 ④항(퇴직수당 재직기간 합산 제외)"]
    ]
  },
  {
    slug: "travel-expense-settlement-no-receipt",
    substitutions: [
      # 컨텍스트와 함께 매칭하여 legal_basis 정확 인용(§5 = 여행일수의 계산)과 충돌 방지
      ["공무원여비규정 제5조는 여비를 실비로 계산", "공무원여비규정 제4조는 여비를 실비로 계산"],
      ["공무원여비규정 제5조의 취지", "공무원여비규정 제4조의 취지"]
    ]
  }
]

body_corrections.each do |c|
  ac = AuditCase.find_by(slug: c[:slug])
  if ac.nil?
    puts "    [skipped] #{c[:slug]} — 미존재"
    next
  end

  changed_fields = []
  c[:substitutions].each do |from, to|
    if ac.detail&.include?(from)
      ac.detail = ac.detail.gsub(from, to)
      changed_fields << "detail:#{from[0, 20]}…"
    end
    if ac.lesson&.include?(from)
      ac.lesson = ac.lesson.gsub(from, to)
      changed_fields << "lesson:#{from[0, 20]}…"
    end
  end

  if ac.changed?
    ac.save!
    puts "    [body-corrected] #{c[:slug]} — #{changed_fields.uniq.join(', ')}"
  else
    puts "    [unchanged] #{c[:slug]} — gsub 패턴 매칭 0회"
  end
end
