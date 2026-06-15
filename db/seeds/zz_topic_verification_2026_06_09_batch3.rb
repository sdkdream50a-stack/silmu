# frozen_string_literal: true

# 2026-06-09 E-E-A-T 검증 배치3 (S4 색인 회복) — 계약 이행·보증·전자조달·회계 클러스터.
# 각 토픽 조문을 운영(silmu.kr 라이브)+law.go.kr 정본 1:1 대조 후 등재. 헤드라인 자동채움 금지.
# verification_source = varchar(200) → 200자 가드 강제(초과 시 abort).

VERIFIED_2026_06_09_B3 = {
  "extra-budgetary-fund" =>
    "법제처 — 지방회계법 §44③(세입세출외현금 출납원 구분)·§42·§43(공금 취급·현금관리), 시행령 §51(종류별 금고 보관)·§52(직접취급 예외). 유형: 보증금·보관금·예치금·기부금. 운영(silmu.kr) 정본 일치 확인",
  "entertainment-expense-rules" =>
    "법제처·국민권익위 — 청탁금지법 시행령 별표1(음식물·선물·경조사비 가액 한도, 연도 개정), 공무원 행동강령 §14③2호(사교의례 가액 범위). 현행 한도는 별표1 직접 확인 권고. 운영(silmu.kr) 정본 일치 확인",
  "e-bidding" =>
    "법제처 — 전자조달법 §5(전자적 처리)·§6(전자 공고)·§7(전자입찰), 지방계약법 §14②(전자계약 의무), 시행령 §39(입찰서 제출·접수). 추정가격 2천만원 초과 시 나라장터 전자입찰 의무. 운영(silmu.kr) 정본 일치 확인",
  "spec-price-split-bid" =>
    "법제처 — 지방계약법 시행령 §18③(규격·가격 분리 2단계 입찰). 적용 추정가격 1억원↑(임의)·2억원↑(의무), 규격심의위 5명 이상(전문가 2/3 이상). 운영(silmu.kr) 정본 일치 확인",
  "defect-warranty" =>
    "법제처 — 지방계약법 §21(하자보수보증금 납부), 시행령 §69(담보책임 존속기간: 구조체 5년·방수 3년·창호 2년·도장 1년)·§71(보증금 2~10%: 구조체 5%·방수 3~4%·도장 2%)·§72. 운영(silmu.kr) 정본 일치 확인",
  "payment" =>
    "법제처 — 지방계약법 §18(대가의 지급: 청구 후 5일 이내), 시행령 §68(대가 지급·지연이자)·§54(기성대가)·§55(준공대가). 선금 계약금액 70% 이내(입찰·계약집행기준). 운영(silmu.kr) 정본 일치 확인",
  "price-escalation" =>
    "법제처 — 지방계약법 시행령 §73(물가변동에 따른 계약금액 조정). 요건: 계약체결(직전 조정기준일)부터 90일 이상 경과 + 등락률 3% 이상 변동, 두 요건 모두 충족. 운영(silmu.kr) 정본 일치 확인",
  "contract-guarantee-deposit" =>
    "법제처 — 지방계약법 §15(계약보증금: 계약금액 10% 이상), 시행령 §52(10% 이상)·§53(면제: 물품·용역 5천만·공사 1억 이하)·§54(불이행 시 10% 징수). 운영(silmu.kr) 정본 일치 확인"
}.freeze

oversized = VERIFIED_2026_06_09_B3.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

verified_at = Date.new(2026, 6, 9)
updated = 0
missing = []
VERIFIED_2026_06_09_B3.each do |slug, source|
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
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_09_B3.size}건 (2026-06-09 배치3 — 이행·보증·전자조달·회계)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
