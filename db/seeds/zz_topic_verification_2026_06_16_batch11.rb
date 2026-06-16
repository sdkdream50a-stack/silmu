# frozen_string_literal: true

# 2026-06-16 E-E-A-T 검증 배치11 (S4) — special-leave(본문 정확성 정정 동반).
# 정정: special_leave.rb 배우자 출산휴가 10일→20일(2025.2.11 지방/국가 복무규정 개정, 다태아 25일).
#   1차출처: 정책브리핑(korea.kr 148939204)·인사혁신처·복수 언론. 운영 "10일"은 stale이었음.
#   special_leave.rb는 find_or_initialize_by+save라 load 시 본문 갱신(content_fix gsub 불요).
# 경조사 별표(조부모 3일·형제자매 3일)는 silmu가 개정일 명시 반영분 → 정확(블로그 2일/1일은 구버전).
# verification_source ≤200, verification_method ≤32 가드.

VERIFIED_2026_06_16_B11 = {
  "special-leave" =>
    "법제처 — 지방공무원 복무규정(특별휴가)·국가공무원 복무규정 §20+별표2(경조사), 지방공무원법(복무 위임). 배우자 출산휴가 20일(2025.2.11 개정, 다태아 25일). 운영(silmu.kr) 본문 정정 후 일치 확인"
}.freeze

oversized = VERIFIED_2026_06_16_B11.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ verification_method 32자 초과: #{method.length}" if method.length > 32

verified_at = Date.new(2026, 6, 16)
updated = 0
missing = []
VERIFIED_2026_06_16_B11.each do |slug, source|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    missing << slug
    next
  end
  topic.update_columns(verification_source: source, verification_method: method, last_verified_at: verified_at)
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_16_B11.size}건 (2026-06-16 배치11 — special-leave 정정+attest)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
