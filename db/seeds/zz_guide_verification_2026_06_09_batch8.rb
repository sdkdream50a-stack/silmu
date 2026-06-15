# frozen_string_literal: true

# 2026-06-09 E-E-A-T 검증 배치8 (S4) — 고조회 Guide(대응 토픽 검증·본문 정합분).
# 운영(silmu.kr/guides/<slug>) 본문 직접 확인 + 대응 토픽(배치1 검증) 법령 정합. 헤드라인 자동채움 금지.
# 보류: private-contract-limit-guide(한도 "연간 누계 5천만" framing — 일반 2천만/특례 5천만 혼동 소지),
#   price-negotiation-guide(가이드=협상에 의한 계약, 대응 토픽=수의시담 §74 — 다른 제도라 조문 재검증 필요).
# verification_source ≤200, verification_method ≤32 가드.

VERIFIED_GUIDE_2026_06_09_B8 = {
  "emergency-contract-guide" =>
    "법제처 — 지방계약법 §9①(수의계약)·시행령 §25①4호(긴급 수의: 천재지변·재난·전염병 등 경쟁에 부칠 여유 없는 경우). 예정가격 초과 불가·긴급 종료 후 경쟁입찰 복귀. 대응 토픽 emergency-contract 검증 정합. 운영 가이드 확인",
  "budget-carryover-guide" =>
    "법제처 — 지방재정법 §50(세출예산 이월: 명시이월·사고이월·계속비이월)·시행령 §55(이월 절차), 행안부 「지방자치단체 예산편성 운영기준」. 대응 토픽 budget-carryover 검증 정합. 운영 가이드 확인",
  "dual-quote-guide" =>
    "법제처 — 지방계약법 시행령 §25(수의계약 한도)·§30②(2인 이상 견적), 소기업·소상공인 지원 특별조치법 §7의2(수의 특례). 추정가격 2천만 초과~5천만 이하. 대응 토픽 dual-quote 검증 정합. 운영 가이드 확인"
}.freeze

oversized = VERIFIED_GUIDE_2026_06_09_B8.select { |_s, src| src.length > 200 }
abort "❌ source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}" unless oversized.empty?
method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32

verified_at = Date.new(2026, 6, 9)
updated = 0
missing = []
VERIFIED_GUIDE_2026_06_09_B8.each do |slug, source|
  g = Guide.find_by(slug: slug)
  if g.nil?
    missing << slug; next
  end
  g.update_columns(verification_source: source, verification_method: method, last_verified_at: verified_at)
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_GUIDE_2026_06_09_B8.size}건 (2026-06-09 배치8 — Guide)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
