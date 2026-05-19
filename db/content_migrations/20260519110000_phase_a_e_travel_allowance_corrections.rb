# P6 Phase 2 — db/seeds/audit_cases/legal_basis_correction_2026_05_19_b.rb 컨버전
#
# 2026-05-19 batch #3 — 여비 audit_case legal_basis 운영 patch
# travel_allowance_audit_cases.rb는 find_or_create_by! 패턴 (idempotent 아님) → patch 별도 필요
# 정정 사유:
#   - §21(국내 가족여비)를 숙박비 본조로 잘못 인용 → §16 ①항(별표 2 상한액)
#   - §18(근무지 내 국내 출장)을 자가용 여비로 잘못 인용 → 별표 2 + 「공무원보수 등의 업무지침」

corrections = [
  {
    slug: "accommodation-allowance-false-claim",
    legal_basis: "공무원여비규정 제16조 제1항(숙박비·식비·일비)·별표 2(국내 여비 지급 기준표), 지방공무원 여비규정 제16조(숙박비), 형법 제227조의2(공전자기록등불실기재), 공무원 징계령 제2조",
    body_substitutions: [
      ["공무원여비규정 제21조 및 지방공무원 여비규정은 숙박비를 실비로 지급하되",
       "공무원여비규정 제16조 제1항 및 지방공무원 여비규정은 숙박비를 별표 2 상한액 범위 내 실비로 지급하되"],
      ["공무원여비규정 제21조는 숙박비를 실비로 지급하도록 규정하고 있습니다",
       "공무원여비규정 제16조 제1항은 숙박비를 별표 2 상한액 범위 내 실비로 지급하도록 규정하고 있습니다"]
    ]
  },
  {
    slug: "domestic-travel-transport-overclaim",
    body_substitutions: [
      ["공무원여비규정 제18조 및 지방공무원 여비규정 제18조는 자가용 여비를 \"출발지로부터 목적지까지의 실제 사용 거리\"를 기준으로 계산합니다",
       "공무원여비규정 별표 2(자가용승용차 사용 시 여비 지급 기준) 및 인사혁신처 「공무원보수 등의 업무지침」(예규, 2026-01-22 시행)은 자가용 여비를 \"출발지로부터 목적지까지의 실제 사용 거리\"를 기준으로 계산합니다"],
      ["공무원여비규정 제18조는 자가용 여비를 \"실제 사용 거리\"를 기준으로 계산하도록 규정합니다",
       "공무원여비규정 별표 2 및 인사혁신처 「공무원보수 등의 업무지침」(예규, 2026-01-22 시행)은 자가용 여비를 \"실제 사용 거리\"를 기준으로 계산하도록 규정합니다"]
    ],
    legal_basis: "공무원여비규정 별표 2(자가용승용차 사용 시 여비 지급 기준) + 인사혁신처 「공무원보수 등의 업무지침」(예규, 2026-01-22 시행), 지방공무원 여비규정 별표(자가용 여비)"
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
