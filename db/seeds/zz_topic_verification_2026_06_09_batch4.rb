# frozen_string_literal: true

# 2026-06-09 E-E-A-T 검증 배치4 (S4 색인 회복) — 계약 보증/선금/가격기준 + 지방공무원법 복무.
# 각 토픽 조문을 운영(silmu.kr 라이브)+law.go.kr 정본 1:1 대조 후 등재. 헤드라인 자동채움 금지.
# verification_source = varchar(200) → 200자 가드 강제.

VERIFIED_2026_06_09_B4 = {
  "performance-guarantee" =>
    "법제처 — 지방계약법 §15(계약보증금=계약이행보증: 계약금액 10% 이상), 시행령 §52~§54(납부: 현금·보증서·국공채, 면제: 2천만 이하·국가/지자체, 불이행 시 귀속). 운영(silmu.kr) 정본 일치 확인",
  "advance-payment" =>
    "법제처 — 지방계약법 시행령(선금)·행안부 「지방자치단체 입찰 및 계약집행기준」: 선금 한도 공사·제조·용역 70%·학술연구 50%, 선금이행보증서 필수, 기성 비례 정산. 운영(silmu.kr) 정본 일치 확인",
  "estimated-amount" =>
    "법제처 — 지방계약법 시행령 §2①(추정가격: 부가세·관급 제외), 시행규칙 §2②(추정금액: 부가세·관급 포함), 시행령 §2②(예정가격: 결정 상한)·§77(분할계약 한도회피 금지). 운영(silmu.kr) 정본 일치 확인",
  "audit-immunity" =>
    "법제처 — 공공감사에 관한 법률 §23의2(적극행정 면책: 공익성·적극성·결과발생·고의/중과실 부존재 4요건, 처분요구 전 신청, 면책심의위 의결). 금품수수·직무태만 제외. 운영(silmu.kr) 정본 일치 확인",
  "position-suspension" =>
    "법제처 — 지방공무원법 §65의3(직위해제: 능력부족·중징계의결요구·형사기소·비위수사 등)·국가공무원법 §73의3. 봉급 감액 능력부족 80%·기소/수사/중징계 50%(3개월 후 30%). 운영(silmu.kr) 정본 일치 확인",
  "reinstatement" =>
    "법제처 — 지방공무원법 §65(복직: 휴직·직위해제 사유 소멸 시)·국가공무원법 §73. 사유 소멸·기간 만료 후 30일 이내 복귀 신고, 임용권자 지체 없이 복직 명령. 운영(silmu.kr) 정본 일치 확인",
  "concurrent-position" =>
    "법제처 — 지방공무원법 §56(영리업무 및 겸직 금지: 소속기관장 허가, 영리업무 4유형·직무지장·부당영향 심사), 청탁금지법 §10(외부강의 신고). 운영(silmu.kr) 정본 일치 확인"
}.freeze

oversized = VERIFIED_2026_06_09_B4.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

verified_at = Date.new(2026, 6, 9)
updated = 0
missing = []
VERIFIED_2026_06_09_B4.each do |slug, source|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    missing << slug
    next
  end
  topic.update_columns(
    verification_source: source,
    verification_method: "law.go.kr 1:1 대조 (운영 콘텐츠 정본 확인)",
    last_verified_at: verified_at
  )
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_09_B4.size}건 (2026-06-09 배치4 — 보증·선금·가격기준·복무)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
