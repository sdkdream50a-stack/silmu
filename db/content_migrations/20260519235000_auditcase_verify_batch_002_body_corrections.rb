# AuditCase verify batch #2 — 본문 부정확 조문 인용 정정 (2026-05-19)
#
# verify batch #2 (20260519230000)에서 legal_basis만 정정한 Group B에서
# 라이브 spot check 결과 issue 필드(페이지 description·JSON-LD·공유 메타)에
# 폐지 조문 잔존 2건 발견. mcp 대조 기반 issue gsub 정정.
#
# 정정 대상:
#   1) cash-management-failure — issue "지방재정법 시행령 제60조" → "지방회계법 제43조"
#      (mcp: 시행령 §60 삭제. 현금 취급의 제한은 지방회계법 §43)
#   2) non-budgetary-funds-violation — issue "지방재정법 제64조" → "지방재정법 제34조 제3항"
#      (mcp: 법 §64 삭제. 예산총계주의 예외는 §34 ③항)
#
# 안전: issue 필드만 gsub. legal_basis는 verify batch #2에서 이미 정정 완료, 건드리지 않음.
# 본문(detail/lesson)에는 §60·§64 잔존 없음 (이미 정확한 § 인용).

body_corrections = [
  {
    slug: "cash-management-failure",
    substitutions: [
      [
        "지방재정법 시행령 제60조는 현금을 정확히 관리하고 정기적으로 점검해야 한다고 규정",
        "지방회계법 제43조(현금 취급의 제한)·제44조(출납원)는 현금을 정확히 관리하고 정기적으로 점검해야 한다고 규정"
      ]
    ]
  },
  {
    slug: "non-budgetary-funds-violation",
    substitutions: [
      [
        "지방재정법 제64조는 세입세출외현금은 별도 계정으로 관리해야 한다고 규정",
        "지방재정법 제34조 제3항(예산총계주의의 원칙 예외)·시행령 제40조는 세입세출외현금을 별도 계정으로 관리해야 한다고 규정"
      ]
    ]
  }
]

puts ""
puts "=== AuditCase verify batch #2 — body corrections (#{body_corrections.size}건) ==="

body_corrections.each do |c|
  ac = AuditCase.find_by(slug: c[:slug])
  if ac.nil?
    puts "    [skipped] #{c[:slug]} — 미존재"
    next
  end

  changed_fields = []
  c[:substitutions].each do |from, to|
    %i[issue detail lesson action_taken].each do |field|
      val = ac.public_send(field)
      next if val.blank?
      if val.include?(from)
        ac.public_send("#{field}=", val.gsub(from, to))
        changed_fields << "#{field}"
      end
    end
  end

  if ac.changed?
    ac.save!
    puts "    [corrected] #{c[:slug]} (fields: #{changed_fields.uniq.join(', ')})"
  else
    puts "    [unchanged] #{c[:slug]}"
  end
end
