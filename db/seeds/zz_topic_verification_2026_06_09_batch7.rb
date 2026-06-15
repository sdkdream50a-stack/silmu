# frozen_string_literal: true

# 2026-06-09 E-E-A-T 검증 배치7 (S4) — 예규 332 현행화로 차단해제된 토픽 + 부정당업자/적격/정의.
# topic_content_fix_2026_06_09_yegyu332.rb로 324→332 정정 후 attest. 운영 라이브+law.go.kr 1:1 대조.
# verification_source ≤200, verification_method ≤32 가드. 헤드라인 자동채움 금지.
# 보류: disqualified-vendor(운영404)·contract-guarantee-exemption(면제액 2026.6.30 변경 임박 시한민감).

VERIFIED_2026_06_09_B7 = {
  "bid-participation-restriction" =>
    "법제처 — 지방계약법 §31(부정당업자 입찰참가자격 제한)·시행령 §92(제한 기간: 담합·뇌물 2년·부실시공 1년 등), 「지방자치단체 입찰 및 계약집행기준」(예규 제332호). 소명기회 7일. 운영(silmu.kr) 정본 일치 확인",
  "penalty-reduction-procedure" =>
    "법제처 — 지방계약법 §30(지체상금)·시행령 §90(지체상금률·감면)·시행규칙 §75. 감면 사유: 발주기관 귀책·천재지변·불가항력·법령변경(계약상대자 과실 제외). 예규 제332호. 운영(silmu.kr) 정본 일치 확인",
  "qualification-failure" =>
    "법제처 — 지방계약법 §13(낙찰자 결정)·시행령 §42(적격심사), 행안부 「지방자치단체 입찰시 낙찰자 결정기준」. 추정가격 2억↑ 적격심사, 종합 95점 이상 통과. 운영(silmu.kr) 정본 일치 확인",
  "goods-vs-service-contract" =>
    "법제처 — 지방계약법 §2(정의: 물품=유형 재화 취득, 용역=노무·서비스 제공)·시행령 §2(용역 범위: 설계·감리·정보처리 등). 혼합계약 물품가액 70%↑이면 물품. 운영(silmu.kr) 정본 일치 확인",
  "completion-payment-checklist" =>
    "법제처 — 지방계약법 §17(검사)·§18(대가 지급), 시행령 §64(검사 14일)·§67·§68(대가 청구 후 5일). 준공검사→하자보증 확인→지급. 예규 제332호. 운영(silmu.kr) 정본 일치 확인",
  "private-contract-justification" =>
    "법제처 — 지방계약법 §9①단서(수의계약)·시행령 §25①(사유: 소액 물품/용역 2천만·공사 1.6억~4억, 긴급·특정·2회 유찰), 「지방자치단체 입찰 및 계약집행기준」(예규 제332호). 운영(silmu.kr) 정본 일치 확인",
  "multiple-price" =>
    "법제처 — 지방계약법 §11(예정가격)·시행령 §8(복수예비가격: 기초금액 ±3% 15개 작성→4개 추첨 산술평균), 「지방자치단체 입찰 및 계약집행기준」(예규 제332호). 운영(silmu.kr) 정본 일치 확인"
}.freeze

oversized = VERIFIED_2026_06_09_B7.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ verification_method 32자 초과: #{method.length}" if method.length > 32

verified_at = Date.new(2026, 6, 9)
updated = 0
missing = []
VERIFIED_2026_06_09_B7.each do |slug, source|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    missing << slug
    next
  end
  topic.update_columns(verification_source: source, verification_method: method, last_verified_at: verified_at)
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_09_B7.size}건 (2026-06-09 배치7 — 332 차단해제분)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
