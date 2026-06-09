# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 예규 번호 현행화 (제324호 → 제332호)
# 2026-06-09. cf. S2 권위확정(예규 현행 = 행안부 제332호, 2025.7.8 시행; 277→282→324→332).
#
# 정본(2026-06-09 재확인): 「지방자치단체 입찰 및 계약집행기준」 현행 = 행정안전부 예규 제332호
#   (law.go.kr admRulSeq=2100000261486 / mois.go.kr 제332호 2025.7.8 시행). 324호는 stale.
# 결함: 9개 토픽 본문이 현행 집행기준을 옛 "제324호"로 지칭(운영 라이브 노출 — 권위 훼손).
#   모두 "행정안전부 예규 제324호"/"(예규 제324호)" 형태로 현행 집행기준을 가리킴(역사적 참조 아님).
# 정정: 해당 토픽 content 필드의 "제324호" → "제332호" (외과적 — 번호만). update_columns로 ping 회피.
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_09_yegyu332.rb})"'

SLUGS = %w[
  bid-participation-restriction goods-vs-service-contract e-bidding-error-faq
  qualification-failure penalty-reduction-procedure disqualified-vendor
  completion-payment-checklist contract-guarantee-exemption private-contract-justification
].freeze

FIELDS = %w[law_content decree_content rule_content regulation_content interpretation_content commentary summary qa_content practical_tips faqs].freeze

results = []
SLUGS.each do |slug|
  t = Topic.find_by(slug: slug)
  if t.nil?
    results << "#{slug}: NOT_FOUND"; next
  end
  changes = {}
  FIELDS.each do |f|
    next unless t.respond_to?(f)
    v = t.public_send(f)
    next unless v.is_a?(String) && v.include?("제324호")
    changes[f] = v.gsub("제324호", "제332호")
  end
  if changes.empty?
    results << "#{slug}: CLEAN(324 없음)"
  else
    t.update_columns(changes)
    results << "#{slug}: FIXED [#{changes.keys.join(', ')}]"
  end
end

puts "예규 324→332 현행화 결과:"
results.each { |r| puts "  #{r}" }
remaining = Topic.published.select { |t| FIELDS.any? { |f| t.respond_to?(f) && t.public_send(f).is_a?(String) && t.public_send(f).include?("제324호") } }
puts "→ published 토픽 '제324호' 잔존: #{remaining.size}건#{remaining.any? ? ' (' + remaining.map(&:slug).join(', ') + ')' : ' — CLEAN'}"
