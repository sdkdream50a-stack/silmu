# frozen_string_literal: true

# 2026-06-16 E-E-A-T 검증 배치9 (S4) — 계약 클러스터(계약금액 조정·공동·해지) 6토픽.
# 운영 라이브(silmu.kr/topics/*) 본문 + 1차출처(LBOX/easylaw/빅케이스/lawnb) 1:1 대조.
# ⚠️ 시행령 §74 = "설계변경으로 인한 계약금액의 조정" 확정(1차출처). 이전 조문맵 "§74=수의시담"은 오류.
# verification_source ≤200, verification_method ≤32 가드. 헤드라인 자동채움 금지.

VERIFIED_2026_06_16_B9 = {
  "design-change" =>
    "법제처 — 지방계약법 §22·시행령 §74(설계변경 계약금액 조정: 증액 청구 30일 내, 예가 86% 미만 낙찰+증액 10% 이상 단체장 승인)·§65/§66, 건산법 §22. 신규비목 단가 낙찰률 적용. 운영(silmu.kr) 정본 일치 확인",
  "contract-amount-adjustment" =>
    "법제처 — 지방계약법 §22·시행령 §73(물가변동: 입찰일 후 90일+등락 3% 이상)·§74(설계변경)·§75(기타 변경), 예규 제332호. 3종 조정사유 독립 적용. 운영(silmu.kr) 정본 일치 확인",
  "contract-period-extension" =>
    "법제처 — 지방계약법 §22②·시행령 §75의2(계약기간 연장 조정: 통제범위 외 사유=호우·대설·감염병 등)·§30①(지체상금 면제). 준공 30일 전 신청. 운영(silmu.kr) 정본 일치 확인",
  "joint-contract" =>
    "법제처 — 지방계약법 §29·시행령 §88(공동계약: 공동수급체 2인 이상, 구성원 최소지분 5%, 대표사 30% 이상), 「공동계약운용요령」. 공동이행·분담이행. 운영(silmu.kr) 정본 일치 확인",
  "contract-termination" =>
    "법제처 — 지방계약법 §30의2(계약 해제·해지)·시행령 §60~62(공사중단 30일/대금미지급 3개월 등 사유·절차)·§31(부정당 최대 2년). 보증금 10% 귀속. 운영(silmu.kr) 정본 일치 확인",
  "additional-contract-limit" =>
    "법제처 — 지방계약법 §22·시행령 §74(설계변경 증액 한도: 예가 86% 미만 낙찰+증액 10% 이상 단체장 승인), 예규 제332호. 동일목적물 분할발주 금지, 한도초과분 신규계약. 운영(silmu.kr) 정본 일치 확인"
}.freeze

oversized = VERIFIED_2026_06_16_B9.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ verification_method 32자 초과: #{method.length}" if method.length > 32

verified_at = Date.new(2026, 6, 16)
updated = 0
missing = []
VERIFIED_2026_06_16_B9.each do |slug, source|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    missing << slug
    next
  end
  topic.update_columns(verification_source: source, verification_method: method, last_verified_at: verified_at)
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_16_B9.size}건 (2026-06-16 배치9 — 계약 클러스터)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
