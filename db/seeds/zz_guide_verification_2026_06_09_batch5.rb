# frozen_string_literal: true

# 2026-06-09 E-E-A-T 검증 배치5 (S4 색인 회복) — Guide(고조회 실무 가이드).
# 대응 토픽(검증 완료)과 substantive 법령 사실이 일치하고 인용이 정합한 가이드만 등재.
# 운영(silmu.kr/guides/<slug>) 본문 직접 확인 후 attest. 헤드라인 자동채움 금지.
# verification_source = varchar(200) → 200자 가드 강제.

VERIFIED_GUIDE_2026_06_09 = {
  "private-contract-guide" =>
    "법제처 — 지방계약법 §9(수의계약)·시행령 §25(한도: 물품·용역 2천만·종합공사 4억·전문공사 2억, 특례 5천만), 「지방자치단체 입찰 및 계약집행기준」. 대응 토픽 private-contract 검증 정합. 운영 가이드 본문 확인",
  "private-contract-amount-guide" =>
    "법제처 — 지방계약법 시행령 §25(수의계약 대상·한도)·§30(금액별 견적: 200만 이하 견적 생략, 2천만 이하 1인 견적, 한도까지 2인 이상). 대응 토픽 private-contract-amount 검증 정합. 운영 가이드 본문 확인",
  "single-quote-guide" =>
    "법제처 — 지방계약법 시행령 §30(1인 견적 수의계약: 추정가격 2천만 이하, 특례기업 5천만 이하)·§25(대상). 대응 토픽 single-quote 검증 정합. 운영 가이드 본문 확인",
  "purchase-and-inspection" =>
    "법제처 — 지방계약법 §15(계약보증금 10%)·§18(대가 지급)·시행령 §64(검사: 통보 후 14일 이내)·§77(공사의 분할계약 금지). 대응 토픽 inspection·contract-guarantee-deposit 검증 정합. 운영 가이드 본문 확인",
  "inspection-report" =>
    "법제처 — 지방계약법 §17(검사)·시행령 §64(검사 기한)·§66(검사조서: 5천만 초과 작성), 물품관리법. 대응 토픽 inspection 검증 정합. 운영 가이드 본문 확인"
}.freeze

oversized = VERIFIED_GUIDE_2026_06_09.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

# verification_method = varchar(32)
method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ verification_method 32자 초과: #{method.length}" if method.length > 32

verified_at = Date.new(2026, 6, 9)
updated = 0
missing = []
VERIFIED_GUIDE_2026_06_09.each do |slug, source|
  guide = Guide.find_by(slug: slug)
  if guide.nil?
    missing << slug
    next
  end
  guide.update_columns(
    verification_source: source,
    verification_method: method,
    last_verified_at: verified_at
  )
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_GUIDE_2026_06_09.size}건 (2026-06-09 배치5 — Guide)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
