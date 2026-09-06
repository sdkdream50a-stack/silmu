# frozen_string_literal: true

# 2026-06-09 E-E-A-T 검증 배치2 (S4 색인 회복) — 계약-core 클러스터.
# 각 토픽의 법령 조문을 운영(silmu.kr 라이브)·law.go.kr·법제처 정본 조문맵과 1:1 대조 후에만 등재.
# (헤드라인 자동채움 금지 — 거짓 E-E-A-T 방지). 메타데이터만 갱신하므로 update_columns 사용.
#
# 정본 조문맵(법제처 OPEN API, content-fix batch9/11 + 운영 라이브 확인):
#   본법: §9=계약의 방법·§11=예정가격의 작성·§13=낙찰자의 결정·§14=계약서의 작성·§17=검사·§18=대가의 지급·§24=장기계속/계속비계약.
#   시행령: §9/§10=예정가격(작성·결정기준)·§13=참가자격·§42=재정지출부담입찰 낙찰자결정·§49=계약서 서식 위임·§50=계약서 작성 생략 등(기재사항은 법 §14①이 직접 규정)·§64/§66=검사(기한·조서)·§78=장기계속.
# ⚠️ 옛 "제8조(계약의 방법)"·"제13조(예정가격)"는 오기(운영서 정정됨). 예규 324호 잔존 토픽(multiple-price 등)은 332호 현행화 전이라 본 배치 제외.

# verification_source 컬럼 = varchar(200). 각 문자열 ≤200자 유지(아래 길이 가드로 강제).
VERIFIED_2026_06_09_B2 = {
  "bidding" =>
    "법제처 — 지방계약법 §9(계약의 방법: 일반경쟁 원칙·제한/지명경쟁·수의계약 예외), 시행령 §13(참가자격)·§20(제한입찰)·§22(지명입찰)·§33(입찰공고)·§35(공고시기), 시행규칙 §14·§17. 운영(silmu.kr) 정본 일치 확인",
  "estimated-price" =>
    "법제처 — 지방계약법 §11(예정가격의 작성·개찰 전 비공개), 시행령 §9(총액 원칙·부가세 포함)·§10(결정기준: 거래실례가격·원가계산·감정가격·유사거래실례). 운영(silmu.kr) 정본 일치 확인",
  "contract-execution" =>
    "법제처 — 지방계약법 §14①(기재: 목적·금액·이행기간·계약보증금·위험부담·지연배상금)·§14②(전자문서 원칙)·§14③(성립), 시행령 §49(서식 위임)·§50①(생략: 5천만원 이하 등 5개 호)·§50②(전자계약 예외). 운영(silmu.kr) 정본 일치 확인",
  "bid-qualification" =>
    "법제처 — 지방계약법 §13(낙찰자 결정: 최저가 원칙·적격심사 예외), 시행령 §42(재정지출부담입찰 낙찰자결정). 적격심사 공사 3억~300억 미만·물품/용역 2억↑, 공사 낙찰하한율 10억미만 89.745%·10~50억 88.745%·50~300억 88%. 운영 정본 확인",
  "long-term-contract" =>
    "법제처 — 지방계약법 §24(장기계속계약·계속비계약: ①1호 장기계속·2호 계속비), 시행령 §78(총 계약금액·총 이행기간·연도별 금액·기간 명시), 지방재정법 §42(계속비 예산). 운영(silmu.kr) 정본 일치 확인",
  "inspection" =>
    "법제처 — 지방계약법 §17(검사 의무)·§18(대가의 지급), 시행령 §64(검사 기한: 통보 후 14일 이내)·§66(검사조서: 5천만 초과 작성). 운영(silmu.kr) 정본 일치 확인"
}.freeze

# 길이 가드: varchar(200) 초과 시 즉시 실패(부분 적용·잘림 방지)
oversized = VERIFIED_2026_06_09_B2.select { |_s, src| src.length > 200 }
unless oversized.empty?
  abort "❌ verification_source 200자 초과: #{oversized.map { |s, src| "#{s}=#{src.length}" }.join(', ')}"
end

verified_at = Date.new(2026, 6, 9)
updated = 0
missing = []
VERIFIED_2026_06_09_B2.each do |slug, source|
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
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_09_B2.size}건 (2026-06-09 배치2 — 계약-core)"
puts "⚠️  미발견 slug: #{missing.join(', ')}" if missing.any?
