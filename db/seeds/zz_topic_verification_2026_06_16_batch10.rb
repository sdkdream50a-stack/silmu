# frozen_string_literal: true

# 2026-06-16 E-E-A-T 검증 배치10 (S4) — 계약·조달 4 + 노무 안정 3.
# 운영 라이브(silmu.kr/topics/*) 본문 + 1차출처(LBOX/easylaw/인사혁신처/법제처/WebSearch) 1:1 대조.
# verification_source ≤200, verification_method ≤32 가드. 헤드라인 자동채움 금지.
# 보류: special-leave(배우자 출산휴가 10일이 현행 20일과 불일치 의심 — 정확성 정정 선행).
#       bid-notice-requirements·comprehensive-contract(운영 404).

VERIFIED_2026_06_16_B10 = {
  "subcontract" =>
    "법제처 — 건설산업기본법 §29(일괄·전문·재하도급 제한)·§34(기성 수령 15일 내 하도급대금 지급)·§35(직접지급), 하도급법 §13(60일 내 지급)·§14, 지계 §31. 직접시공 50%. 운영(silmu.kr) 정본 일치 확인",
  "direct-production-confirm" =>
    "법제처 — 「중소기업제품 구매촉진 및 판로지원법」 §12(직접생산확인), 「지방자치단체 입찰 및 계약집행기준」(예규 제332호). 증명서 발급=중소기업중앙회(SMPP). 운영(silmu.kr) 정본 일치 확인",
  "national-vs-local-contract-law" =>
    "법제처 — 국가계약법·지방계약법 §1·§2 비교(국가=기재부 계약예규/지방=행안부 예규). 수의계약 한도 물품·용역 2천만·공사 종합 4억/전문 2억/기타 1.6억(지계 시행령 §25). 운영(silmu.kr) 정본 일치 확인",
  "cost-calculation-guide" =>
    "법제처 — 지계 시행령 §8(예정가격 결정: 거래실례가·원가계산·감정), 시행규칙 §6(원가 5비목: 재료·노무·경비·일반관리비·이윤)·§11. 일반관리비 공사 6%·이윤 공사 15%/제조 10%. 운영(silmu.kr) 정본 일치 확인",
  "leave-of-absence" =>
    "법제처 — 지방공무원법 §63(휴직)·§64(기간)·§65(효력). 질병휴직 1년(공무상 3년)·육아휴직 자녀당 3년, 공무원보수규정 §28(질병 1년차 70%). 인사혁신처 확인. 운영(silmu.kr) 정본 일치 확인",
  "disciplinary-action" =>
    "법제처 — 지방공무원법 §69(징계사유)·§70(종류: 파면·해임·강등·정직·감봉·견책)·§72·§73, 국가공무원법 §83의2(시효 일반 3년·금품 5년·성비위 10년). 파면 임용제한 5년. 운영(silmu.kr) 정본 일치 확인",
  "official-leave" =>
    "법제처 — 지방공무원 복무규정 §7의3·§7의4·§18(공가), 국가공무원 복무규정 §19. 사유: 병역·소집·투표·건강검진·헌혈·예비군 등 필요한 기간, 봉급 전액. 운영(silmu.kr) 정본 일치 확인"
}.freeze

oversized = VERIFIED_2026_06_16_B10.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ verification_method 32자 초과: #{method.length}" if method.length > 32

verified_at = Date.new(2026, 6, 16)
updated = 0
missing = []
VERIFIED_2026_06_16_B10.each do |slug, source|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    missing << slug
    next
  end
  topic.update_columns(verification_source: source, verification_method: method, last_verified_at: verified_at)
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_16_B10.size}건 (2026-06-16 배치10 — 계약·조달+노무)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
