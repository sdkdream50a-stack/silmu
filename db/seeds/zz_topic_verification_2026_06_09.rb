# frozen_string_literal: true
# 2026-06-09 E-E-A-T 검증 배치 (S4 색인 회복) — 조회수 상위 토픽 실검증 후 슬롯 채움.
# 각 토픽 본문 법령 주장을 law.go.kr 1:1 대조 후에만 등재(헤드라인 자동채움 금지 — 거짓 E-E-A-T 방지).
# 'topic' 접두사를 피해 other_files로 분류 → 모든 토픽 정의(topics.rb 포함) 이후 로드 보장.
# 메타데이터만 갱신하므로 update_columns(검증·콜백 skip)로 ping/needs_review 부작용 회피.

VERIFIED_2026_06_09 = {
  "private-contract" =>
    "법제처 국가법령정보센터 — 지방계약법 §9(수의계약), 시행령(MST 281055) §25(대상·한도: 종합공사 4억·전문 2억·기타 1.6억·물품/용역 2천만, 특례 청년창업·여성·장애인 5천만/소기업·사회적기업 1억)·§30(견적 방법), 지방자치단체 입찰 및 계약집행기준 제5장",
  "price-negotiation" =>
    "법제처 국가법령정보센터 — 지방계약법 §9(수의계약), 시행령(MST 281055) §30(수의계약 방법)·§74(수의시담: 견적가격 적정성 비교)",
  "dual-quote" =>
    "법제처 국가법령정보센터 — 지방계약법 시행령(MST 281055) §30②(2인 이상 견적)·§25(한도), 지방자치단체 입찰 및 계약집행기준 제70조(2인 이상 견적)",
  "single-quote" =>
    "법제처 국가법령정보센터 — 지방계약법 시행령(MST 281055) §30(1인 견적: 2천만·특례 5천만)·§25, 지방자치단체 입찰 및 계약집행기준 제69조(1인 견적)",
  "emergency-contract" =>
    "법제처 국가법령정보센터 — 지방계약법 §9, 시행령(MST 281055) §25①4호(긴급 수의계약 사유: 천재지변·긴급 행사·원자재 가격급등 등 경쟁에 부칠 여유가 없는 경우)",
  "private-contract-limit" =>
    "법제처 국가법령정보센터 — 지방계약법 시행령(MST 281055) §25①(수의계약 한도: 공사 종합 4억·전문 2억·기타 1.6억, 물품/용역 2천만, 청년창업 5천만·소기업/여성/장애인/사회적기업 1억)",
  "private-contract-amount" =>
    "법제처 국가법령정보센터 — 지방계약법 시행령(MST 281055) §25·§30(금액별 견적 방법: 200만 이하 카드·계약서 생략, 2천만 이하 1인 견적, 한도까지 2인 이상 견적)",
  "budget-carryover" =>
    "법제처 국가법령정보센터 — 지방재정법(MST 281909) §50(세출예산의 이월: 명시이월·사고이월·계속비이월), 시행령 §55(이월 절차)",
  "travel-expense" =>
    "법제처 국가법령정보센터 — 지방공무원법 §45(실비 변상), 지방공무원 여비 규정(여비 단가: 숙박비 서울 10만·광역시 8만·기타 7만, 일비·식비 25,000원). 단가 기준값 config/legal_standards.yml(2026-01-02)",
  # 파일럿(topic_late_penalty.rb는 find_or_create_by!라 기존 레코드 미갱신) → 배치(update_columns)로 실효성 보장
  "late-penalty" =>
    "법제처 국가법령정보센터 — 지방계약법 §30(지체상금), 지방계약법 시행령(MST 281055) §90③(지체상금 한도 30%), 지방계약법 시행규칙(MST 285747) §75(지연배상금률 공사 0.5·물품제조 0.8·용역 1.3·운송 2.5/1,000)"
}.freeze

verified_at = Date.new(2026, 6, 9)
updated = 0
VERIFIED_2026_06_09.each do |slug, source|
  topic = Topic.find_by(slug: slug)
  next unless topic
  topic.update_columns(
    verification_source: source,
    verification_method: "law.go.kr 1:1 대조",
    last_verified_at: verified_at
  )
  updated += 1
end
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{VERIFIED_2026_06_09.size}건 (2026-06-09 배치)"
