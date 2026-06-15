# frozen_string_literal: true

#
# 감사사례 법령근거 정정 — 예규 번호 현행화 (제324호 → 제332호)
# 2026-06-09. cf. topic_content_fix_2026_06_09_yegyu332.rb (토픽 동일 정정).
#
# 정본: 「지방자치단체 입찰 및 계약집행기준」 현행 = 행정안전부 예규 제332호(2025.7.8 시행).
# 결함: 일부 AuditCase legal_basis가 옛 "제324호" 지칭(토픽 페이지 관련사례 섹션에 라이브 노출).
# ⚠️ "제324호" 정확 패턴만 치환 — 금액("644,324천원") 등 다른 324는 건드리지 않음.
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/audit_cases/legal_basis_correction_2026_06_09_yegyu332.rb})"'

FIELDS = AuditCase.column_names.freeze
results = []
AuditCase.find_each do |a|
  changes = {}
  FIELDS.each do |f|
    v = a.public_send(f)
    next unless v.is_a?(String) && v.include?("제324호")
    changes[f] = v.gsub("제324호", "제332호")
  end
  next if changes.empty?
  a.update_columns(changes)
  results << "#{a.slug}: FIXED [#{changes.keys.join(', ')}]"
end

puts "AuditCase 예규 324→332 현행화:"
results.each { |r| puts "  #{r}" }
remaining = AuditCase.all.count { |a| FIELDS.any? { |f| a.public_send(f).is_a?(String) && a.public_send(f).include?("제324호") } }
puts "→ AuditCase '제324호' 잔존: #{remaining}건#{remaining.zero? ? ' — CLEAN' : ''}"
